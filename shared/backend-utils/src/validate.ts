import { FastifyRequest, FastifyReply } from "fastify";
import { AnyZodObject, ZodError } from "zod";
import { ApiError } from "./errors.js";

export function validateRequest<T extends AnyZodObject>(schema: T) {
  return async (req: FastifyRequest, _reply: FastifyReply) => {
    try {
      await schema.parseAsync({
        body: req.body,
        query: req.query,
        params: req.params,
      });
    } catch (error) {
      if (error instanceof ZodError) {
        const formattedErrors = error.errors.map((err) => ({
          path: err.path.join("."),
          message: err.message,
        }));
        throw ApiError.validation(formattedErrors);
      }
      throw error;
    }
  };
}
