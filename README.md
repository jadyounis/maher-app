# MAHER

Two-sided service marketplace for Jordan — **كل خدمة. الشخص المناسب.**

## Product
- **Customer App** — create service requests, choose hourly/daily/contract pricing, receive offers, compare professionals, follow the job and review it.
- **Professional App** — receive eligible requests, submit quotations, manage accepted jobs and update job status.
- **Admin Dashboard** — operational control center for requests, users, professional verification, reports, moderation, commissions and financial visibility.

## Backend
Supabase is the shared backend for authentication, PostgreSQL data, row-level security and realtime updates.

The current backend includes the request → offer → accepted job flow, configurable commission, role-based access control, moderation actions and realtime tables.

## Pricing modes
- **بالساعة** — customer pays an hourly amount; MAHER commission is calculated from the full customer payment.
- **يومي** — configurable daily price.
- **مقاولة** — professionals submit quotations and the accepted quote becomes the agreed job price.

## Build
GitHub Actions builds the Customer and Professional Android APKs. A separate workflow packages the Admin Dashboard for deployment.

Runtime Supabase credentials are injected at build/package time and are not committed to the repository.

## Project structure
```text
customer_app/          Customer Flutter app
professional_app/      Professional Flutter app
admin_dashboard/       Admin web dashboard
 docs/MAHER_PRODUCT_SPEC.md
.github/workflows/      Mobile + dashboard CI
```

## Current stage
The core shared backend and app-side integration are in place. Production launch still requires external services such as SMS/OTP provider configuration, maps/location, payment processing, push notifications, storage/media policies and final Play Store deployment settings.
