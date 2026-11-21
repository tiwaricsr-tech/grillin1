ALTER TABLE "Order"
  ADD COLUMN "customerPhone" TEXT,
  ADD COLUMN "whatsappOptIn" BOOLEAN NOT NULL DEFAULT false,
  ADD COLUMN "whatsappReceiptSentAt" TIMESTAMP(3),
  ADD COLUMN "whatsappReceiptError" TEXT;

CREATE TABLE "IntegrationSettings" (
  "id" TEXT NOT NULL DEFAULT 'default',
  "razorpayKeyId" TEXT,
  "razorpaySecretEncrypted" TEXT,
  "razorpayTestMode" BOOLEAN NOT NULL DEFAULT true,
  "whatsappAccessTokenEncrypted" TEXT,
  "whatsappPhoneNumberId" TEXT,
  "whatsappTemplateName" TEXT NOT NULL DEFAULT 'restaurant_order_receipt',
  "whatsappLanguage" TEXT NOT NULL DEFAULT 'en',
  "whatsappGraphVersion" TEXT NOT NULL DEFAULT 'v23.0',
  "whatsappActive" BOOLEAN NOT NULL DEFAULT false,
  "updatedAt" TIMESTAMP(3) NOT NULL,
  CONSTRAINT "IntegrationSettings_pkey" PRIMARY KEY ("id")
);
