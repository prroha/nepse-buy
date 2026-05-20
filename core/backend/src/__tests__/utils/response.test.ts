import { describe, it, expect } from "vitest";
import {
  successResponse,
  errorResponse,
  paginatedResponse,
  ErrorCodes,
} from "../../utils/response.js";

describe("Response Utilities", () => {
  describe("successResponse", () => {
    it("should create a success response with data", () => {
      const data = { id: 1, name: "Test" };
      const result = successResponse(data);

      expect(result).toEqual({
        success: true,
        data: { id: 1, name: "Test" },
      });
    });

    it("should include message when provided", () => {
      const data = { id: 1 };
      const result = successResponse(data, "Operation successful");

      expect(result).toEqual({
        success: true,
        data: { id: 1 },
        message: "Operation successful",
      });
    });

    it("should not include message key when message is undefined", () => {
      const data = "simple string";
      const result = successResponse(data);

      expect(result).toEqual({
        success: true,
        data: "simple string",
      });
      expect(result).not.toHaveProperty("message");
    });
  });

  describe("errorResponse", () => {
    it("should create an error response with code and message", () => {
      const result = errorResponse("TEST_ERROR", "Something went wrong");

      expect(result).toEqual({
        success: false,
        error: {
          code: "TEST_ERROR",
          message: "Something went wrong",
        },
      });
    });

    it("should include details when provided", () => {
      const details = { field: "email", issue: "invalid format" };
      const result = errorResponse(
        ErrorCodes.VALIDATION_ERROR,
        "Validation failed",
        details
      );

      expect(result).toEqual({
        success: false,
        error: {
          code: "VALIDATION_ERROR",
          message: "Validation failed",
          details: { field: "email", issue: "invalid format" },
        },
      });
    });

    it("should not include details when undefined", () => {
      const result = errorResponse(ErrorCodes.NOT_FOUND, "Resource not found");

      expect(result.error).not.toHaveProperty("details");
    });
  });

  describe("paginatedResponse", () => {
    it("should create a paginated response with correct structure", () => {
      const items = [{ id: 1 }, { id: 2 }];
      const result = paginatedResponse(items, 1, 10, 25);

      expect(result).toEqual({
        success: true,
        data: {
          items: [{ id: 1 }, { id: 2 }],
          pagination: {
            page: 1,
            limit: 10,
            total: 25,
            totalPages: 3,
            hasNext: true,
            hasPrev: false,
          },
        },
      });
    });

    it("should correctly calculate hasNext and hasPrev for middle page", () => {
      const items = [{ id: 3 }, { id: 4 }];
      const result = paginatedResponse(items, 2, 10, 30);

      expect(result.data.pagination.hasNext).toBe(true);
      expect(result.data.pagination.hasPrev).toBe(true);
    });

    it("should correctly calculate hasNext and hasPrev for last page", () => {
      const items = [{ id: 5 }];
      const result = paginatedResponse(items, 3, 10, 25);

      expect(result.data.pagination.hasNext).toBe(false);
      expect(result.data.pagination.hasPrev).toBe(true);
    });

    it("should handle single page correctly", () => {
      const items = [{ id: 1 }];
      const result = paginatedResponse(items, 1, 10, 1);

      expect(result.data.pagination).toEqual({
        page: 1,
        limit: 10,
        total: 1,
        totalPages: 1,
        hasNext: false,
        hasPrev: false,
      });
    });

    it("should handle empty results", () => {
      const result = paginatedResponse([], 1, 10, 0);

      expect(result.data.items).toEqual([]);
      expect(result.data.pagination.totalPages).toBe(0);
      expect(result.data.pagination.hasNext).toBe(false);
      expect(result.data.pagination.hasPrev).toBe(false);
    });
  });
});
