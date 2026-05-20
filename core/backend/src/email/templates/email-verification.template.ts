/**
 * Email Verification Template
 *
 * Sent to users to verify their email address after registration.
 */

import { config } from "../../config/index.js";
import {
  baseTemplate,
  emailButton,
  emailHeading,
  emailParagraph,
  emailMutedText,
  emailInfoBox,
  emailDivider,
  EmailOutput,
} from "./base.template.js";

export interface EmailVerificationData {
  name: string | null;
  email: string;
  verificationToken: string;
  expiresInHours?: number;
}

/**
 * Generate email verification HTML and plain text
 */
export function emailVerificationEmail(data: EmailVerificationData): EmailOutput {
  const { name, email: _email, verificationToken, expiresInHours = 24 } = data;
  const branding = config.app;
  const displayName = name || "there";
  const verifyUrl = `${config.frontendUrl}/verify-email?token=${verificationToken}`;

  const content = `
    ${emailHeading("Verify Your Email Address")}

    ${emailParagraph(`Hi ${displayName},`)}

    ${emailParagraph(`
      Thanks for signing up for ${branding.name}! To complete your registration,
      please verify your email address by clicking the button below:
    `)}

    ${emailButton("Verify Email Address", verifyUrl)}

    ${emailInfoBox(`
      This verification link will expire in <strong>${expiresInHours} hours</strong>.
      If you need a new link, you can request one from the login page.
    `)}

    ${emailDivider()}

    ${emailMutedText(`
      If the button above doesn't work, copy and paste this link into your browser:
    `)}

    <p style="margin: 0 0 16px 0; font-size: 13px; line-height: 20px; color: #71717a; word-break: break-all;">
      <a href="${verifyUrl}" style="color: ${branding.primaryColor};">${verifyUrl}</a>
    </p>

    ${emailDivider()}

    ${emailMutedText(`
      If you didn't create an account with ${branding.name}, please ignore this email
      or contact us at <a href="mailto:${branding.supportEmail}" style="color: ${branding.primaryColor};">${branding.supportEmail}</a>.
    `)}
  `;

  const html = baseTemplate({
    content,
    previewText: `Verify your email address for ${branding.name}`,
    showUnsubscribe: false,
  });

  const text = `
Verify Your Email Address

Hi ${displayName},

Thanks for signing up for ${branding.name}! To complete your registration, please verify your email address.

Verify your email by visiting this link:
${verifyUrl}

This verification link will expire in ${expiresInHours} hours. If you need a new link, you can request one from the login page.

If you didn't create an account with ${branding.name}, please ignore this email or contact us at ${branding.supportEmail}.

---
${branding.name}
${config.frontendUrl}
  `.trim();

  return { html, text };
}
