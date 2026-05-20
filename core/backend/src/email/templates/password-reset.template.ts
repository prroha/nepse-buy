/**
 * Password Reset Email Template
 *
 * Sent when a user requests to reset their password.
 */

import { config } from "../../config/index.js";
import {
  baseTemplate,
  emailButton,
  emailHeading,
  emailParagraph,
  emailMutedText,
  emailWarningBox,
  emailDivider,
  EmailOutput,
} from "./base.template.js";

export interface PasswordResetEmailData {
  name: string | null;
  email: string;
  resetToken: string;
  expiresInMinutes?: number;
}

/**
 * Generate password reset email HTML and plain text
 */
export function passwordResetEmail(data: PasswordResetEmailData): EmailOutput {
  const { name, email, resetToken, expiresInMinutes = 60 } = data;
  const branding = config.app;
  const displayName = name || "there";
  const resetUrl = `${config.frontendUrl}/reset-password?token=${resetToken}`;

  const content = `
    ${emailHeading("Reset Your Password")}

    ${emailParagraph(`Hi ${displayName},`)}

    ${emailParagraph(`
      We received a request to reset the password for your ${branding.name} account
      associated with ${email}.
    `)}

    ${emailParagraph(`
      Click the button below to create a new password:
    `)}

    ${emailButton("Reset Password", resetUrl)}

    ${emailWarningBox(`
      <strong>This link will expire in ${expiresInMinutes} minutes.</strong><br>
      If you didn't request a password reset, you can safely ignore this email.
      Your password will remain unchanged.
    `)}

    ${emailDivider()}

    ${emailMutedText(`
      If the button above doesn't work, copy and paste this link into your browser:
    `)}

    <p style="margin: 0 0 16px 0; font-size: 13px; line-height: 20px; color: #71717a; word-break: break-all;">
      <a href="${resetUrl}" style="color: ${branding.primaryColor};">${resetUrl}</a>
    </p>

    ${emailDivider()}

    ${emailMutedText(`
      If you didn't request this password reset, please contact us immediately at
      <a href="mailto:${branding.supportEmail}" style="color: ${branding.primaryColor};">${branding.supportEmail}</a>.
    `)}
  `;

  const html = baseTemplate({
    content,
    previewText: `Reset your ${branding.name} password`,
    showUnsubscribe: false,
  });

  const text = `
Reset Your Password

Hi ${displayName},

We received a request to reset the password for your ${branding.name} account associated with ${email}.

To reset your password, visit this link:
${resetUrl}

IMPORTANT: This link will expire in ${expiresInMinutes} minutes.

If you didn't request a password reset, you can safely ignore this email. Your password will remain unchanged.

If you didn't request this password reset, please contact us immediately at ${branding.supportEmail}.

---
${branding.name}
${config.frontendUrl}
  `.trim();

  return { html, text };
}
