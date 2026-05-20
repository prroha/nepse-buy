import { FastifyReply } from "fastify";

export interface ApiResponse<T = unknown> {
  success: boolean;
  data?: T;
  message?: string;
  error?: {
    code: string;
    message: string;
    details?: unknown;
    requestId?: string;
  };
}

export interface PaginationInfo {
  page: number;
  limit: number;
  total: number;
  totalPages: number;
  hasPrev: boolean;
  hasNext: boolean;
}

export interface PaginatedData<T> {
  items: T[];
  pagination: PaginationInfo;
}

export function sendSuccess<T>(
  reply: FastifyReply,
  data: T,
  message?: string,
  statusCode = 200
): FastifyReply {
  return reply.code(statusCode).send({
    success: true,
    data,
    message,
  } satisfies ApiResponse<T>);
}

export function sendPaginated<T>(
  reply: FastifyReply,
  items: T[],
  pagination: PaginationInfo,
  message?: string
): FastifyReply {
  return reply.code(200).send({
    success: true,
    data: { items, pagination },
    message,
  } satisfies ApiResponse<PaginatedData<T>>);
}

export function sendError(
  reply: FastifyReply,
  message: string,
  statusCode = 400,
  code = "ERROR",
  details?: unknown
): FastifyReply {
  return reply.code(statusCode).send({
    success: false,
    error: { code, message, details },
  } satisfies ApiResponse);
}

export function createPaginationInfo(
  page: number,
  limit: number,
  total: number
): PaginationInfo {
  const totalPages = Math.ceil(total / limit);
  return {
    page,
    limit,
    total,
    totalPages,
    hasPrev: page > 1,
    hasNext: page < totalPages,
  };
}

export function parsePaginationParams(query: {
  page?: string;
  limit?: string;
}): { page: number; limit: number; skip: number } {
  const page = Math.max(1, parseInt(query.page || "1", 10));
  const limit = Math.min(100, Math.max(1, parseInt(query.limit || "10", 10)));
  const skip = (page - 1) * limit;
  return { page, limit, skip };
}
