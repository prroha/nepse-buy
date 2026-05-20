import { describe, it, expect } from "vitest";
import jwt from "jsonwebtoken";
import {
  generateAccessToken,
  generateRefreshToken,
  generateTokenPair,
  verifyToken,
  decodeToken,
} from "../../utils/jwt.js";
import { config } from "../../config/index.js";

const testPayload = { userId: "user-123", email: "test@example.com" };

describe("JWT Utilities", () => {
  describe("generateAccessToken", () => {
    it("should return a valid JWT string", () => {
      const token = generateAccessToken(testPayload);
      expect(typeof token).toBe("string");
      expect(token.split(".")).toHaveLength(3);
    });

    it("should contain the correct payload", () => {
      const token = generateAccessToken(testPayload);
      const decoded = jwt.verify(token, config.jwt.secret) as Record<string, unknown>;
      expect(decoded.userId).toBe("user-123");
      expect(decoded.email).toBe("test@example.com");
    });

    it("should include iat and exp claims", () => {
      const token = generateAccessToken(testPayload);
      const decoded = jwt.decode(token) as Record<string, unknown>;
      expect(decoded.iat).toBeDefined();
      expect(decoded.exp).toBeDefined();
    });
  });

  describe("generateRefreshToken", () => {
    it("should return a valid JWT string", () => {
      const token = generateRefreshToken(testPayload);
      expect(typeof token).toBe("string");
      expect(token.split(".")).toHaveLength(3);
    });

    it("should have a longer expiry than access token", () => {
      const accessToken = generateAccessToken(testPayload);
      const refreshToken = generateRefreshToken(testPayload);
      const accessDecoded = jwt.decode(accessToken) as { exp: number };
      const refreshDecoded = jwt.decode(refreshToken) as { exp: number };
      expect(refreshDecoded.exp).toBeGreaterThan(accessDecoded.exp);
    });
  });

  describe("generateTokenPair", () => {
    it("should return accessToken, refreshToken, and expiresIn", () => {
      const pair = generateTokenPair(testPayload);
      expect(pair).toHaveProperty("accessToken");
      expect(pair).toHaveProperty("refreshToken");
      expect(pair).toHaveProperty("expiresIn");
      expect(typeof pair.accessToken).toBe("string");
      expect(typeof pair.refreshToken).toBe("string");
      expect(typeof pair.expiresIn).toBe("number");
      expect(pair.expiresIn).toBeGreaterThan(0);
    });
  });

  describe("verifyToken", () => {
    it("should return payload for a valid token", () => {
      const token = generateAccessToken(testPayload);
      const payload = verifyToken(token);
      expect(payload.userId).toBe("user-123");
      expect(payload.email).toBe("test@example.com");
    });

    it("should throw 'Token expired' for an expired token", () => {
      const token = jwt.sign(testPayload, config.jwt.secret, { expiresIn: "0s" });
      expect(() => verifyToken(token)).toThrow("Token expired");
    });

    it("should throw 'Invalid token' for a malformed token", () => {
      expect(() => verifyToken("not.a.valid.token")).toThrow("Invalid token");
    });

    it("should throw 'Invalid token' for a token signed with wrong secret", () => {
      const token = jwt.sign(testPayload, "wrong-secret");
      expect(() => verifyToken(token)).toThrow("Invalid token");
    });
  });

  describe("decodeToken", () => {
    it("should decode without verification", () => {
      const token = generateAccessToken(testPayload);
      const decoded = decodeToken(token);
      expect(decoded).not.toBeNull();
      expect(decoded!.userId).toBe("user-123");
    });

    it("should return null for garbage input", () => {
      const decoded = decodeToken("garbage-string");
      expect(decoded).toBeNull();
    });
  });
});
