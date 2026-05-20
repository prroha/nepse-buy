/**
 * Email Service
 *
 * Centralized email sending service with templating support.
 * Currently logs emails to console, ready for SMTP/SendGrid/Resend integration.
 */

import { Resend } from "resend";
import { config } from "../config/index.js";
import { logger } from "../lib/logger.js";
import {
  welcomeEmail,
  passwordResetEmail,
  emailVerificationEmail,
  passwordChangedEmail,
  dailySignalDigestEmail,
  type DailySignalDigestData,
} from "../email/templates/index.js";

export interface SendEmailOptions {
  /** Recipient email address */
  to: string;
  /** Email subject line */
  subject: string;
  /** HTML content */
  html: string;
  /** Plain text content */
  text: string;
  /** Reply-To address (optional) */
  replyTo?: string;
  /** Additional headers (optional) */
  headers?: Record<string, string>;
}

export interface SendEmailResult {
  success: boolean;
  messageId?: string;
  error?: string;
}

/**
 * User info for email sending
 */
export interface EmailUser {
  id: string;
  email: string;
  name: string | null;
}

class EmailService {
  private readonly from: string;
  private readonly provider: string;

  constructor() {
    this.from = config.email.from;
    this.provider = config.email.provider;
  }

  /**
   * Send an email using the configured provider
   */
  private async send(options: SendEmailOptions): Promise<SendEmailResult> {
    const { to, subject, html: _html, text: _text, replyTo: _replyTo, headers: _headers } = options;

    // Log email for development/debugging
    if (this.provider === "console" || config.isDevelopment()) {
      this.logEmail(options);
    }

    // In production, send via configured provider
    if (config.isProduction() && this.provider !== "console") {
      try {
        switch (this.provider) {
          case "smtp":
            return await this.sendViaSMTP(options);
          case "sendgrid":
            return await this.sendViaSendGrid(options);
          case "resend":
            return await this.sendViaResend(options);
          default:
            logger.warn("Unknown email provider, falling back to console", {
              provider: this.provider,
            });
        }
      } catch (error) {
        const errorMessage = error instanceof Error ? error.message : "Unknown error";
        logger.error("Failed to send email", {
          provider: this.provider,
          to,
          subject,
          error: errorMessage,
        });
        return { success: false, error: errorMessage };
      }
    }

    // For development/console provider, just return success after logging
    return {
      success: true,
      messageId: `dev-${Date.now()}-${Math.random().toString(36).substring(7)}`,
    };
  }

  /**
   * Log email to console (for development)
   */
  private logEmail(options: SendEmailOptions): void {
    const { to, subject, html, text, replyTo } = options;
    const separator = "=".repeat(60);

    console.log("\n" + separator);
    console.log("EMAIL SENT (Console Provider)");
    console.log(separator);
    console.log(`From: ${this.from}`);
    console.log(`To: ${to}`);
    if (replyTo) console.log(`Reply-To: ${replyTo}`);
    console.log(`Subject: ${subject}`);
    console.log(separator);
    console.log("PLAIN TEXT:");
    console.log("-".repeat(40));
    console.log(text);
    console.log("-".repeat(40));
    console.log("HTML PREVIEW:");
    console.log("-".repeat(40));
    console.log(html);
    console.log(separator + "\n");

    logger.info("Email logged to console", { to, subject });
  }

  /**
   * Send email via SMTP (placeholder - implement with nodemailer)
   */
  private async sendViaSMTP(options: SendEmailOptions): Promise<SendEmailResult> {
    // TODO: Implement SMTP sending with nodemailer
    // npm install nodemailer @types/nodemailer
    //
    // import nodemailer from "nodemailer";
    //
    // const transporter = nodemailer.createTransport({
    //   host: config.email.smtp.host,
    //   port: config.email.smtp.port,
    //   secure: config.email.smtp.secure,
    //   auth: {
    //     user: config.email.smtp.user,
    //     pass: config.email.smtp.password,
    //   },
    // });
    //
    // const info = await transporter.sendMail({
    //   from: this.from,
    //   to: options.to,
    //   subject: options.subject,
    //   text: options.text,
    //   html: options.html,
    //   replyTo: options.replyTo || this.replyTo,
    // });
    //
    // return { success: true, messageId: info.messageId };

    logger.warn("SMTP provider not implemented - email not sent", {
      to: options.to,
      subject: options.subject,
    });
    return { success: false, error: "SMTP provider not implemented" };
  }

  /**
   * Send email via SendGrid (placeholder)
   */
  private async sendViaSendGrid(options: SendEmailOptions): Promise<SendEmailResult> {
    // TODO: Implement SendGrid sending
    // npm install @sendgrid/mail
    //
    // import sgMail from "@sendgrid/mail";
    // sgMail.setApiKey(config.email.apiKey);
    //
    // const [response] = await sgMail.send({
    //   to: options.to,
    //   from: this.from,
    //   subject: options.subject,
    //   text: options.text,
    //   html: options.html,
    //   replyTo: options.replyTo || this.replyTo,
    // });
    //
    // return { success: true, messageId: response.headers["x-message-id"] };

    logger.warn("SendGrid provider not implemented - email not sent", {
      to: options.to,
      subject: options.subject,
    });
    return { success: false, error: "SendGrid provider not implemented" };
  }

  /** Lazy Resend client (avoids loading when provider=console). */
  private resendClient: Resend | null = null;
  private getResend(): Resend {
    if (!this.resendClient) {
      if (!config.email.apiKey) {
        throw new Error("RESEND_API_KEY is required when EMAIL_PROVIDER=resend");
      }
      this.resendClient = new Resend(config.email.apiKey);
    }
    return this.resendClient;
  }

  private async sendViaResend(options: SendEmailOptions): Promise<SendEmailResult> {
    const resend = this.getResend();
    const { data, error } = await resend.emails.send({
      from: this.from,
      to: options.to,
      subject: options.subject,
      text: options.text,
      html: options.html,
      replyTo: options.replyTo,
      headers: options.headers,
    });
    if (error) {
      logger.error("Resend rejected message", { to: options.to, error: error.message });
      return { success: false, error: error.message };
    }
    return { success: true, messageId: data?.id };
  }

  /**
   * Send the daily DCA signal digest. Returns whether the send succeeded
   * and the provider message id for audit (NotificationDelivery row).
   */
  async sendDailySignalDigest(to: string, data: DailySignalDigestData): Promise<SendEmailResult> {
    const { html, text, subject } = dailySignalDigestEmail(data);
    return this.send({ to, subject, html, text });
  }

  // ============================================================================
  // Public Email Methods
  // ============================================================================

  /**
   * Send welcome email to new user
   */
  async sendWelcomeEmail(user: EmailUser): Promise<SendEmailResult> {
    const { html, text } = welcomeEmail({
      name: user.name,
      email: user.email,
    });

    return this.send({
      to: user.email,
      subject: `Welcome to ${config.app.name}!`,
      html,
      text,
    });
  }

  /**
   * Send password reset email
   */
  async sendPasswordResetEmail(
    user: EmailUser,
    token: string,
    expiresInMinutes: number = 60
  ): Promise<SendEmailResult> {
    const { html, text } = passwordResetEmail({
      name: user.name,
      email: user.email,
      resetToken: token,
      expiresInMinutes,
    });

    return this.send({
      to: user.email,
      subject: `Reset Your ${config.app.name} Password`,
      html,
      text,
    });
  }

  /**
   * Send email verification email
   */
  async sendEmailVerificationEmail(
    user: EmailUser,
    token: string,
    expiresInHours: number = 24
  ): Promise<SendEmailResult> {
    const { html, text } = emailVerificationEmail({
      name: user.name,
      email: user.email,
      verificationToken: token,
      expiresInHours,
    });

    return this.send({
      to: user.email,
      subject: `Verify Your ${config.app.name} Email Address`,
      html,
      text,
    });
  }

  /**
   * Send password changed notification
   */
  async sendPasswordChangedEmail(user: EmailUser): Promise<SendEmailResult> {
    const { html, text } = passwordChangedEmail({
      name: user.name,
      email: user.email,
      changedAt: new Date(),
    });

    return this.send({
      to: user.email,
      subject: `Your ${config.app.name} Password Has Been Changed`,
      html,
      text,
    });
  }

}

// Export singleton instance
export const emailService = new EmailService();
