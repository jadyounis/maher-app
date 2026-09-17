# MAHER — Product Specification v0.2

## 1. Product
MAHER is a two-sided marketplace connecting customers who need a service with verified skilled professionals (الصنايعية).

## 2. Applications
- **MAHER Customer:** creates requests, receives offers, compares professionals, selects a professional, follows the job and reviews it.
- **MAHER Professional:** receives nearby requests, chooses jobs, sends offers, accepts assigned work, marks arrival/completion and tracks earnings.
- **Admin Dashboard:** manages accounts, verification, categories, requests, jobs, commissions, reviews, disputes and support.

## 3. Authentication
Both apps use the same identity model:
1. Phone/email entry.
2. OTP verification.
3. Account details.
4. Role-specific onboarding.

Professional onboarding additionally includes identity verification, skills, service areas and portfolio.

## 4. Service pricing modes
### Hourly — بالساعة
Customer pays an hourly rate. The platform commission is calculated per paid hour. The initial business example discussed is **10 JOD/hour**, with **5 JOD** allocated as the professional's hourly amount and the remainder configurable as platform/service economics. Exact commission must be configurable by admin before launch.

### Daily — يومي
A full-day job uses a daily price. The initial example is **50 JOD/day**. The final price remains configurable per request and professional offer.

### Contract — مقاولة
Customer publishes the job. Professionals submit their own quotations, for example 20, 25, 35 or 40 JOD. Customer compares the offers and accepts one. The accepted quotation becomes the agreed job price.

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
- Only verified professionals should be eligible for jobs requiring verification.
- A customer can accept one offer per request.
- Once an offer is accepted, competing offers become closed.
- Arrival and completion are timestamped status events.
- Hourly jobs need start/end or billable-hour confirmation before final settlement.
- Contract jobs use the accepted quotation as the agreed amount.
- Commission rates and pricing defaults are admin-configurable.

## 12. Technical phases
### Phase A — UX/MVP
Two standalone Flutter APKs with the complete navigation and state flow.

### Phase B — Real connection
Shared backend/API + database + authentication + file storage + push notifications. Both apps read/write the same request, offer and job records.

### Phase C — Production services
Maps/location, real payment provider, identity verification, chat/call, dispute workflow, admin dashboard, analytics, security rules and production monitoring.

## 13. Current repository structure
```text
maher-app/
├── customer_app/       # Customer mobile application
├── professional_app/   # Professional mobile application
├── docs/               # Product and technical specification
├── lib/                # Previous single-app prototype kept for reference
└── .github/workflows/  # Automated APK builds
```

## 14. Visual system
Deep Navy `#111827`, Electric Orange `#F97316`, Off White `#F8FAFC`. Modern, premium, human and trustworthy. Arabic RTL is the default experience.
