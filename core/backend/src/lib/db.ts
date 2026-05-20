import { PrismaClient } from "@prisma/client";

// Create Prisma client with appropriate logging
// Note: global.prisma pattern removed — that is a Next.js hot-reload workaround, not needed in backend
export const db = new PrismaClient({
  log: ["error", "warn"],
});

// Graceful shutdown
process.on("beforeExit", async () => {
  await db.$disconnect();
});
