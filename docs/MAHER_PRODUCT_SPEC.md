# MAHER — Product Specification v0.3

## 1. Product
MAHER is a two-sided marketplace connecting customers who need a service with verified skilled professionals (الصنايعية).

## 2. Applications
- **MAHER Customer:** creates requests, receives offers, compares professionals, selects a professional, follows the job and reviews it.
- **MAHER Professional:** receives nearby requests, chooses jobs, sends offers, accepts assigned work, marks arrival/completion and tracks earnings.
- **Admin Dashboard:** manages accounts, verification, categories, requests, jobs, commissions, reviews, disputes and support.

## 3. Authentication
Both apps use the same Supabase Auth identity model:
1. Phone entry.
2. SMS OTP verification.
3. Account details.
4. Role-specific onboarding.

Professional accounts are activated/promoted by administration; a client cannot self-assign the professional role.

Professional onboarding additionally includes identity verification, skills, service areas and portfolio.

## 4. Service pricing modes
### Hourly — بالساعة
Customer pays an hourly amount. By default, MAHER takes **30% of the customer's gross payment** as platform commission and the professional receives **70%** before any separately configured adjustments.

Example: customer pays **10 JOD/hour** → MAHER commission **3 JOD** → professional amount **7 JOD**.

The commission rate is configurable by Admin.

### Daily — يومي
A full-day job uses a daily price. The initial example is **50 JOD/day**. The final price remains configurable per request and professional offer, and the same configurable commission framework applies at settlement.

### Contract — مقاولة
Customer publishes the job. Professionals submit their own quotations, for example 20, 25, 35 or 40 JOD. Customer compares the offers and accepts one. The accepted quotation becomes the agreed job price, and the configured commission applies to the gross settled amount.

## 5. Customer journey
Login → OTP → Home → Select service → Select pricing mode → Add description/media → Location → Date/time → Publish → Receive offers → Compare profile/rating/portfolio/price → Accept offer → Scheduled → Professional arrives → Arrival confirmation → Work in progress → Completed → Payment → Review.

## 6. Professional journey
Login → OTP → Professional profile → Verification → Skills/service areas → Incoming nearby requests → Open request → Submit offer → Customer accepts → Job appears in active work → Navigate to customer → Mark arrived → Work in progress → Mark completed → Earnings recorded → Review/reputation.

## 7. Job states
Draft → Published → Offers Received → Professional Selected → Scheduled → En Route → Arrived → In Progress → Completed → Paid → Reviewed.

## 8. Trust layer
Phone verified, identity verified, skills verified, portfolio, completed jobs, ratings/reviews and verification badge.

## 9. Matching
Match by service category + location + service area + availability + skills. Ranking/order is a product implementation detail and must remain configurable.

## 10. Core data model
- User
- ProfessionalProfile
- Skill
- ServiceCategory
- ServiceRequest
- Offer
- Job
- JobStatusEvent
- Location
- Payment
- Commission
- Review
- Notification
- Dispute
- SupportTicket

## 11. Business rules
- Only verified/active professionals should be eligible for jobs requiring verification.
- A customer can accept one offer per request.
- Once an offer is accepted, competing offers become closed.
- Arrival and completion are timestamped status events.
- Hourly jobs need start/end or billable-hour confirmation before final settlement.
- Contract jobs use the accepted quotation as the agreed amount.
- Commission rates and pricing defaults are admin-configurable.
- Admin moderation actions require an explicit action type and reason, and may include expiry or amount.

## 12. Technical phases
### Phase A — UX/MVP
Two Flutter Android apps with complete navigation and state flow. **Completed.**

### Phase B — Real connection
Shared Supabase backend/database, authentication scaffolding, secured RPCs, RLS, request/offer/job operations and Realtime subscriptions. **In progress.**

### Phase C — Production services
Maps/location, real payment provider, identity verification, chat/call, dispute workflow, admin dashboard, analytics, production secrets/configuration, monitoring, app-store release and end-to-end QA.
