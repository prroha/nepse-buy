/**
 * Email Templates Index
 */

// Base template and utilities
export {
  baseTemplate,
  emailButton,
  emailDivider,
  emailParagraph,
  emailHeading,
  emailMutedText,
  emailInfoBox,
  emailWarningBox,
  htmlToPlainText,
  type BaseTemplateOptions,
  type EmailOutput,
} from "./base.template.js";

// Individual templates
export { welcomeEmail, type WelcomeEmailData } from "./welcome.template.js";
export { passwordResetEmail, type PasswordResetEmailData } from "./password-reset.template.js";
export { emailVerificationEmail, type EmailVerificationData } from "./email-verification.template.js";
export { passwordChangedEmail, type PasswordChangedEmailData } from "./password-changed.template.js";
export { dailySignalDigestEmail, type DailySignalDigestData, type DigestSignalRow } from "./daily-signal-digest.template.js";
