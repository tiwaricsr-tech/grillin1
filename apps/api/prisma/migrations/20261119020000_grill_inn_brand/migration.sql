ALTER TABLE "RestaurantSettings" ALTER COLUMN "name" SET DEFAULT 'GRILL INN';
UPDATE "RestaurantSettings" SET "name" = 'GRILL INN' WHERE "name" = 'The Green Table';
