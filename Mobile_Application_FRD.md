# Mobile Application Functional Requirements Document (FRD)

## 1. Document Control
- Version: 1.0
- Date: 2026-05-17
- Product: Multi-Organization Member, Asset, and Kuri Management System
- Platforms: Mobile App (Flutter), Admin Panel (Web or Mobile Admin Mode), REST API (Node.js)

## 2. Purpose
This document defines the functional and non-functional requirements for a multi-organization application that manages:
- Organizations
- Members and privilege cards
- Asset issuing/returns
- Kuri (chit fund) lifecycle and accounting
- Notifications and reporting

The goal is a low-cost, scalable system with strict tenant (organization) isolation.

## 3. Scope
### In Scope
- Multi-organization onboarding and management
- Member lifecycle management with digital privilege cards
- Asset assignment and return tracking
- Kuri group setup, collections, winner selection, payouts, and history
- Push notification delivery via Firebase Cloud Messaging (FCM)
- Role-based access for Admin and Member users
- Reporting for admin operations

### Out of Scope (Current Release)
- Payment gateway integrations
- Advanced BI analytics and predictive reporting
- Cross-organization dashboards (except platform super-admin operational metrics)

## 4. Technology Stack
- Frontend (Mobile): Flutter
- Backend: Node.js (REST API)
- Database: PostgreSQL
- Hosting: Railway (API + PostgreSQL)
- Push Notifications: Firebase Cloud Messaging (FCM)

## 5. Key Architecture Principle: Multi-Organization Isolation
### 5.1 Tenant Model
- Each organization is a tenant.
- All business tables must include `organization_id`.
- Every API request must resolve organization context before any read/write operation.

### 5.2 Isolation Rules
- No user may access records with a different `organization_id`.
- Joins and aggregates must always include organization filters.
- Background jobs and reports must execute per organization context.

### 5.3 Enforcement
- Token/session includes org context or user-to-org mapping.
- Middleware validates org context and injects filter constraints.
- Database constraints and indexes include `organization_id` where applicable.

## 6. User Roles
- Platform Super Admin (optional for SaaS operations)
  - Manages organizations and global settings.
- Organization Admin
  - Manages members, assets, kuri groups, collections, payouts, notifications, and reports for own organization only.
- Member
  - Accesses own profile, privilege card, issued assets, kuri dues/history, and receives notifications.

## 7. Functional Requirements

## 7.1 Organization Management
### Description
Create and maintain organizations as isolated tenants.

### Functional Requirements
1. System shall allow creation of a new organization with mandatory fields: name, contact info, status.
2. System shall allow edit/deactivate organization.
3. System shall map admins and members to exactly one organization for current release.
4. System shall block login for inactive organization users.

### Acceptance Criteria
1. Creating an organization assigns a unique organization identifier.
2. Users from Organization A cannot list or fetch Organization B records.
3. Deactivating organization blocks API access for its users.

## 7.2 Member Management
### Description
Organization admins manage members and members can sign in to the mobile app.

### Functional Requirements
1. Admin shall add, edit, and delete (or soft-delete) members.
2. Member profile must include: member ID, name, contact, join date, status, organization.
3. System shall support member login with secure authentication.
4. Member shall view own profile in mobile app.
5. Member shall view assigned assets and kuri summary.

### Acceptance Criteria
1. Admin can create member and assign to own organization only.
2. Deleted members are excluded from active lists but retained for audit if soft-delete is used.
3. Member login returns only self-scoped data.

## 7.3 Privilege Card
### Description
Each member has a digital privilege card.

### Functional Requirements
1. System shall generate one privilege card per active member.
2. Card must display: member ID, member name, organization name, unique code/QR.
3. Member shall access card in app.
4. Admin may regenerate card code if compromised.

### Acceptance Criteria
1. Card generation occurs immediately after member activation or on-demand.
2. QR/unique code resolves to the same member within correct organization context.

## 7.4 Asset Management
### Description
Track asset inventory, issuing, and returns.

### Functional Requirements
1. Admin shall create and maintain asset records.
2. Admin shall issue an asset to a member with issue date and expected return date.
3. Admin shall mark asset as returned with return date and condition notes.
4. System shall maintain asset transaction history.
5. Member shall view currently issued assets and due status.

### Data Tracked
- Asset identifier
- Organization ID
- Assigned member ID
- Issue date
- Due date
- Return date
- Status: `ISSUED` / `RETURNED`
- Optional remarks

### Acceptance Criteria
1. An already issued asset cannot be re-issued until returned.
2. Return operation updates status and closes active assignment.
3. Member can view only own issued assets.

## 7.5 Kuri (Chit Fund) Management
### Description
Manage kuri groups, monthly collections, winners, and payouts.

### Functional Requirements
1. Admin shall create kuri groups with:
   - Group name/code
   - Total members
   - Monthly contribution amount
   - Duration (months)
   - Start date
2. System shall enroll members into kuri groups under same organization.
3. Admin shall record monthly contributions per member.
4. Admin shall select monthly winner based on configured policy.
5. System shall ensure each member receives payout only once per cycle.
6. Admin shall record payout amount/date/reference.
7. Members shall view:
   - Payment status by month
   - Winner history
   - Pending dues

### Business Rules
1. Monthly payment amount is fixed for a given kuri group.
2. Winner uniqueness rule: one payout per member per complete cycle.
3. Full transaction trail is mandatory for audit and reconciliation.

### Acceptance Criteria
1. System rejects winner selection if member already won in same cycle.
2. System shows pending dues accurately month-by-month.
3. Admin can export kuri financial ledger per group.

## 7.6 Notifications
### Description
Push notifications to members using FCM.

### Functional Requirements
1. Admin shall send notification to all members in own organization.
2. Admin shall send notification to selected target audience within own organization.
3. System shall persist notification logs (title, body, audience, timestamp, delivery status).
4. Member app shall receive push notifications when device token is registered.

### Acceptance Criteria
1. Notifications from one organization are never delivered to another organization users.
2. Failed delivery attempts are logged with retry status/error reason.

## 7.7 Admin Panel
### Description
Central operational interface for organization-level administration.

### Functional Requirements
1. Admin panel shall provide modules for organizations, members, assets, kuri, notifications, and reports.
2. Admin panel shall enforce role permissions.
3. Admin panel shall provide search/filter/export for major lists.

### Acceptance Criteria
1. Unauthorized role actions return access denied.
2. Reports display only organization-scoped data.

## 8. Reporting Requirements
System shall provide at minimum:
- Member count (active/inactive)
- Asset issued vs returned
- Overdue assets
- Kuri collection summary by month/group
- Kuri payout history
- Notification delivery summary

Exports: CSV (mandatory), PDF (optional in current release).

## 9. API and Data Requirements
## 9.1 API Standards
- RESTful endpoints with versioning (`/api/v1/...`).
- JSON request/response.
- Standard error format with code/message/details.
- Pagination for list endpoints.

## 9.2 Core Entity Set (Minimum)
- organizations
- users
- members
- privilege_cards
- assets
- asset_transactions
- kuri_groups
- kuri_members
- kuri_collections
- kuri_winners
- kuri_payouts
- notifications
- notification_logs

All applicable tables include:
- `organization_id`
- audit fields (`created_at`, `updated_at`, `created_by`, `updated_by`)

## 9.3 Integrity and Constraints
- Foreign keys enforce organization-consistent relationships.
- Unique constraints (examples):
  - member_id per organization
  - asset_code per organization
  - one winner per month per kuri group

## 10. Security Requirements
1. Authentication required for all protected endpoints.
2. Role-based authorization (Admin/Member/Super Admin where applicable).
3. Organization scoping must be mandatory and server-enforced.
4. Sensitive operations must be audited.
5. Passwords must be hashed using modern standard (for example bcrypt/argon2).
6. Transport security via HTTPS only.

## 11. Non-Functional Requirements
1. Scalability: support at least 1,000 active members initially, with growth path.
2. Performance:
   - P95 read API latency under 500 ms under expected load.
   - P95 write API latency under 800 ms under expected load.
3. Availability target: 99.5% monthly uptime (initial target).
4. Maintainability: modular service design, migration-based schema management.
5. Cost efficiency: optimized for Railway-hosted deployment.

## 12. Audit and Compliance
1. System shall log critical events:
   - member create/update/delete
   - asset issue/return
   - kuri winner and payout actions
   - notification dispatch
2. Audit logs must include actor, action, entity, timestamp, and organization context.

## 13. Assumptions and Dependencies
- Admin panel UI can be delivered as responsive web app or admin mode in Flutter.
- FCM project and credentials are configured per environment.
- Railway environment provides managed PostgreSQL and deployment pipeline.
- Organization-specific legal/financial policies for kuri are externally defined.

## 14. Risks and Mitigations
1. Risk: Cross-tenant data leakage due to missing filters.
   - Mitigation: middleware enforcement + integration tests for tenant boundaries.
2. Risk: Financial inconsistency in kuri records.
   - Mitigation: transactional writes and ledger reconciliation checks.
3. Risk: Notification delivery failures.
   - Mitigation: retry queue and failure logging.

## 15. Future Enhancements
- Multi-organization SaaS self-service onboarding
- Advanced financial and operational analytics
- Payment gateway integration for automated collections
- Multi-language app support

## 16. Release Acceptance (MVP)
MVP is accepted only when:
1. All module acceptance criteria in Sections 7.1 to 7.7 pass.
2. Tenant isolation tests pass for all core endpoints.
3. Kuri financial flow supports end-to-end cycle (group -> collection -> winner -> payout -> reports).
4. Push notifications are successfully delivered in staging and production-like tests.
5. Critical audit logs are available and queryable.
