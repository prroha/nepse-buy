/**
 * Export OpenAPI specification to JSON file
 * This file is used by the frontend to generate TypeScript types
 *
 * Usage: npx ts-node scripts/export-openapi.ts
 */

import * as fs from "fs";
import * as path from "path";
import { swaggerSpec } from "../src/swagger";

interface OpenAPISpec {
  openapi: string;
  info: object;
  paths?: Record<string, unknown>;
  components?: {
    schemas?: Record<string, unknown>;
    securitySchemes?: Record<string, unknown>;
  };
}

const spec = swaggerSpec as OpenAPISpec;
const outputPath = path.resolve(__dirname, "../../openapi.json");

// Write the spec to file
fs.writeFileSync(outputPath, JSON.stringify(spec, null, 2));

console.log(`✅ OpenAPI spec exported to: ${outputPath}`);
console.log(`   Schemas: ${Object.keys(spec.components?.schemas || {}).length}`);
console.log(`   Paths: ${Object.keys(spec.paths || {}).length}`);
