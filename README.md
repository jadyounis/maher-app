# MAHER

Two-sided service marketplace for Jordan:

- **Customer App** — request a service and compare professional offers.
- **Professional App** — receive nearby requests, send quotations and manage jobs.
- **Admin Dashboard** — planned control center for verification, jobs, payments, commissions and support.

## Pricing modes
- بالساعة — hourly
- يومي — daily
- مقاولة — contract / quotation

## Build
GitHub Actions builds two Android APK artifacts automatically on pushes to `main` or by manual workflow dispatch.

See `docs/MAHER_PRODUCT_SPEC.md` for the complete product flow and business rules.

## Important
The current mobile builds implement the UX and in-app state flow. Cross-device real-time synchronization requires the shared backend/API layer described in Phase B of the product specification.
