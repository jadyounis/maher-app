# MAHER iOS TestFlight CI

The iOS workflow builds both MAHER apps, stores unsigned iOS archives as CI artifacts, and can produce signed IPAs and upload them to App Store Connect when Apple signing credentials are present.

## Bundle IDs

- Customer: `com.maher.customer`
- Professional: `com.maher.professional`

## Required GitHub Actions secrets for signing

- `APPLE_CERTIFICATE_BASE64` — Base64 of the Apple Distribution `.p12` certificate
- `APPLE_CERTIFICATE_PASSWORD` — Password for the `.p12`
- `APPLE_PROVISIONING_PROFILE_CUSTOMER_BASE64` — Base64 of the App Store provisioning profile for `com.maher.customer`
- `APPLE_PROVISIONING_PROFILE_PROFESSIONAL_BASE64` — Base64 of the App Store provisioning profile for `com.maher.professional`
- `APPLE_DEVELOPMENT_TEAM` — Apple Team ID
- `APPLE_SIGNING_CERTIFICATE` — Signing certificate name, normally `Apple Distribution`

## Required GitHub Actions secrets for App Store Connect upload

- `APPSTORE_CONNECT_API_KEY_BASE64` — Base64 of the App Store Connect Team API `.p8` private key
- `APPSTORE_CONNECT_KEY_ID` — Team API key ID
- `APPSTORE_CONNECT_ISSUER_ID` — Team API issuer ID

The existing Supabase secret remains:

- `MAHER_SUPABASE_PUBLISHABLE_KEY`

Never store an Apple private key, signing certificate, or Supabase service-role key in source control.
