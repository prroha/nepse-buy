import { FastifyPluginAsync } from "fastify";
import authRoutes from "./auth.routes.js";
import userRoutes from "./user.routes.js";
import notificationRoutes from "./notification.routes.js";
import configRoutes from "./config.routes.js";
import stockRoutes from "./stock.routes.js";
import watchlistRoutes from "./watchlist.routes.js";
import signalRoutes from "./signal.routes.js";
import debtRoutes from "./debt.routes.js";
import positionRoutes from "./position.routes.js";
import adminRoutes from "./admin.routes.js";
import tradeRoutes from "./trade.routes.js";
import feeScheduleRoutes from "./fee-schedule.routes.js";
import screenerRoutes from "./screener.routes.js";
import corporateActionRoutes from "./corporate-action.routes.js";

const routes: FastifyPluginAsync = async (fastify) => {
  await fastify.register(async (v1) => {
    await v1.register(authRoutes, { prefix: "/auth" });
    await v1.register(userRoutes, { prefix: "/users" });
    await v1.register(notificationRoutes, { prefix: "/notifications" });
    await v1.register(configRoutes, { prefix: "/config" });
    await v1.register(stockRoutes, { prefix: "/stocks" });
    await v1.register(watchlistRoutes, { prefix: "/watchlist" });
    await v1.register(signalRoutes, { prefix: "/signals" });
    await v1.register(debtRoutes, { prefix: "/debt-accounts" });
    await v1.register(positionRoutes, { prefix: "/positions" });
    await v1.register(tradeRoutes, { prefix: "/trades" });
    await v1.register(feeScheduleRoutes, { prefix: "/fee-schedule" });
    await v1.register(screenerRoutes, { prefix: "/screener" });
    await v1.register(corporateActionRoutes, { prefix: "/corporate-actions" });
    await v1.register(adminRoutes, { prefix: "/admin" });
  }, { prefix: "/v1" });
};

export default routes;
