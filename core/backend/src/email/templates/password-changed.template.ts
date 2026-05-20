/**
 * Password Changed Notification Template
 *
 * Sent to users after their password has been successfully changed.
 * This is a security notification to alert users of account changes.
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

export interface PasswordChangedEmailData {
  name: string | null;
  email: string;
  changedAt?: Date;
}

/**
 * Generate password changed notification email HTML and plain text
 */
export function passwordChangedEmail(data: PasswordChangedEmailData): EmailOutput {
  const { name, email, changedAt = new Date() } = data;
  const branding = config.app;
  const displayName = name || "there";
  const resetUrl = `${config.frontendUrl}/forgot-password`;

  // Format the date nicely
  const formattedDate = changedAt.toLocaleDateString("en-US", {
    weekday: "long",
    year: "numeric",
    month: "long",
    day: "numeric",
  });
  const formattedTime = changedAt.toLocaleTimeString("en-US", {
    hour: "2-digit",
    minute: "2-digit",
    timeZoneName: "short",
  });

  const content = `
    ${emailHeading("Your Password Has Been Changed")}

    ${emailParagraph(`Hi ${displayName},`)}

    ${emailParagraph(`
      The password for your ${branding.name} account (${email}) was recently changed.
    `)}

    <table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0" style="margin: 16px 0; background-color: #f4f4f5; border-radius: 6px;">
      <tr>
        <td style="padding: 16px;">
          <table role="presentation" cellpadding="0" cellspacing="0" border="0">
            <tr>
              <td style="padding: 4px 0; font-size: 14px; color: #71717a;">Date:</td>
              <td style="padding: 4px 0 4px 16px; font-size: 14px; color: #27272a; font-weight: 600;">${formattedDate}</td>
            </tr>
            <tr>
              <td style="padding: 4px 0; font-size: 14px; color: #71717a;">Time:</td>
              <td style="padding: 4px 0 4px 16px; font-size: 14px; color: #27272a; font-weight: 600;">${formattedTime}</td>
            </tr>
          </table>
        </td>
      </tr>
    </table>

    ${emailWarningBox(`
      <strong>Didn't make this change?</strong><br>
      If you didn't change your password, your account may have been compromised.
      Please reset your password immediately and contact our support team.
    `)}

    ${emailButton("Reset Password Now", resetUrl, "secondary")}

    ${emailDivider()}

    ${emailMutedText(`
      If you did make this change, no further action is required. This email is just
      a confirmation for your security.
    `)}

    ${emailMutedText(`
      Need help? Contact us at
      <a href="mailto:${branding.supportEmail}" style="color: ${branding.primaryColor};">${branding.supportEmail}</a>.
    `)}
  `;

  const html = baseTemplate({
    content,
    previewText: `Your ${branding.name} password was changed`,
    showUnsubscribe: false,
  });

  const text = `
Your Password Has Been Changed

Hi ${displayName},

The password for your ${branding.name} account (${email}) was recently changed.

Date: ${formattedDate}
Time: ${formattedTime}

DIDN'T MAKE THIS CHANGE?
If you didn't change your password, your account may have been compromised.
Please reset your password immediately:
${resetUrl}

If you did make this change, no further action is required. This email is just a confirmation for your security.

Need help? Contact us at ${branding.supportEmail}.

---
${branding.name}
${config.frontendUrl}
  `.trim();

  return { html, text };
}
