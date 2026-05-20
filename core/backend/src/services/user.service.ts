import { PrismaClient } from "@prisma/client";
import { db } from "../lib/db.js";
import { ApiError } from "../middleware/error.middleware.js";
import { ErrorCodes } from "../utils/response.js";
import { deleteUploadedFile, getAvatarPath, getAvatarUrl } from "../middleware/upload.middleware.js";

interface UpdateProfileInput {
  name?: string;
  email?: string;
}

interface UserProfile {
  id: string;
  email: string;
  name: string | null;
  role: string;
  isActive: boolean;
  createdAt: Date;
  updatedAt: Date;
}

export class UserService {
  constructor(private db: PrismaClient) {}
  /**
   * Get user profile by ID
   */
  async getProfile(userId: string): Promise<UserProfile> {
    const user = await this.db.user.findUnique({
      where: { id: userId },
      select: {
        id: true,
        email: true,
        name: true,
        role: true,
        isActive: true,
        createdAt: true,
        updatedAt: true,
      },
    });

    if (!user) {
      throw ApiError.notFound("User not found", ErrorCodes.USER_NOT_FOUND);
    }

    return user;
  }

  /**
   * Update user profile
   */
  async updateProfile(userId: string, input: UpdateProfileInput): Promise<UserProfile> {
    const { name, email } = input;

    // Check if user exists
    const existingUser = await this.db.user.findUnique({
      where: { id: userId },
      select: {
        id: true,
        email: true,
      },
    });

    if (!existingUser) {
      throw ApiError.notFound("User not found", ErrorCodes.USER_NOT_FOUND);
    }

    // If email is being changed, check for conflicts
    if (email && email.toLowerCase() !== existingUser.email) {
      const emailExists = await this.db.user.findUnique({
        where: { email: email.toLowerCase() },
        select: { id: true },
      });

      if (emailExists) {
        throw ApiError.conflict("Email already in use", ErrorCodes.ALREADY_EXISTS);
      }
    }

    // If email is changing, require re-verification
    const isEmailChanging = email && email.toLowerCase() !== existingUser.email;

    // Update user
    const user = await this.db.user.update({
      where: { id: userId },
      data: {
        ...(name !== undefined && { name }),
        ...(email && { email: email.toLowerCase() }),
        ...(isEmailChanging && { emailVerified: false }),
      },
      select: {
        id: true,
        email: true,
        name: true,
        role: true,
        isActive: true,
        createdAt: true,
        updatedAt: true,
      },
    });

    return user;
  }

  /**
   * Get user avatar URL and initials
   */
  async getAvatar(userId: string): Promise<{ url: string | null; initials: string }> {
    const user = await this.db.user.findUnique({
      where: { id: userId },
      select: {
        name: true,
        email: true,
        avatarUrl: true,
      },
    });

    if (!user) {
      throw ApiError.notFound("User not found", ErrorCodes.USER_NOT_FOUND);
    }

    // Generate initials from name or email
    let initials = "U";
    if (user.name) {
      const nameParts = user.name.trim().split(/\s+/);
      initials = nameParts.length > 1
        ? `${nameParts[0][0]}${nameParts[nameParts.length - 1][0]}`.toUpperCase()
        : user.name.substring(0, 2).toUpperCase();
    } else if (user.email) {
      initials = user.email.substring(0, 2).toUpperCase();
    }

    return {
      url: user.avatarUrl,
      initials,
    };
  }

  /**
   * Upload user avatar
   */
  async uploadAvatar(userId: string, file: { filename: string; filepath: string; mimetype: string; size: number }): Promise<{ url: string }> {
    // Check if user exists
    const existingUser = await this.db.user.findUnique({
      where: { id: userId },
      select: { avatarUrl: true },
    });

    if (!existingUser) {
      // Delete the uploaded file if user doesn't exist
      await deleteUploadedFile(file.filepath);
      throw ApiError.notFound("User not found", ErrorCodes.USER_NOT_FOUND);
    }

    // Delete old avatar if exists
    if (existingUser.avatarUrl) {
      try {
        // Extract filename from URL path
        const oldFilename = existingUser.avatarUrl.split("/").pop();
        if (oldFilename) {
          await deleteUploadedFile(getAvatarPath(oldFilename));
        }
      } catch {
        // Ignore errors deleting old file
      }
    }

    // Generate avatar URL
    const avatarUrl = getAvatarUrl(file.filename);

    // Update user with new avatar URL
    await this.db.user.update({
      where: { id: userId },
      data: { avatarUrl },
    });

    return { url: avatarUrl };
  }

  /**
   * Delete user avatar
   */
  async deleteAvatar(userId: string): Promise<void> {
    // Get user with current avatar
    const user = await this.db.user.findUnique({
      where: { id: userId },
      select: { avatarUrl: true },
    });

    if (!user) {
      throw ApiError.notFound("User not found", ErrorCodes.USER_NOT_FOUND);
    }

    if (!user.avatarUrl) {
      throw ApiError.badRequest("No avatar to delete", ErrorCodes.INVALID_INPUT);
    }

    // Delete the file
    try {
      const filename = user.avatarUrl.split("/").pop();
      if (filename) {
        await deleteUploadedFile(getAvatarPath(filename));
      }
    } catch {
      // Continue even if file deletion fails
    }

    // Update user to remove avatar URL
    await this.db.user.update({
      where: { id: userId },
      data: { avatarUrl: null },
    });
  }
}

export const userService = new UserService(db);

export function createUserService(injectedDb: PrismaClient) {
  return new UserService(injectedDb);
}
