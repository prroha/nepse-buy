/**
 * Feature Flag Utilities
 */

// Feature slug constants for type safety
export const Features = {
  // Auth
  AUTH_BASIC: "auth.basic",
  AUTH_SOCIAL: "auth.social",
  AUTH_MFA: "auth.mfa",
  AUTH_SSO: "auth.sso",
  AUTH_MAGIC_LINK: "auth.magic-link",

  // Security
  SECURITY_RBAC: "security.rbac",
  SECURITY_AUDIT: "security.audit",
  SECURITY_ENCRYPTION: "security.encryption",

  // Payments
  PAYMENTS_STRIPE: "payments.stripe",
  PAYMENTS_WEBHOOKS: "payments.webhooks",
  PAYMENTS_SUBSCRIPTIONS: "payments.subscriptions",
  PAYMENTS_MULTI_CURRENCY: "payments.multi-currency",

  // Storage
  STORAGE_UPLOAD: "storage.upload",
  STORAGE_S3: "storage.s3",
  STORAGE_LOCAL: "storage.local",
  STORAGE_CDN: "storage.cdn",
  STORAGE_BACKUP: "storage.backup",

  // Communications
  COMMS_EMAIL: "comms.email",
  COMMS_PUSH: "comms.push",
  COMMS_SMS: "comms.sms",
  COMMS_REALTIME: "comms.realtime",

  // UI
  UI_DASHBOARD: "ui.dashboard",
  UI_COMPONENTS: "ui.components",
  UI_THEMES: "ui.themes",
  UI_FORMS: "ui.forms",
  UI_CHARTS: "ui.charts",

  // Analytics
  ANALYTICS_BASIC: "analytics.basic",
  ANALYTICS_DASHBOARD: "analytics.dashboard",
  ANALYTICS_REPORTS: "analytics.reports",
  ANALYTICS_EXPORT: "analytics.export",

  // Mobile
  MOBILE_CORE: "mobile.core",
  MOBILE_PUSH: "mobile.push",
  MOBILE_OFFLINE: "mobile.offline",

  // Infrastructure
  INFRA_DOCKER: "infra.docker",
  INFRA_KUBERNETES: "infra.kubernetes",
  INFRA_CI_CD: "infra.ci-cd",

  // Integrations
  INTEGRATIONS_WEBHOOKS: "integrations.webhooks",
  INTEGRATIONS_API: "integrations.api",
  INTEGRATIONS_ZAPIER: "integrations.zapier",
} as const;

export type FeatureSlug = (typeof Features)[keyof typeof Features];
