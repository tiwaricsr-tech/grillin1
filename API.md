# Tableflow API reference

Base path: `/api`. JSON request/response unless noted. Staff endpoints use `Authorization: Bearer <token>` from admin PIN login. All prices are INR. Requests are validated with Zod; errors return `{ "error": "..." }` (validation failures also include issue details).

## Public customer endpoints

- `GET /health` — service check.
- `GET /menu` — active categories, available products/variants, active tables and restaurant settings.
- `POST /coupons/validate` — `{ "code": "WELCOME10", "subtotal": 500 }`; returns backend-calculated discount or `400` with a reason.
- `POST /orders` — `{ "customerName":"Asha", "type":"DINE_IN|TAKEAWAY", "tableLabel":"T1", "paymentMethod":"COUNTER|RAZORPAY", "notes":"No onion", "couponCode":"WELCOME10", "items":[{"variantId":"...","quantity":2}] }`. `tableLabel` is required for dine-in. Prices/taxes/discount are re-read and calculated by the server; product and variant snapshots are saved on order items.
- `GET /orders/:id` — current order, items and status history.
- `POST /orders/:id/cancellation` — `{ "reason":"..." }` creates a request for admin approval.
- `POST /support` — `{ "customerName":"Asha", "orderId":"...", "subject":"...", "message":"..." }` creates a ticket.

## Razorpay checkout

Configure `RAZORPAY_KEY_ID` and `RAZORPAY_KEY_SECRET` on the API only.

1. Create an order with `paymentMethod: "RAZORPAY"`.
2. `POST /payments/razorpay/:orderId/create` — creates/reuses a Razorpay order and returns `keyId`, `razorpayOrderId`, amount in paise and currency. The browser uses those fields to open Razorpay Checkout.
3. On Checkout success, send `{ "orderId":"...", "razorpay_order_id":"...", "razorpay_payment_id":"...", "razorpay_signature":"..." }` to `POST /payments/razorpay/verify`.
4. The API verifies the HMAC signature and fetches the payment from Razorpay; it checks order link, amount, INR currency and `captured` status before marking the order paid. Duplicate verification for the same payment is safe.

Do not mark Razorpay orders paid from an admin/client action. Webhook reconciliation, refund execution and settlement handling are not included yet.

## Staff endpoints

Login: `POST /admin/login` — `{ "pin":"..." }`; responds with bearer token and staff role. Rate limited. Token expires after 12 hours.

- Integrations: `GET /admin/integrations` returns configuration state and masked identifiers only; `PUT /admin/integrations/razorpay` accepts `{ "keyId":"rzp_test_…", "secretKey":"…", "testMode":true }`. Secret values are AES-256-GCM encrypted with `INTEGRATION_ENCRYPTION_KEY`; never returned by GET.
- Orders: `GET /admin/orders`; `PATCH /admin/orders/:id/status` — `{ "status":"ACCEPTED|PREPARING|READY|COMPLETED|CANCELLED" }`; server enforces legal next steps. `PATCH /admin/orders/:id/payment` — `{ "paymentStatus":"PAID|PENDING|REFUNDED" }`; only counter payments may be manually marked paid.
- Product images: `POST /admin/uploads/images` with `{ "mimeType":"image/jpeg|image/png|image/webp", "data":"data:image/...;base64,..." }`; responds with `{ "imageUrl":"..." }`. Uploads are stored under `uploads/product-images/` in development and use Cloudinary in production.
- Products: `GET|POST /admin/products`; `PATCH /admin/products/:id`; `DELETE /admin/products/:id` (hard-deletes the menu entry; order-item snapshots remain for history). Create body: `{ "name":"...", "description":"...", "categoryId":"...", "imageUrl":"https://...", "isVeg":true, "bestseller":false, "taxRate":5, "variants":[{"name":"Half","price":120}] }`.
- Coupons: `GET|POST /admin/coupons`; `PATCH /admin/coupons/:id` with `{ "active":true }`. Create body accepts `code`, `type` (`PERCENTAGE|FIXED`), `value`, `minOrder`, optional `maxDiscount`, `usageLimit`, `expiresAt`.
- Tables: `GET|POST /admin/tables`; create `{ "label":"T4", "capacity":2 }`.
- Analytics: `GET /admin/analytics?from=ISO_DATE&to=ISO_DATE`.
- Export: `GET /admin/export.csv?from=ISO_DATE&to=ISO_DATE` returns a downloadable CSV.
- Guest care: `GET /admin/support`; `PATCH /admin/cancellations/:id` with `{ "status":"APPROVED|REJECTED", "adminNote":"..." }`; `PATCH /admin/support/:id` with `{ "status":"OPEN|RESOLVED", "reply":"..." }`.

## Realtime Socket.IO

Client connects to the API origin. Server broadcasts `admin:new-order` and `admin:order-updated`. Customer emits `order:subscribe` with its order ID; server emits `order:updated` to that room. The browser also polls the order endpoint as a reconnect fallback.

## Order lifecycle

`PLACED → ACCEPTED → PREPARING → READY → COMPLETED`; cancellation is allowed before `READY`. Razorpay orders cannot be accepted into the kitchen before server verification.
