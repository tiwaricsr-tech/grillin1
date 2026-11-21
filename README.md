# Tableflow · Restaurant ordering & operations

A deployable monorepo starter for customer ordering, staff operations and kitchen order flow. Stack: React/Vite, Express/Socket.IO, Prisma and PostgreSQL.

## What's implemented

- Customer menu, category/search filters, variants and quantities, cart, takeaway/dine-in checkout, name-only customer identity, counter payment, order receipt, live order status, guided help bot for order status/cancellation requests, table-specific QR ordering links, and a customer-side menu/cart/orders navigation.
- Backend-authoritative product/variant prices, coupon validation, tax calculation, order snapshots and a transactionally saved order/status history.
- Admin PIN login (bcrypt hash + rate limit + 12-hour JWT), order lifecycle, kitchen queue, add/delete product management, availability controls, dining table management, downloadable per-table QR codes, live new-order notifications with opt-in chime, cancellations/support views, daily analytics and CSV sales export.
- Socket.IO for new orders and status changes; customer tracking also polls as a reconnect fallback.
- Razorpay Checkout flow with server-created payment orders, captured-payment verification, and idempotent duplicate verification. Admin Settings can save Razorpay credentials encrypted at rest; plaintext secrets are never returned to the UI.
- Prisma relational schema and seed routine. Sample menu/table/coupon records are development seed data; replace them before operating a restaurant.

## Local development (PowerShell or terminal)

Prerequisites: Node.js 20+, npm, and a Supabase project (or another PostgreSQL database). Copy `apps/api/.env.example` to `apps/api/.env`; set Supabase `DATABASE_URL` (runtime pooler) and `DIRECT_URL` (direct/session connection for migrations), a long random `JWT_SECRET`, `CLIENT_URL`, a private `INITIAL_ADMIN_PIN`, and `INTEGRATION_ENCRYPTION_KEY` (generate with `node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"`). Keep the encryption key backed up and stable or previously stored provider secrets cannot be decrypted. The web dev server proxies `/api` and Socket.IO to localhost:4000, so leave `VITE_API_URL` blank for local development and the live preview; set it to your Render API URL on Vercel.

```powershell
npm install
npm run db:generate
npm run db:migrate
npm --workspace apps/api run db:seed
npm run dev
```

Web: http://localhost:5173 · API health: http://localhost:4000/api/health. The seed is intentionally fail-closed unless `INITIAL_ADMIN_PIN` is set. In this workspace preview, the dev-only demo PIN is `998800`; it is read from the ignored `apps/api/.env` and is disabled automatically when `NODE_ENV=production`. It unlocks the portal preview, but live admin data/actions still need PostgreSQL. Never reuse this demo PIN or commit `.env` files.

## API outline

Public: `GET /api/health`, `GET /api/menu`, `POST /api/coupons/validate`, `POST /api/orders`, `GET /api/orders/:id`, `POST /api/orders/:id/cancellation`, `POST /api/support`.

Staff (Bearer JWT from `POST /api/admin/login`): `GET /api/admin/orders`, `PATCH /api/admin/orders/:id/status`, `PATCH /api/admin/orders/:id/payment`, `GET|POST /api/admin/products`, `PATCH /api/admin/products/:id`, `GET|POST /api/admin/tables`, `GET /api/admin/analytics?from=&to=`, `GET /api/admin/export.csv`, `GET /api/admin/support`, `PATCH /api/admin/cancellations/:id`, `PATCH /api/admin/support/:id`, `GET|POST /api/admin/coupons`.

Socket.IO events: server emits `admin:new-order` / `admin:order-updated`; customer client emits `order:subscribe` with order id and receives `order:updated`. Admin client refreshes every 15 seconds as a resiliency fallback.

## Deploy

### Render (API) + Supabase (PostgreSQL)
1. Create a Supabase project. In **Project Settings → Database → Connect**, copy the transaction-pooler URI for runtime as `DATABASE_URL` (port 6543; add `?pgbouncer=true&sslmode=require`) and a direct or session-pooler URI as `DIRECT_URL` (port 5432; `sslmode=require`). URL-encode special characters in the database password. Do not use the Supabase `anon` or `service_role` API key as a Postgres password.
2. Create a Node web service from this repo. Root directory: repository root. Build command: `npm install && npm run db:generate && npm --workspace apps/api run build`. Start command: `npm --workspace apps/api run db:migrate && npm --workspace apps/api run start`.
3. Set `DATABASE_URL`, `DIRECT_URL`, `JWT_SECRET`, `INTEGRATION_ENCRYPTION_KEY`, and `CLIENT_URL` (the exact Vercel site origin) in Render environment variables. The included `render.yaml` asks for these external database values. Never commit them.
4. After the service starts and migrations succeed, run `npm --workspace apps/api run db:seed` once in a secure shell with `INITIAL_ADMIN_PIN` set; remove that seed PIN variable afterward.

### Vercel (web)
1. Import this repo; set Root Directory to `apps/web`, Framework preset Vite, Build command `npm run build`, Output directory `dist`.
2. Add `VITE_API_URL=https://YOUR-API.onrender.com` as a Vercel environment variable and redeploy. This URL is used by browser code, so keep it to the public API origin. Store database URLs, `JWT_SECRET`, `INTEGRATION_ENCRYPTION_KEY`, and private payment credentials on the Render API service; do not commit them or expose them through a `VITE_` variable. The Render `CLIENT_URL` must include the exact Vercel origin.

## Production checklist / current boundaries

- Configure `INTEGRATION_ENCRYPTION_KEY` as a stable 32-byte hex secret in Render before saving integration credentials; it is intentionally separate from the database and must be backed up. Razorpay is implemented but must be tested with test keys. Refund execution and webhook reconciliation are not included.
- Replace seed/sample images, name/address/contact, menu, taxes and coupon with restaurant-approved details. Configure an image upload provider (Cloudinary/S3) for product management.
- Before public launch, add customer-owned order access (the current opaque order ID is used by the customer tracking link), admin PIN rotation/staff management, CSRF/session policy if cookie auth is introduced, audit logs, backups, monitoring, stricter CORS, retention policy and payment reconciliation.
- Product image uploads/full editing, coupon editing/deletion/expiry controls, custom analytics date-range controls, support replies, table edit/delete, and server-generated PDF files remain follow-up work. Browser thermal receipt printing is implemented with 58/80 mm layout selection; the browser can print to a connected receipt printer or Save as PDF. Printer output depends on the installed OS/browser driver. Do not treat this starter as payment-certified POS software.
- Tax computation currently uses each product's stored tax rate and a simple proportional discount allocation. Have a tax professional validate applicable GST treatment and bill wording for your jurisdiction.
