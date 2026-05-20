/**
 * Manually run the daily pipeline (in-process, no queue) for debugging.
 * Run: SMOKE_INSECURE=1 npx tsx scripts/run-pipeline.ts [YYYY-MM-DD]
 */
import { runDailyPipeline } from "../src/jobs/pipeline.js";
import { db } from "../src/lib/db.js";

async function main(): Promise<void> {
  const arg = process.argv[2];
  const signalDate = arg ? new Date(`${arg}T00:00:00Z`) : new Date();
  console.log(`Running pipeline for signalDate=${signalDate.toISOString()}`);
  const result = await runDailyPipeline(signalDate);
  console.log("Result:", result);
  await db.$disconnect();
}

main().catch(async (err) => {
  console.error(err);
  await db.$disconnect();
  process.exit(1);
});
