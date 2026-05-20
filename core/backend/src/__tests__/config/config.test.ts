import { describe, it, expect } from "vitest";
import { config } from "../../config/index.js";

describe("Config", () => {
  it("should load config with test defaults", () => {
    expect(config).toBeDefined();
    expect(config.jwt).toBeDefined();
    expect(config.jwt.secret).toBeDefined();
    expect(typeof config.jwt.secret).toBe("string");
  });

  it("should have JWT config with expected shape", () => {
    expect(config.jwt.expiresIn).toBeDefined();
    expect(config.jwt.refreshExpiresIn).toBeDefined();
  });

  it("should have helper methods", () => {
    expect(typeof config.isDevelopment).toBe("function");
    expect(typeof config.isProduction).toBe("function");
    expect(typeof config.isTest).toBe("function");
  });

  it("should detect test environment", () => {
    expect(config.isTest()).toBe(true);
    expect(config.isProduction()).toBe(false);
  });
});
