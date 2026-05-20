import { Queue, Worker, type Job } from "bullmq";
import { logger } from "../lib/logger.js";
import { config } from "../config/index.js";
import { getRedis, disconnectRedis } from "./redis.js";
import { runDailyPipeline, type PipelineResult } from "./pipeline.js";

const QUEUE_NAME = "nepse-buy";
const JOB_DAILY_PIPELINE = "daily-pipeline";
const REPEAT_KEY = "daily-pipeline-cron";

let queue: Queue | null = null;
let worker: Worker | null = null;

interface DailyPipelineData {
  /** ISO date for which to compute signals. Defaults to "now" in the worker. */
  signalDate?: string;
  /** Free-text reason (cron | manual | api). Used in logs/dashboards. */
  trigger: string;
}

export function getQueue(): Queue {
  if (!queue) {
    queue = new Queue<DailyPipelineData>(QUEUE_NAME, {
      connection: getRedis(),
      defaultJobOptions: {
        attempts: 3,
        backoff: { type: "exponential", delay: 30_000 },
        removeOnComplete: { age: 7 * 24 * 3600 }, // keep last week
        removeOnFail: { age: 30 * 24 * 3600 },
      },
    });
  }
  return queue;
}

/**
 * Enqueue an ad-hoc run of the daily pipeline. Returns the BullMQ job id.
 */
export async function triggerDailyPipeline(trigger: string = "manual", signalDate?: Date): Promise<string> {
  const q = getQueue();
  const job = await q.add(JOB_DAILY_PIPELINE, {
    trigger,
    signalDate: signalDate?.toISOString(),
  });
  logger.info("Daily pipeline enqueued", { jobId: job.id, trigger });
  return job.id!;
}

/**
 * Boot the worker and (re)register the cron repeat. Called from app.ts.
 */
export async function startJobs(): Promise<void> {
  if (worker) {
    logger.warn("startJobs called twice — ignoring");
    return;
  }
  worker = new Worker<DailyPipelineData, PipelineResult>(
    QUEUE_NAME,
    async (job: Job<DailyPipelineData>): Promise<PipelineResult> => {
      logger.info("Job started", { jobId: job.id, name: job.name, trigger: job.data.trigger });
      const signalDate = job.data.signalDate ? new Date(job.data.signalDate) : new Date();
      return await runDailyPipeline(signalDate);
    },
    { connection: getRedis(), concurrency: 1 },
  );

  worker.on("completed", (job, result) => {
    logger.info("Job completed", { jobId: job.id, ...result });
  });
  worker.on("failed", (job, err) => {
    logger.error("Job failed", {
      jobId: job?.id,
      attempts: job?.attemptsMade,
      error: err.message,
    });
  });

  // Register cron repeat. NEPSE trades Sun-Thu, ~11:00-15:00 NPT.
  // SCHEDULE_CRON_DAILY default "0 16 * * 0-4" → 16:00 NPT on Sun-Thu.
  const q = getQueue();
  // Remove any prior repeat so config edits take effect on restart.
  const existing = await q.getRepeatableJobs();
  for (const r of existing) {
    if (r.key === REPEAT_KEY || r.name === JOB_DAILY_PIPELINE) {
      await q.removeRepeatableByKey(r.key);
    }
  }
  await q.add(
    JOB_DAILY_PIPELINE,
    { trigger: "cron" },
    {
      repeat: { pattern: config.schedule.cronDaily, tz: config.schedule.timezone, key: REPEAT_KEY },
      jobId: REPEAT_KEY,
    },
  );

  logger.info("Jobs ready", {
    queue: QUEUE_NAME,
    cron: config.schedule.cronDaily,
    tz: config.schedule.timezone,
  });
}

export async function stopJobs(): Promise<void> {
  try {
    if (worker) {
      await worker.close();
      worker = null;
    }
    if (queue) {
      await queue.close();
      queue = null;
    }
    await disconnectRedis();
  } catch (err) {
    logger.error("Error stopping jobs", { error: err instanceof Error ? err.message : String(err) });
  }
}
