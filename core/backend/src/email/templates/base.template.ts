/**
 * Base Email Template
 *
 * Provides a consistent, branded, mobile-responsive wrapper for all email templates.
 * Uses inline CSS for maximum email client compatibility.
 */

import { config } from "../../config/index.js";

export interface BaseTemplateOptions {
  /** Main content HTML */
  content: string;
  /** Preview text shown in email client before opening */
  previewText?: string;
  /** Whether to show the unsubscribe link */
  showUnsubscribe?: boolean;
  /** Custom footer text */
  footerText?: string;
}

export interface EmailOutput {
  /** Full HTML email content */
  html: string;
  /** Plain text alternative */
  text: string;
}

/**
 * Get app branding values
 */
function getBranding() {
  return {
    appName: config.app.name,
    primaryColor: config.app.primaryColor,
    logoUrl: config.app.logoUrl,
    supportEmail: config.app.supportEmail,
    frontendUrl: config.frontendUrl,
  };
}

/**
 * Generate base HTML email template
 */
export function baseTemplate(options: BaseTemplateOptions): string {
  const { content, previewText, showUnsubscribe = true, footerText } = options;
  const branding = getBranding();
  const year = new Date().getFullYear();

  return `
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <meta http-equiv="X-UA-Compatible" content="IE=edge">
  <meta name="x-apple-disable-message-reformatting">
  <title>${branding.appName}</title>
  <!--[if mso]>
  <noscript>
    <xml>
      <o:OfficeDocumentSettings>
        <o:PixelsPerInch>96</o:PixelsPerInch>
      </o:OfficeDocumentSettings>
    </xml>
  </noscript>
  <![endif]-->
  <style>
    /* Reset styles */
    body, table, td, p, a, li, blockquote {
      -webkit-text-size-adjust: 100%;
      -ms-text-size-adjust: 100%;
    }
    table, td {
      mso-table-lspace: 0pt;
      mso-table-rspace: 0pt;
    }
    img {
      -ms-interpolation-mode: bicubic;
      border: 0;
      height: auto;
      line-height: 100%;
      outline: none;
      text-decoration: none;
    }
    body {
      margin: 0 !important;
      padding: 0 !important;
      width: 100% !important;
      background-color: #f4f4f5;
    }
    /* Mobile styles */
    @media only screen and (max-width: 600px) {
      .container {
        width: 100% !important;
        padding: 16px !important;
      }
      .content {
        padding: 24px 16px !important;
      }
      .button {
        width: 100% !important;
        display: block !important;
      }
    }
  </style>
</head>
<body style="margin: 0; padding: 0; width: 100%; background-color: #f4f4f5; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;">
  ${previewText ? `
  <!-- Preview text (hidden) -->
  <div style="display: none; font-size: 1px; line-height: 1px; max-height: 0px; max-width: 0px; opacity: 0; overflow: hidden; mso-hide: all;">
    ${previewText}
    ${"&zwnj;&nbsp;".repeat(50)}
  </div>
  ` : ""}

  <!-- Main container -->
  <table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0" style="background-color: #f4f4f5;">
    <tr>
      <td align="center" style="padding: 40px 16px;">

        <!-- Email wrapper -->
        <table role="presentation" class="container" width="600" cellpadding="0" cellspacing="0" border="0" style="max-width: 600px; width: 100%;">

          <!-- Header -->
          <tr>
            <td align="center" style="padding-bottom: 24px;">
              ${branding.logoUrl ? `
              <img src="${branding.logoUrl}" alt="${branding.appName}" width="150" style="display: block; max-width: 150px; height: auto;">
              ` : `
              <div style="font-size: 28px; font-weight: 700; color: ${branding.primaryColor}; letter-spacing: -0.5px;">
                ${branding.appName}
              </div>
              `}
            </td>
          </tr>

          <!-- Content card -->
          <tr>
            <td>
              <table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0" style="background-color: #ffffff; border-radius: 8px; box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);">
                <tr>
                  <td class="content" style="padding: 40px 48px;">
                    ${content}
                  </td>
                </tr>
              </table>
            </td>
          </tr>

          <!-- Footer -->
          <tr>
            <td align="center" style="padding-top: 32px;">
              <table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0">
                <tr>
                  <td align="center" style="color: #71717a; font-size: 13px; line-height: 20px;">
                    ${footerText || `
                    <p style="margin: 0 0 8px 0;">
                      This email was sent by ${branding.appName}.
                    </p>
                    `}
                    <p style="margin: 0 0 8px 0;">
                      <a href="${branding.frontendUrl}" style="color: ${branding.primaryColor}; text-decoration: none;">${branding.frontendUrl.replace(/^https?:\/\//, "")}</a>
                    </p>
                    ${showUnsubscribe ? `
                    <p style="margin: 0 0 8px 0;">
                      <a href="{{unsubscribe_url}}" style="color: #71717a; text-decoration: underline;">Unsubscribe</a>
                      &nbsp;|&nbsp;
                      <a href="${branding.frontendUrl}/preferences" style="color: #71717a; text-decoration: underline;">Email preferences</a>
                    </p>
                    ` : ""}
                    <p style="margin: 16px 0 0 0; color: #a1a1aa; font-size: 12px;">
                      &copy; ${year} ${branding.appName}. All rights reserved.
                    </p>
                  </td>
                </tr>
              </table>
            </td>
          </tr>

        </table>

      </td>
    </tr>
  </table>
</body>
</html>
`.trim();
}

/**
 * Generate a styled button for emails
 */
export function emailButton(text: string, url: string, variant: "primary" | "secondary" = "primary"): string {
  const branding = getBranding();
  const isPrimary = variant === "primary";

  return `
<table role="presentation" cellpadding="0" cellspacing="0" border="0" style="margin: 24px 0;">
  <tr>
    <td align="center" style="border-radius: 6px; background-color: ${isPrimary ? branding.primaryColor : "#ffffff"}; border: ${isPrimary ? "none" : `2px solid ${branding.primaryColor}`};">
      <a href="${url}" target="_blank" class="button" style="display: inline-block; padding: 14px 28px; font-size: 16px; font-weight: 600; color: ${isPrimary ? "#ffffff" : branding.primaryColor}; text-decoration: none; border-radius: 6px;">
        ${text}
      </a>
    </td>
  </tr>
</table>
`.trim();
}

/**
 * Generate a divider line
 */
export function emailDivider(): string {
  return `
<table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0" style="margin: 24px 0;">
  <tr>
    <td style="border-top: 1px solid #e4e4e7;"></td>
  </tr>
</table>
`.trim();
}

/**
 * Style for paragraph text
 */
export function emailParagraph(text: string): string {
  return `<p style="margin: 0 0 16px 0; font-size: 16px; line-height: 24px; color: #27272a;">${text}</p>`;
}

/**
 * Style for heading text
 */
export function emailHeading(text: string, level: 1 | 2 | 3 = 1): string {
  const sizes = { 1: "24px", 2: "20px", 3: "18px" };
  const margins = { 1: "0 0 24px 0", 2: "0 0 16px 0", 3: "0 0 12px 0" };

  return `<h${level} style="margin: ${margins[level]}; font-size: ${sizes[level]}; font-weight: 700; color: #18181b; line-height: 1.3;">${text}</h${level}>`;
}

/**
 * Style for muted/secondary text
 */
export function emailMutedText(text: string): string {
  return `<p style="margin: 0 0 16px 0; font-size: 14px; line-height: 20px; color: #71717a;">${text}</p>`;
}

/**
 * Style for a highlighted info box
 */
export function emailInfoBox(content: string): string {
  const branding = getBranding();

  return `
<table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0" style="margin: 16px 0;">
  <tr>
    <td style="padding: 16px; background-color: #f0f9ff; border-left: 4px solid ${branding.primaryColor}; border-radius: 4px;">
      <div style="font-size: 14px; line-height: 20px; color: #1e3a5f;">
        ${content}
      </div>
    </td>
  </tr>
</table>
`.trim();
}

/**
 * Style for a warning box
 */
export function emailWarningBox(content: string): string {
  return `
<table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0" style="margin: 16px 0;">
  <tr>
    <td style="padding: 16px; background-color: #fef3c7; border-left: 4px solid #f59e0b; border-radius: 4px;">
      <div style="font-size: 14px; line-height: 20px; color: #78350f;">
        ${content}
      </div>
    </td>
  </tr>
</table>
`.trim();
}

/**
 * Convert HTML email to plain text
 * Simple conversion for email clients that don't support HTML
 */
export function htmlToPlainText(html: string): string {
  return html
    // Remove style and script tags with their content
    .replace(/<style[^>]*>[\s\S]*?<\/style>/gi, "")
    .replace(/<script[^>]*>[\s\S]*?<\/script>/gi, "")
    // Convert links to text with URL
    .replace(/<a[^>]*href="([^"]*)"[^>]*>([^<]*)<\/a>/gi, "$2 ($1)")
    // Convert headings to text with emphasis
    .replace(/<h[1-6][^>]*>([^<]*)<\/h[1-6]>/gi, "\n\n$1\n" + "=".repeat(40) + "\n")
    // Convert paragraphs to text with newlines
    .replace(/<p[^>]*>/gi, "\n")
    .replace(/<\/p>/gi, "\n")
    // Convert line breaks
    .replace(/<br\s*\/?>/gi, "\n")
    // Convert list items
    .replace(/<li[^>]*>/gi, "\n  - ")
    .replace(/<\/li>/gi, "")
    // Remove remaining HTML tags
    .replace(/<[^>]+>/g, "")
    // Decode HTML entities
    .replace(/&nbsp;/gi, " ")
    .replace(/&amp;/gi, "&")
    .replace(/&lt;/gi, "<")
    .replace(/&gt;/gi, ">")
    .replace(/&quot;/gi, '"')
    .replace(/&#39;/gi, "'")
    .replace(/&copy;/gi, "(c)")
    .replace(/&zwnj;/gi, "")
    // Clean up whitespace
    .replace(/\n{3,}/g, "\n\n")
    .replace(/[ \t]+/g, " ")
    .trim();
}
