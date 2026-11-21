ALTER TABLE "Order"
  DROP COLUMN "customerPhone",
  DROP COLUMN "whatsappOptIn",
  DROP COLUMN "whatsappReceiptSentAt",
  DROP COLUMN "whatsappReceiptError";

ALTER TABLE "IntegrationSettings"
  DROP COLUMN "whatsappAccessTokenEncrypted",
  DROP COLUMN "whatsappPhoneNumberId",
  DROP COLUMN "whatsappTemplateName",
  DROP COLUMN "whatsappLanguage",
  DROP COLUMN "whatsappGraphVersion",
  DROP COLUMN "whatsappActive";
