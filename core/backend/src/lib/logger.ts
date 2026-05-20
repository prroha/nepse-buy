/**
 * Logger Utility
 *
 * A simple logger wrapper that can be easily swapped to Winston/Pino later.
 * All logging should go through this module instead of direct console calls.
 *
 * Supports request correlation IDs for end-to-end tracing.
 */

import { AsyncLocalStorage } from "async_hooks";
import { config } from "../config/index.js";

type LogLevel = "debug" | "info" | "warn" | "error";

interface LogContext {
  [key: string]: unknown;
}

/**
 * AsyncLocalStorage for request-scoped context (e.g., requestId)
 */
interface RequestContext {
  requestId: string;
}

export const requestContext = new AsyncLocalStorage<RequestContext>();

/**
 * Get the current request ID from AsyncLocalStorage
 */
function getCurrentRequestId(): string | undefined {
  return requestContext.getStore()?.requestId;
}

const LOG_LEVELS: Record<LogLevel, number> = {
  debug: 0,
  info: 1,
  warn: 2,
  error: 3,
};

// In production, only log warn and above by default
const MIN_LOG_LEVEL: LogLevel = config.isProduction() ? "warn" : "debug";

function shouldLog(level: LogLevel): boolean {
  return LOG_LEVELS[level] >= LOG_LEVELS[MIN_LOG_LEVEL];
}

function formatMessage(level: LogLevel, message: string, context?: LogContext): string {
  const timestamp = new Date().toISOString();
  const requestId = getCurrentRequestId();

  // Merge requestId into context if available
  const fullContext = requestId
    ? { requestId, ...context }
    : context;

  const contextStr = fullContext ? ` ${JSON.stringify(fullContext)}` : "";

  if (config.isProduction()) {
    // JSON format for production (easier to parse in log aggregators)
    return JSON.stringify({
      timestamp,
      level,
      message,
      ...fullContext,
    });
  }

  // Human-readable format for development
  const requestIdStr = requestId ? ` [${requestId.substring(0, 8)}]` : "";
  return `[${timestamp}] [${level.toUpperCase()}]${requestIdStr} ${message}${contextStr}`;
}

/**
 * Logger instance
 *
 * Usage:
 *   logger.info("User logged in", { userId: "123" });
 *   logger.error("Operation failed", { error: err.message });
 *   logger.warn("Rate limit approaching", { ip, count });
 *   logger.debug("Request details", { headers, body });
 */
export const logger = {
  debug(message: string, context?: LogContext): void {
    if (shouldLog("debug")) {
      console.debug(formatMessage("debug", message, context));
    }
  },

  info(message: string, context?: LogContext): void {
    if (shouldLog("info")) {
      console.info(formatMessage("info", message, context));
    }
  },

  warn(message: string, context?: LogContext): void {
    if (shouldLog("warn")) {
      console.warn(formatMessage("warn", message, context));
    }
  },

  error(message: string, context?: LogContext): void {
    if (shouldLog("error")) {
      console.error(formatMessage("error", message, context));
    }
  },

  /**
   * Log security-related events (always logged regardless of level)
   */
  security(message: string, context?: LogContext): void {
    const securityContext = { ...context, _security: true };
    console.warn(formatMessage("warn", `[SECURITY] ${message}`, securityContext));
  },

  /**
   * Log audit events (always logged regardless of level)
   */
  audit(message: string, context?: LogContext): void {
    const auditContext = { ...context, _audit: true };
    console.info(formatMessage("info", `[AUDIT] ${message}`, auditContext));
  },
};

/**
 * Create a logger instance with a fixed request ID
 * Use this when you need to log outside the async context
 *
 * @param requestId - The correlation ID for this request
 * @returns A logger that includes the requestId in all logs
 */
export function createRequestLogger(requestId: string) {
  return {
    debug(message: string, context?: LogContext): void {
      if (shouldLog("debug")) {
        console.debug(formatMessage("debug", message, { requestId, ...context }));
      }
    },

    info(message: string, context?: LogContext): void {
      if (shouldLog("info")) {
        console.info(formatMessage("info", message, { requestId, ...context }));
      }
    },

    warn(message: string, context?: LogContext): void {
      if (shouldLog("warn")) {
        console.warn(formatMessage("warn", message, { requestId, ...context }));
      }
    },

    error(message: string, context?: LogContext): void {
      if (shouldLog("error")) {
        console.error(formatMessage("error", message, { requestId, ...context }));
      }
    },

    security(message: string, context?: LogContext): void {
      const securityContext = { requestId, ...context, _security: true };
      console.warn(formatMessage("warn", `[SECURITY] ${message}`, securityContext));
    },

    audit(message: string, context?: LogContext): void {
      const auditContext = { requestId, ...context, _audit: true };
      console.info(formatMessage("info", `[AUDIT] ${message}`, auditContext));
    },
  };
}

export default logger;
