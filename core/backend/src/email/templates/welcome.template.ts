/**
 * Welcome Email Template
 *
 * Sent to new users after registration to welcome them to the app.
 */

import { config } from "../../config/index.js";
import {
  baseTemplate,
  emailButton,
  emailHeading,
  emailParagraph,
  emailMutedText,
  emailDivider,
  EmailOutput,
} from "./base.template.js";

export interface WelcomeEmailData {
  name: string | null;
  email: string;
}

/**
 * Generate welcome email HTML and plain text
 */
export function welcomeEmail(data: WelcomeEmailData): EmailOutput {
  const { name, email } = data;
  const branding = config.app;
  const displayName = name || "there";
  const dashboardUrl = `${config.frontendUrl}/dashboard`;

  const content = `
    ${emailHeading(`Welcome to ${branding.name}!`)}

    ${emailParagraph(`Hi ${displayName},`)}

    ${emailParagraph(`
      Thank you for joining ${branding.name}! We're excited to have you on board.
    `)}

    ${emailParagraph(`
      Your account has been created successfully and you're ready to get started.
      Click the button below to explore your dashboard:
    `)}

    ${emailButton("Go to Dashboard", dashboardUrl)}

    ${emailDivider()}

    ${emailHeading("Getting Started", 2)}

    ${emailParagraph(`
      Here are a few things you can do to get the most out of ${branding.name}:
    `)}

    <table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0" style="margin: 0 0 16px 0;">
      <tr>
        <td style="padding: 8px 0; font-size: 16px; line-height: 24px; color: #27272a;">
          <strong style="color: ${branding.primaryColor};">1.</strong> Complete your profile to personalize your experience
        </td>
      </tr>
      <tr>
        <td style="padding: 8px 0; font-size: 16px; line-height: 24px; color: #27272a;">
          <strong style="color: ${branding.primaryColor};">2.</strong> Explore the features and discover what's possible
        </td>
      </tr>
      <tr>
        <td style="padding: 8px 0; font-size: 16px; line-height: 24px; color: #27272a;">
          <strong style="color: ${branding.primaryColor};">3.</strong> Reach out to our support team if you need any help
        </td>
      </tr>
    </table>

    ${emailDivider()}

    ${emailMutedText(`
      If you have any questions, feel free to reply to this email or contact us at
      <a href="mailto:${branding.supportEmail}" style="color: ${branding.primaryColor};">${branding.supportEmail}</a>.
    `)}

    ${emailMutedText(`
      You're receiving this email because you signed up for ${branding.name} with ${email}.
    `)}
  `;

  const html = baseTemplate({
    content,
    previewText: `Welcome to ${branding.name}! Your account is ready.`,
  });

  const text = `
Welcome to ${branding.name}!

Hi ${displayName},

Thank you for joining ${branding.name}! We're excited to have you on board.

Your account has been created successfully and you're ready to get started.

Go to Dashboard: ${dashboardUrl}

---

Getting Started:

1. Complete your profile to personalize your experience
2. Explore the features and discover what's possible
3. Reach out to our support team if you need any help

---

If you have any questions, feel free to contact us at ${branding.supportEmail}.

You're receiving this email because you signed up for ${branding.name} with ${email}.

---
${branding.name}
${config.frontendUrl}
  `.trim();

  return { html, text };
}
