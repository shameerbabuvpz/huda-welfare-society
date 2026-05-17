# Ayalkoottam

Multi-organization member, asset, and kuri (chit fund) management system.

## Architecture

```
ayalkoottam/
├── backend/          # Node.js REST API
│   ├── src/
│   │   ├── config/       # Database config
│   │   ├── middleware/   # Auth, org scope, validation, error handling
│   │   ├── migrations/   # PostgreSQL schema
│   │   ├── seeds/        # Initial data
│   │   ├── services/     # Business logic
│   │   ├── controllers/  # Request/response handling
│   │   ├── routes/       # API endpoints
│   │   └── utils/        # Helpers
│   └── package.json
├── mobile/           # Flutter mobile app
│   ├── lib/
│   │   ├── config/       # API config, theme, routes
│   │   ├── models/       # Data models
│   │   ├── services/     # API communication
│   │   ├── providers/    # State management (Provider)
│   │   ├── screens/      # UI screens (admin + member)
│   │   └── main.dart     # App entry point
│   └── pubspec.yaml
└── Mobile_Application_FRD.md
```

## Tech Stack

- **Backend**: Node.js + Express.js
- **Database**: PostgreSQL (via Knex.js)
- **Mobile**: Flutter (Provider for state management)
- **Notifications**: Firebase Cloud Messaging (FCM)
- **Hosting**: Railway (recommended)

---

## Backend Setup

### Prerequisites
- Node.js 18+
- PostgreSQL 14+

### Steps

```bash
cd backend

# 1. Install dependencies
npm install

# 2. Configure environment
cp .env.example .env
# Edit .env with your database URL and JWT secret

# 3. Run database migrations
npm run migrate

# 4. Seed super admin
npm run seed

# 5. Start server
npm run dev
```

### API Base URL
```
http://localhost:3000/api/v1
```

### Default Super Admin
```
Email: admin@ayalkoottam.com
Password: changeme123
```

---

## Flutter Mobile Setup

### Prerequisites
- Flutter SDK 3.2+
- Dart SDK

### Steps

```bash
cd mobile

# 1. Create Flutter platform folders (first time only)
flutter create --project-name ayalkoottam .

# 2. Install dependencies
flutter pub get

# 3. Update API URL
# Edit lib/config/api_config.dart with your backend URL

# 4. Run the app
flutter run
```

### Firebase Setup (for push notifications)
1. Create a Firebase project
2. Add Android/iOS apps in Firebase console
3. Download `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)
4. Place in respective platform folders
5. Set `FIREBASE_SERVICE_ACCOUNT` path in backend `.env`

---

## API Endpoints

### Auth
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/auth/login` | Login |
| GET | `/auth/me` | Current user |
| PUT | `/auth/fcm-token` | Update FCM token |
| PUT | `/auth/change-password` | Change password |

### Organizations (Super Admin)
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/organizations` | Create org |
| GET | `/organizations` | List orgs |
| GET | `/organizations/:id` | Get org |
| PUT | `/organizations/:id` | Update org |
| PUT | `/organizations/:id/deactivate` | Deactivate org |

### Members (Admin)
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/members` | Add member |
| GET | `/members` | List members |
| GET | `/members/:id` | Get member |
| PUT | `/members/:id` | Update member |
| DELETE | `/members/:id` | Soft-delete member |
| GET | `/members/profile` | Member self profile |

### Privilege Cards
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/privilege-cards/:memberId/generate` | Generate card (admin) |
| GET | `/privilege-cards/:memberId` | Get card (admin) |
| GET | `/privilege-cards/my-card` | My card (member) |
| PUT | `/privilege-cards/:cardId/revoke` | Revoke card (admin) |

### Assets
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/assets` | Create asset |
| GET | `/assets` | List assets |
| GET | `/assets/:id` | Get asset |
| PUT | `/assets/:id` | Update asset |
| POST | `/assets/:id/issue` | Issue to member |
| POST | `/assets/:id/return` | Mark returned |
| GET | `/assets/:id/history` | Transaction history |
| GET | `/assets/my-assets` | My issued assets (member) |

### Kuri (Chit Fund)
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/kuri` | Create group |
| GET | `/kuri` | List groups |
| GET | `/kuri/:id` | Group detail with members & winners |
| PUT | `/kuri/:id` | Update group |
| POST | `/kuri/:id/members` | Add member to group |
| DELETE | `/kuri/:id/members/:memberId` | Remove member |
| POST | `/kuri/:id/collections` | Record payment |
| GET | `/kuri/:id/collections` | Get collections |
| POST | `/kuri/:id/winners` | Select winner |
| GET | `/kuri/:id/winners` | Winner history |
| POST | `/kuri/:id/payouts` | Record payout |
| GET | `/kuri/my-kuri` | My kuri status (member) |

### Notifications
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/notifications` | Send notification |
| GET | `/notifications` | List notifications |
| GET | `/notifications/:id/logs` | Delivery logs |
| GET | `/notifications/my-notifications` | My notifications (member) |

### Reports (Admin)
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/reports/members` | Member summary |
| GET | `/reports/assets` | Asset summary |
| GET | `/reports/kuri/:groupId/collections` | Kuri collection summary |
| GET | `/reports/kuri/:groupId/payouts` | Kuri payout history |
| GET | `/reports/notifications` | Notification summary |

---

## Deployment to Railway

### Backend
1. Push `backend/` to a Git repository
2. Create a Railway project
3. Add PostgreSQL plugin
4. Set environment variables (from `.env.example`)
5. Deploy from Git

### Database
- Railway provides managed PostgreSQL
- Run `npm run migrate` and `npm run seed` after deployment

---

## Security

- JWT authentication on all protected routes
- Organization-scoped middleware enforces tenant isolation
- Passwords hashed with bcrypt (12 rounds)
- Input validation via express-validator
- Helmet.js for HTTP security headers
- CORS enabled

---

## License

Private / Internal Use
