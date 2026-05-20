import path from "path";
import fs from "fs";
import crypto from "crypto";
import { FastifyRequest } from "fastify";
import { ApiError } from "./error.middleware.js";
import { ErrorCodes } from "../utils/response.js";

// Allowed image types
const ALLOWED_MIME_TYPES = [
  "image/jpeg",
  "image/png",
  "image/gif",
  "image/webp",
] as const;

type AllowedMimeType = typeof ALLOWED_MIME_TYPES[number];

const ALLOWED_EXTENSIONS = [".jpg", ".jpeg", ".png", ".gif", ".webp"];

// Max file size: 5MB
const MAX_FILE_SIZE = 5 * 1024 * 1024;

// Upload directory
const UPLOAD_DIR = path.join(process.cwd(), "uploads");
const AVATAR_DIR = path.join(UPLOAD_DIR, "avatars");

// Ensure upload directories exist
function ensureUploadDirs(): void {
  if (!fs.existsSync(UPLOAD_DIR)) {
    fs.mkdirSync(UPLOAD_DIR, { recursive: true });
  }
  if (!fs.existsSync(AVATAR_DIR)) {
    fs.mkdirSync(AVATAR_DIR, { recursive: true });
  }
}

ensureUploadDirs();

/**
 * Process avatar upload from Fastify multipart
 * Returns the saved file info or throws ApiError
 */
export async function processAvatarUpload(req: FastifyRequest): Promise<{
  filename: string;
  filepath: string;
  mimetype: string;
  size: number;
}> {
  const data = await (req as FastifyRequest & { file: () => Promise<{
    filename: string;
    mimetype: string;
    file: NodeJS.ReadableStream;
    toBuffer: () => Promise<Buffer>;
  } | undefined> }).file();

  if (!data) {
    throw ApiError.badRequest("No file uploaded", ErrorCodes.INVALID_INPUT);
  }

  // Check MIME type
  if (!ALLOWED_MIME_TYPES.includes(data.mimetype as AllowedMimeType)) {
    throw ApiError.badRequest(
      `Invalid file type. Allowed types: ${ALLOWED_MIME_TYPES.join(", ")}`,
      ErrorCodes.INVALID_INPUT
    );
  }

  // Check extension
  const ext = path.extname(data.filename).toLowerCase();
  if (!ALLOWED_EXTENSIONS.includes(ext)) {
    throw ApiError.badRequest(
      `Invalid file extension. Allowed extensions: ${ALLOWED_EXTENSIONS.join(", ")}`,
      ErrorCodes.INVALID_INPUT
    );
  }

  // Read file buffer
  const buffer = await data.toBuffer();

  // Check file size
  if (buffer.length > MAX_FILE_SIZE) {
    throw ApiError.badRequest(
      `File too large. Maximum size: ${MAX_FILE_SIZE / (1024 * 1024)}MB`,
      ErrorCodes.INVALID_INPUT
    );
  }

  // Generate unique filename
  const uniqueSuffix = `${Date.now()}-${crypto.randomBytes(8).toString("hex")}`;
  const filename = `avatar-${uniqueSuffix}${ext}`;
  const filepath = path.join(AVATAR_DIR, filename);

  // Write file
  await fs.promises.writeFile(filepath, buffer);

  return {
    filename,
    filepath,
    mimetype: data.mimetype,
    size: buffer.length,
  };
}

/**
 * Delete a file from the uploads directory
 */
export function deleteUploadedFile(filePath: string): Promise<void> {
  return new Promise((resolve, reject) => {
    const normalizedPath = path.normalize(filePath);
    if (!normalizedPath.startsWith(UPLOAD_DIR)) {
      reject(new Error("Invalid file path"));
      return;
    }

    fs.unlink(normalizedPath, (err) => {
      if (err) {
        if (err.code === "ENOENT") {
          resolve();
          return;
        }
        reject(err);
        return;
      }
      resolve();
    });
  });
}

/**
 * Get the full file path for an avatar filename
 */
export function getAvatarPath(filename: string): string {
  return path.join(AVATAR_DIR, path.basename(filename));
}

/**
 * Get the public URL path for an avatar
 */
export function getAvatarUrl(filename: string): string {
  return `/uploads/avatars/${path.basename(filename)}`;
}

// Export constants for use in other modules
export { UPLOAD_DIR, AVATAR_DIR, MAX_FILE_SIZE, ALLOWED_MIME_TYPES };
