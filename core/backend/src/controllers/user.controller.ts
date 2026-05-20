import { FastifyRequest, FastifyReply } from "fastify";
import { userService } from "../services/user.service.js";
import { exportService } from "../services/export.service.js";
import { successResponse, errorResponse, ErrorCodes } from "../utils/response.js";
import { z } from "zod";
import { AuthenticatedRequest } from "../types/index.js";
import { strictNameSchema, emailSchema } from "../utils/validation-schemas.js";
import { processAvatarUpload } from "../middleware/upload.middleware.js";

// ============================================================================
// Validation Schemas
// ============================================================================

const updateProfileSchema = z.object({
  name: strictNameSchema.optional(),
  email: emailSchema.optional(),
}).refine(
  (data) => data.name !== undefined || data.email !== undefined,
  { message: "At least one field (name or email) must be provided" }
);

const exportFormatSchema = z.enum(["json", "csv"]).optional().default("json");

class UserController {
  /**
   * Get current user profile
   * GET /api/v1/users/me
   */
  async getProfile(req: FastifyRequest, reply: FastifyReply) {
    const authReq = req as AuthenticatedRequest;
    const profile = await userService.getProfile(authReq.dbUser.id);

    return reply.send(successResponse({ profile }));
  }

  /**
   * Update current user profile
   * PATCH /api/v1/users/me
   */
  async updateProfile(req: FastifyRequest, reply: FastifyReply) {
    const authReq = req as AuthenticatedRequest;
    const validated = updateProfileSchema.parse(req.body);

    const profile = await userService.updateProfile(authReq.dbUser.id, validated);

    return reply.send(successResponse(
      { profile },
      "Profile updated successfully"
    ));
  }

  /**
   * Get current user avatar
   * GET /api/v1/users/me/avatar
   */
  async getAvatar(req: FastifyRequest, reply: FastifyReply) {
    const authReq = req as AuthenticatedRequest;
    const avatar = await userService.getAvatar(authReq.dbUser.id);

    return reply.send(successResponse({ avatar }));
  }

  /**
   * Upload current user avatar
   * POST /api/v1/users/me/avatar
   */
  async uploadAvatar(req: FastifyRequest, reply: FastifyReply) {
    const authReq = req as AuthenticatedRequest;

    const file = await processAvatarUpload(req);
    const result = await userService.uploadAvatar(authReq.dbUser.id, file);

    return reply.send(successResponse(
      { avatar: { url: result.url } },
      "Avatar uploaded successfully"
    ));
  }

  /**
   * Delete current user avatar
   * DELETE /api/v1/users/me/avatar
   */
  async deleteAvatar(req: FastifyRequest, reply: FastifyReply) {
    const authReq = req as AuthenticatedRequest;
    await userService.deleteAvatar(authReq.dbUser.id);

    return reply.send(successResponse(null, "Avatar deleted successfully"));
  }

  /**
   * Export current user's data (GDPR compliant)
   * GET /api/v1/users/me/export
   * Query params:
   *   - format: "json" | "csv" (default: "json")
   */
  async exportMyData(req: FastifyRequest, reply: FastifyReply) {
    const authReq = req as AuthenticatedRequest;

    // Validate format using schema
    const formatResult = exportFormatSchema.safeParse((req.query as Record<string, string>).format);
    if (!formatResult.success) {
      return reply.code(400).send(
        errorResponse(ErrorCodes.VALIDATION_ERROR, "Invalid format. Use 'json' or 'csv'")
      );
    }
    const format = formatResult.data;

    const data = await exportService.exportUserData(authReq.dbUser.id, format);

    if (format === "csv") {
      const timestamp = new Date().toISOString().split("T")[0];
      reply.header("Content-Type", "text/csv; charset=utf-8");
      reply.header(
        "Content-Disposition",
        `attachment; filename="my-data-${timestamp}.csv"`
      );
      return reply.send(data);
    } else {
      const timestamp = new Date().toISOString().split("T")[0];
      reply.header("Content-Type", "application/json; charset=utf-8");
      reply.header(
        "Content-Disposition",
        `attachment; filename="my-data-${timestamp}.json"`
      );
      return reply.send(data);
    }
  }
}

export const userController = new UserController();
