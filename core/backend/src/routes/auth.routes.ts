import { FastifyPluginAsync } from "fastify";
import { authController } from "../controllers/auth.controller.js";
import { authMiddleware } from "../middleware/auth.middleware.js";
import { authRateLimiter, sensitiveRateLimiter } from "../middleware/rate-limit.middleware.js";

const routePlugin: FastifyPluginAsync = async (fastify) => {
  /**
   * @swagger
   * /auth/register:
   *   post:
   *     summary: Register a new user
   *     tags: [Auth]
   *     requestBody:
   *       required: true
   *       content:
   *         application/json:
   *           schema:
   *             type: object
   *             required:
   *               - email
   *               - password
   *               - name
   *             properties:
   *               email:
   *                 type: string
   *                 format: email
   *                 example: user@example.com
   *               password:
   *                 type: string
   *                 minLength: 8
   *                 example: securePassword123
   *               name:
   *                 type: string
   *                 example: John Doe
   *     responses:
   *       201:
   *         description: User registered successfully
   *         content:
   *           application/json:
   *             schema:
   *               type: object
   *               properties:
   *                 success:
   *                   type: boolean
   *                   example: true
   *                 data:
   *                   type: object
   *                   properties:
   *                     user:
   *                       $ref: '#/components/schemas/User'
   *                     accessToken:
   *                       type: string
   *       400:
   *         description: Validation error
   *         content:
   *           application/json:
   *             schema:
   *               $ref: '#/components/schemas/Error'
   *       409:
   *         description: Email already registered
   */
  fastify.post("/register", { preHandler: [authRateLimiter], bodyLimit: 16384 }, (req, reply) => authController.register(req, reply));

  /**
   * @swagger
   * /auth/login:
   *   post:
   *     summary: Login with email and password
   *     tags: [Auth]
   *     requestBody:
   *       required: true
   *       content:
   *         application/json:
   *           schema:
   *             type: object
   *             required:
   *               - email
   *               - password
   *             properties:
   *               email:
   *                 type: string
   *                 format: email
   *                 example: user@example.com
   *               password:
   *                 type: string
   *                 example: securePassword123
   *     responses:
   *       200:
   *         description: Login successful
   *         content:
   *           application/json:
   *             schema:
   *               type: object
   *               properties:
   *                 success:
   *                   type: boolean
   *                   example: true
   *                 data:
   *                   type: object
   *                   properties:
   *                     user:
   *                       $ref: '#/components/schemas/User'
   *                     accessToken:
   *                       type: string
   *         headers:
   *           Set-Cookie:
   *             description: HTTP-only refresh token cookie
   *             schema:
   *               type: string
   *       401:
   *         description: Invalid credentials
   *         content:
   *           application/json:
   *             schema:
   *               $ref: '#/components/schemas/Error'
   */
  fastify.post("/login", { preHandler: [authRateLimiter], bodyLimit: 16384 }, (req, reply) => authController.login(req, reply));

  /**
   * @swagger
   * /auth/logout:
   *   post:
   *     summary: Logout and invalidate tokens
   *     tags: [Auth]
   *     responses:
   *       200:
   *         description: Logout successful
   *         content:
   *           application/json:
   *             schema:
   *               type: object
   *               properties:
   *                 success:
   *                   type: boolean
   *                   example: true
   *                 data:
   *                   type: object
   *                   properties:
   *                     message:
   *                       type: string
   *                       example: Logged out successfully
   */
  fastify.post("/logout", (req, reply) => authController.logout(req, reply));

  /**
   * @swagger
   * /auth/refresh:
   *   post:
   *     summary: Refresh access token using refresh token cookie
   *     tags: [Auth]
   *     security:
   *       - cookieAuth: []
   *     responses:
   *       200:
   *         description: Token refreshed successfully
   *         content:
   *           application/json:
   *             schema:
   *               type: object
   *               properties:
   *                 success:
   *                   type: boolean
   *                   example: true
   *                 data:
   *                   type: object
   *                   properties:
   *                     accessToken:
   *                       type: string
   *       401:
   *         description: Invalid or expired refresh token
   */
  fastify.post("/refresh", { preHandler: [authRateLimiter] }, (req, reply) => authController.refresh(req, reply));

  /**
   * @swagger
   * /auth/forgot-password:
   *   post:
   *     summary: Request a password reset email
   *     tags: [Auth]
   *     requestBody:
   *       required: true
   *       content:
   *         application/json:
   *           schema:
   *             type: object
   *             required:
   *               - email
   *             properties:
   *               email:
   *                 type: string
   *                 format: email
   *     responses:
   *       200:
   *         description: Reset email sent (if email exists)
   */
  fastify.post("/forgot-password", { preHandler: [authRateLimiter] }, (req, reply) => authController.forgotPassword(req, reply));

  /**
   * @swagger
   * /auth/verify-reset-token/{token}:
   *   get:
   *     summary: Verify a password reset token is valid
   *     tags: [Auth]
   *     parameters:
   *       - in: path
   *         name: token
   *         required: true
   *         schema:
   *           type: string
   *     responses:
   *       200:
   *         description: Token is valid
   *       400:
   *         description: Token is invalid or expired
   */
  fastify.get("/verify-reset-token/:token", { preHandler: [authRateLimiter] }, (req, reply) => authController.verifyResetToken(req, reply));

  /**
   * @swagger
   * /auth/reset-password:
   *   post:
   *     summary: Reset password using reset token
   *     tags: [Auth]
   *     requestBody:
   *       required: true
   *       content:
   *         application/json:
   *           schema:
   *             type: object
   *             required:
   *               - token
   *               - password
   *             properties:
   *               token:
   *                 type: string
   *               password:
   *                 type: string
   *                 minLength: 8
   *     responses:
   *       200:
   *         description: Password reset successful
   *       400:
   *         description: Invalid token or validation error
   */
  fastify.post("/reset-password", { preHandler: [authRateLimiter] }, (req, reply) => authController.resetPassword(req, reply));

  /**
   * @swagger
   * /auth/verify-email/{token}:
   *   get:
   *     summary: Verify email address using verification token
   *     tags: [Auth]
   *     parameters:
   *       - in: path
   *         name: token
   *         required: true
   *         schema:
   *           type: string
   *     responses:
   *       200:
   *         description: Email verified successfully
   *       400:
   *         description: Invalid or expired token
   */
  fastify.get("/verify-email/:token", { preHandler: [authRateLimiter] }, (req, reply) => authController.verifyEmail(req, reply));

  /**
   * @swagger
   * /auth/send-verification:
   *   post:
   *     summary: Resend email verification link
   *     tags: [Auth]
   *     security:
   *       - bearerAuth: []
   *     responses:
   *       200:
   *         description: Verification email sent
   *       401:
   *         description: Unauthorized
   */
  fastify.post("/send-verification", { preHandler: [authRateLimiter, authMiddleware] }, (req, reply) => authController.sendVerification(req, reply));

  /**
   * @swagger
   * /auth/me:
   *   get:
   *     summary: Get current authenticated user
   *     tags: [Auth]
   *     security:
   *       - bearerAuth: []
   *     responses:
   *       200:
   *         description: Current user data
   *         content:
   *           application/json:
   *             schema:
   *               type: object
   *               properties:
   *                 success:
   *                   type: boolean
   *                   example: true
   *                 data:
   *                   type: object
   *                   properties:
   *                     user:
   *                       $ref: '#/components/schemas/User'
   *       401:
   *         description: Unauthorized - invalid or missing token
   *         content:
   *           application/json:
   *             schema:
   *               $ref: '#/components/schemas/Error'
   */
  fastify.get("/me", { preHandler: [authMiddleware] }, (req, reply) => authController.me(req, reply));

  /**
   * @swagger
   * /auth/change-password:
   *   post:
   *     summary: Change password for authenticated user
   *     tags: [Auth]
   *     security:
   *       - bearerAuth: []
   *     requestBody:
   *       required: true
   *       content:
   *         application/json:
   *           schema:
   *             type: object
   *             required:
   *               - currentPassword
   *               - newPassword
   *             properties:
   *               currentPassword:
   *                 type: string
   *               newPassword:
   *                 type: string
   *                 minLength: 8
   *     responses:
   *       200:
   *         description: Password changed successfully
   *       401:
   *         description: Unauthorized or incorrect current password
   */
  fastify.post("/change-password", { preHandler: [sensitiveRateLimiter, authMiddleware] }, (req, reply) => authController.changePassword(req, reply));

  /**
   * @swagger
   * /auth/sessions:
   *   get:
   *     summary: Get all active sessions for the current user
   *     tags: [Auth]
   *     security:
   *       - bearerAuth: []
   *     responses:
   *       200:
   *         description: List of active sessions
   *       401:
   *         description: Unauthorized
   *   delete:
   *     summary: Revoke all other sessions except current
   *     tags: [Auth]
   *     security:
   *       - bearerAuth: []
   *     responses:
   *       200:
   *         description: All other sessions revoked
   *       401:
   *         description: Unauthorized
   */
  fastify.get("/sessions", { preHandler: [authMiddleware] }, (req, reply) => authController.getSessions(req, reply));
  fastify.delete("/sessions", { preHandler: [authMiddleware] }, (req, reply) => authController.revokeAllOtherSessions(req, reply));

  /**
   * @swagger
   * /auth/sessions/{id}:
   *   delete:
   *     summary: Revoke a specific session
   *     tags: [Auth]
   *     security:
   *       - bearerAuth: []
   *     parameters:
   *       - in: path
   *         name: id
   *         required: true
   *         schema:
   *           type: string
   *     responses:
   *       200:
   *         description: Session revoked
   *       401:
   *         description: Unauthorized
   *       404:
   *         description: Session not found
   */
  fastify.delete("/sessions/:id", { preHandler: [authMiddleware] }, (req, reply) => authController.revokeSession(req, reply));
};

export default routePlugin;
