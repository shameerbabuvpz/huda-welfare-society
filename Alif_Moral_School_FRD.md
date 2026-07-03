# Alif Online Moral School - Functional Requirements Document (FRD)

**Version:** 1.0  
**Date:** June 17, 2026  
**Project Name:** Alif Online Moral School Activity Tracking System

---

## 1. Executive Summary

Alif Online Moral School application is a comprehensive student activity tracking system designed to monitor and encourage daily Islamic practices among students. The system allows students to self-report their daily activities (prayers, Quran reading, etc.), earn marks/points, and track their progress over time. Teachers can monitor student progress, and administrators can manage the entire system including users, activities, and reports.

---

## 2. Project Overview

### 2.1 Purpose
To digitize the traditional "Ihthisab Chart" (Practical Record) system, enabling:
- Daily activity tracking by students
- Progress monitoring by teachers and parents
- Gamification through points, badges, and leaderboards
- Weekly and monthly statistics generation

### 2.2 Target Users
1. **Students** - Self-report daily activities
2. **Parents** - Monitor child's progress
3. **Teachers** - Track student performance, provide guidance
4. **Administrators** - Manage system, users, activities, and reports

### 2.3 Technology Stack
| Component | Technology |
|-----------|------------|
| Mobile App | Flutter (iOS & Android) |
| Admin Panel | Flutter Web |
| Backend | Node.js (Express.js) |
| Database | Supabase (PostgreSQL) |
| Authentication | Mobile OTP via Supabase Auth |
| Push Notifications | Firebase Cloud Messaging |
| File Storage | Supabase Storage |

---

## 3. User Roles & Authentication

### 3.1 User Types

#### 3.1.1 Student/Parent Account
- **Login Method:** Mobile OTP (Phone number based)
- **Access:** Mobile app only
- **Parent Link:** One phone number can be linked to multiple students (for parents with multiple children)

#### 3.1.2 Teacher Account
- **Login Method:** Mobile OTP
- **Access:** Mobile app
- **Permissions:** View assigned batches, monitor student progress, add remarks

#### 3.1.3 Administrator Account
- **Login Method:** Mobile OTP + Optional PIN/Password
- **Access:** Flutter Web + Mobile app
- **Permissions:** Full system access

### 3.2 Authentication Flow

```
┌─────────────────────────────────────────────────────────┐
│                    LOGIN FLOW                           │
├─────────────────────────────────────────────────────────┤
│  1. User enters phone number                            │
│  2. System sends OTP via SMS                            │
│  3. User enters OTP                                     │
│  4. System validates OTP                                │
│  5. If new user → Show registration form                │
│  6. If existing user → Redirect to dashboard            │
│  7. If multiple students linked → Show student picker   │
└─────────────────────────────────────────────────────────┘
```

---

## 4. Feature Specifications

### 4.1 Admin Module (Flutter Web + Mobile)

#### 4.1.1 Dashboard
- Total students count
- Active students today
- Total activities completed today
- Top performers (leaderboard preview)
- Quick stats (weekly/monthly comparison)

#### 4.1.2 Student Management

**Add Student Form Fields:**
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| Student Name | Text | Yes | Full name in English |
| Student Name (Malayalam) | Text | No | Name in Malayalam |
| Mobile Number | Phone | Yes | Primary contact (Parent's number) |
| Father's Name | Text | Yes | Father's full name |
| Mother's Name | Text | Yes | Mother's full name |
| Date of Birth | Date | Yes | For age calculation |
| Gender | Dropdown | Yes | Male/Female |
| Batch | Dropdown | Yes | Dynamic list from batch management |
| Class | Dropdown | Yes | Dynamic list from class management |
| Address | Text | No | Full address |
| Profile Photo | Image | No | Student's photo |
| Enrollment Date | Date | Auto | System generated |
| Status | Toggle | Auto | Active/Inactive |

**Student List View:**
- Search by name, phone, batch
- Filter by batch, class, status
- Bulk actions (activate, deactivate, move batch)
- Export to Excel/PDF

#### 4.1.3 Teacher Management

**Add Teacher Form Fields:**
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| Teacher Name | Text | Yes | Full name |
| Mobile Number | Phone | Yes | Primary contact |
| Email | Email | No | Optional email |
| Subjects | Multi-select | Yes | Assigned subjects |
| Batches | Multi-select | Yes | Assigned batches |
| Qualification | Text | No | Educational qualification |
| Profile Photo | Image | No | Teacher's photo |
| Status | Toggle | Auto | Active/Inactive |

#### 4.1.4 Batch & Class Management

**Batch:**
- Create/Edit/Delete batches
- Assign teachers to batches
- Batch timing (if applicable)
- Batch capacity

**Class:**
- Create/Edit/Delete classes
- Link classes to batches
- Class level (beginner, intermediate, advanced)

#### 4.1.5 Activity Category Management (Ihthisab Configuration)

**Category Structure:**
```
Category (Parent)
├── Sub-Category 1
├── Sub-Category 2
└── Sub-Category 3
```

**Category Fields:**
| Field | Type | Description |
|-------|------|-------------|
| Category Name | Text | e.g., "നമസ്കാരം" (Prayer) |
| Category Name (English) | Text | e.g., "Prayer" |
| Icon | Icon Picker | Display icon |
| Order | Number | Display order |
| Status | Toggle | Active/Inactive |

**Sub-Category (Activity) Fields:**
| Field | Type | Description |
|-------|------|-------------|
| Activity Name | Text | e.g., "സുബ്ഹി" (Subhi) |
| Activity Name (English) | Text | e.g., "Fajr Prayer" |
| Parent Category | Dropdown | Link to category |
| Order | Number | Display order |
| Status | Toggle | Active/Inactive |

#### 4.1.6 Rating/Scoring Configuration

**Rating Options (Per Activity):**
| Rating | Malayalam | Marks | Color |
|--------|-----------|-------|-------|
| Excellent | മികച്ചത് | Configurable (e.g., 10) | Green |
| Satisfactory | തൃപ്തികരം | Configurable (e.g., 5) | Yellow |
| Needs Improvement | തൃപ്തികരമല്ല | Configurable (e.g., 2) | Red |
| Not Done | ചെയ്തില്ല | 0 | Gray |

**Special Scoring Rules (Example from PDF):**
```
ജമാഅത്ത് നമസ്കാരം (Congregation Prayer):
├── ജമാഅത്ത് നമസ്കാരം = 10 മാർക്ക്
├── സമയത്ത്, ഒറ്റയ്ക്ക് നിർവ്വഹിച്ച നമസ്കാരം = 5 മാർക്ക്
└── വൈകി, ഒറ്റയ്ക്ക് നമസ്കരിച്ചത് = 2 മാർക്ക്

ഖുർആൻ പാരായണം (Quran Recitation):
├── 10 പേജ് = 10 മാർക്ക്
├── 5 പേജ് = 5 മാർക്ക്
└── 2 പേജ് = 2 മാർക്ക്
```

#### 4.1.7 Default Activity Categories (From PDF)

**1. നമസ്കാരം (Prayer) - ഇബാദത്തുകൾ:**
| Sub-Activity | Malayalam |
|--------------|-----------|
| Subhi | സുബ്ഹി |
| Zuhr | ളുഹ്ർ |
| Asr | അസർ |
| Maghrib | മഗ്‌രിബ് |
| Isha | ഇശാഅ് |

**2. സുന്നത്ത് നമസ്കാരങ്ങൾ (Sunnah Prayers):**
| Sub-Activity | Malayalam |
|--------------|-----------|
| Before Subhi | സുബ്ഹിക്ക് മുമ്പ് |
| Before Zuhr | ളുഹ്റിന് മുമ്പ് |
| After Zuhr | ളുഹ്റിന് ശേഷം |
| After Maghrib | മഗ്‌രിബിന് ശേഷം |
| After Isha | ഇശാഇന് ശേഷം |

**3. ദിനചര്യ (Daily Routine):**
| Sub-Activity | Malayalam |
|--------------|-----------|
| Quran Recitation | ഖുർആൻ പാരായണം |
| Quran Study | ഖുർആൻ അർത്ഥ പഠനം |
| Hifz (Memorization) | ഹിഫ്സ് |
| Dhikr & Duas | ദിക്ർ, ദുആകൾ |
| Discipline & Cleanliness | ചിട്ടയും വൃത്തിയും |

#### 4.1.8 Reports & Analytics

**Report Types:**
1. **Daily Report** - Activities completed per day
2. **Weekly Report** - Week-wise summary
3. **Monthly Report** - Month-wise detailed report
4. **Student Progress Report** - Individual student tracking
5. **Batch Comparison Report** - Compare batch performances
6. **Teacher Report** - Batch-wise student progress under each teacher

**Export Options:**
- PDF (Malayalam + English)
- Excel
- Print-friendly view

#### 4.1.9 Notification Management
- Send push notifications to all students
- Send to specific batches
- Schedule notifications
- Reminder notifications (configurable time)

#### 4.1.10 Badge & Achievement Management

**Create Badge:**
| Field | Description |
|-------|-------------|
| Badge Name | e.g., "Prayer Champion" |
| Badge Icon | Upload image |
| Criteria | Auto-award rules (e.g., 30 days streak) |
| Points | Bonus points on achievement |

**Default Badges:**
- 🏆 7-Day Streak
- 🌟 30-Day Streak
- 📖 Quran Master (Complete Hifz target)
- 🙏 Perfect Prayer Week
- 👑 Monthly Top Performer

---

### 4.2 Student/Parent Module (Mobile App)

#### 4.2.1 Home Dashboard
- Today's activities status (completed/pending)
- Current streak count
- Total points/marks this week
- Quick actions to mark activities
- Motivational quotes/hadith

#### 4.2.2 Daily Activity Marking (Ihthisab)

**UI Flow:**
```
┌─────────────────────────────────────────┐
│  📅 Today: June 17, 2026                │
├─────────────────────────────────────────┤
│  📿 നമസ്കാരം (Prayer)                   │
│  ┌─────────────────────────────────────┐ │
│  │ സുബ്ഹി (Fajr)                       │ │
│  │ ○ മികച്ചത്  ○ തൃപ്തികരം  ○ ചെയ്തില്ല │ │
│  └─────────────────────────────────────┘ │
│  ┌─────────────────────────────────────┐ │
│  │ ളുഹ്ർ (Zuhr)                        │ │
│  │ ● മികച്ചത്  ○ തൃപ്തികരം  ○ ചെയ്തില്ല │ │
│  └─────────────────────────────────────┘ │
│  ... more activities ...                 │
├─────────────────────────────────────────┤
│  📚 ദിനചര്യ (Daily Routine)             │
│  ┌─────────────────────────────────────┐ │
│  │ ഖുർആൻ പാരായണം                       │ │
│  │ Pages read: [___] (input number)    │ │
│  └─────────────────────────────────────┘ │
└─────────────────────────────────────────┘
```

**Features:**
- Date picker (can mark past days within limit)
- Auto-save on selection
- Visual progress indicator
- Parent signature/approval checkbox (optional)
- Note/comment field (optional)

#### 4.2.3 Progress & Statistics

**Weekly View:**
- Calendar heatmap showing activity levels
- Week's total points
- Comparison with previous week
- Activities completion percentage

**Monthly View:**
- Full month calendar with daily scores
- Category-wise breakdown
- Charts and graphs
- Month ranking in batch

#### 4.2.4 Leaderboard

**Leaderboard Types:**
- Daily Top 10
- Weekly Top 10
- Monthly Top 10
- All-time Top 10

**Display:**
- Rank
- Student name (with privacy option for initials only)
- Points
- Batch name
- Trend (up/down from previous period)

#### 4.2.5 Badges & Achievements
- View earned badges
- Progress towards next badge
- Badge history
- Share achievements (optional)

#### 4.2.6 Profile
- View/Edit profile (limited fields)
- View batch and class info
- Change language preference
- Notification settings
- Privacy settings

#### 4.2.7 Parent Dashboard (Switch Mode)

**Parent Features:**
- Switch between multiple children
- View each child's progress
- Receive notifications
- Approve daily submissions (if enabled)
- View teacher remarks

---

### 4.3 Teacher Module (Mobile App)

#### 4.3.1 Dashboard
- Assigned batches overview
- Today's student activity status
- Students needing attention (low performers)
- Quick stats

#### 4.3.2 Student Monitoring
- View students by batch
- Individual student progress
- Weekly/Monthly reports per student
- Add remarks/feedback

#### 4.3.3 Batch Analytics
- Batch-wise completion rates
- Top performers in batch
- Areas needing improvement
- Comparative analysis

#### 4.3.4 Notifications
- Send batch-wise reminders
- Acknowledge student achievements
- Send motivational messages

---

## 5. Database Schema (Supabase/PostgreSQL)

### 5.1 Core Tables

```sql
-- Users table (handled by Supabase Auth)
-- profiles table for additional user data

CREATE TABLE profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id),
    phone TEXT UNIQUE NOT NULL,
    full_name TEXT NOT NULL,
    full_name_ml TEXT, -- Malayalam name
    role TEXT CHECK (role IN ('student', 'parent', 'teacher', 'admin')),
    profile_photo TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Students table
CREATE TABLE students (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    profile_id UUID REFERENCES profiles(id),
    parent_phone TEXT NOT NULL,
    father_name TEXT,
    mother_name TEXT,
    date_of_birth DATE,
    gender TEXT CHECK (gender IN ('male', 'female')),
    batch_id UUID REFERENCES batches(id),
    class_id UUID REFERENCES classes(id),
    address TEXT,
    enrollment_date DATE DEFAULT CURRENT_DATE,
    status TEXT DEFAULT 'active' CHECK (status IN ('active', 'inactive')),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Teachers table
CREATE TABLE teachers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    profile_id UUID REFERENCES profiles(id),
    email TEXT,
    qualification TEXT,
    status TEXT DEFAULT 'active' CHECK (status IN ('active', 'inactive')),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Batches table
CREATE TABLE batches (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    name_ml TEXT,
    description TEXT,
    capacity INTEGER,
    timing TEXT,
    status TEXT DEFAULT 'active' CHECK (status IN ('active', 'inactive')),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Classes table
CREATE TABLE classes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    name_ml TEXT,
    level TEXT, -- beginner, intermediate, advanced
    batch_id UUID REFERENCES batches(id),
    status TEXT DEFAULT 'active',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Teacher-Batch assignment
CREATE TABLE teacher_batches (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    teacher_id UUID REFERENCES teachers(id),
    batch_id UUID REFERENCES batches(id),
    UNIQUE(teacher_id, batch_id)
);

-- Activity Categories
CREATE TABLE activity_categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    name_ml TEXT,
    icon TEXT,
    display_order INTEGER DEFAULT 0,
    status TEXT DEFAULT 'active',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Activities (Sub-categories)
CREATE TABLE activities (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    category_id UUID REFERENCES activity_categories(id),
    name TEXT NOT NULL,
    name_ml TEXT,
    display_order INTEGER DEFAULT 0,
    has_quantity BOOLEAN DEFAULT FALSE, -- for things like Quran pages
    status TEXT DEFAULT 'active',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Rating options per activity
CREATE TABLE activity_ratings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    activity_id UUID REFERENCES activities(id),
    rating_name TEXT NOT NULL, -- excellent, satisfactory, needs_improvement
    rating_name_ml TEXT,
    marks INTEGER NOT NULL,
    color TEXT, -- hex color code
    display_order INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Daily activity logs
CREATE TABLE activity_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id UUID REFERENCES students(id),
    activity_id UUID REFERENCES activities(id),
    rating_id UUID REFERENCES activity_ratings(id),
    log_date DATE NOT NULL,
    quantity INTEGER, -- for activities with quantity (Quran pages)
    marks_earned INTEGER NOT NULL,
    parent_approved BOOLEAN DEFAULT FALSE,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(student_id, activity_id, log_date)
);

-- Badges
CREATE TABLE badges (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    name_ml TEXT,
    description TEXT,
    icon TEXT,
    criteria JSONB, -- {"type": "streak", "days": 7}
    bonus_points INTEGER DEFAULT 0,
    status TEXT DEFAULT 'active',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Student badges
CREATE TABLE student_badges (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id UUID REFERENCES students(id),
    badge_id UUID REFERENCES badges(id),
    earned_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(student_id, badge_id)
);

-- Notifications
CREATE TABLE notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    body TEXT,
    target_type TEXT CHECK (target_type IN ('all', 'batch', 'class', 'student')),
    target_id UUID, -- batch_id, class_id, or student_id
    scheduled_at TIMESTAMPTZ,
    sent_at TIMESTAMPTZ,
    created_by UUID REFERENCES profiles(id),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Parent-Student relationship (for parents with multiple children)
CREATE TABLE parent_students (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    parent_profile_id UUID REFERENCES profiles(id),
    student_id UUID REFERENCES students(id),
    relationship TEXT DEFAULT 'parent',
    UNIQUE(parent_profile_id, student_id)
);
```

### 5.2 Views for Reports

```sql
-- Daily summary view
CREATE VIEW daily_student_summary AS
SELECT 
    s.id AS student_id,
    al.log_date,
    SUM(al.marks_earned) AS total_marks,
    COUNT(al.id) AS activities_completed,
    s.batch_id
FROM students s
LEFT JOIN activity_logs al ON s.id = al.student_id
GROUP BY s.id, al.log_date, s.batch_id;

-- Weekly leaderboard view
CREATE VIEW weekly_leaderboard AS
SELECT 
    s.id AS student_id,
    p.full_name,
    b.name AS batch_name,
    SUM(al.marks_earned) AS total_marks,
    RANK() OVER (ORDER BY SUM(al.marks_earned) DESC) AS rank
FROM students s
JOIN profiles p ON s.profile_id = p.id
JOIN batches b ON s.batch_id = b.id
LEFT JOIN activity_logs al ON s.id = al.student_id
    AND al.log_date >= date_trunc('week', CURRENT_DATE)
GROUP BY s.id, p.full_name, b.name;
```

---

## 6. API Endpoints

### 6.1 Authentication
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/auth/send-otp` | Send OTP to phone number |
| POST | `/auth/verify-otp` | Verify OTP and login |
| POST | `/auth/logout` | Logout user |
| GET | `/auth/me` | Get current user profile |

### 6.2 Admin APIs
| Method | Endpoint | Description |
|--------|----------|-------------|
| **Students** |
| GET | `/admin/students` | List all students |
| POST | `/admin/students` | Create student |
| GET | `/admin/students/:id` | Get student details |
| PUT | `/admin/students/:id` | Update student |
| DELETE | `/admin/students/:id` | Delete student |
| **Teachers** |
| GET | `/admin/teachers` | List all teachers |
| POST | `/admin/teachers` | Create teacher |
| PUT | `/admin/teachers/:id` | Update teacher |
| DELETE | `/admin/teachers/:id` | Delete teacher |
| **Batches & Classes** |
| GET | `/admin/batches` | List batches |
| POST | `/admin/batches` | Create batch |
| PUT | `/admin/batches/:id` | Update batch |
| DELETE | `/admin/batches/:id` | Delete batch |
| GET | `/admin/classes` | List classes |
| POST | `/admin/classes` | Create class |
| **Activities** |
| GET | `/admin/categories` | List activity categories |
| POST | `/admin/categories` | Create category |
| PUT | `/admin/categories/:id` | Update category |
| GET | `/admin/activities` | List activities |
| POST | `/admin/activities` | Create activity |
| PUT | `/admin/activities/:id` | Update activity |
| **Ratings** |
| GET | `/admin/ratings/:activityId` | Get ratings for activity |
| POST | `/admin/ratings` | Create rating |
| PUT | `/admin/ratings/:id` | Update rating |
| **Badges** |
| GET | `/admin/badges` | List badges |
| POST | `/admin/badges` | Create badge |
| PUT | `/admin/badges/:id` | Update badge |
| **Reports** |
| GET | `/admin/reports/daily` | Daily report |
| GET | `/admin/reports/weekly` | Weekly report |
| GET | `/admin/reports/monthly` | Monthly report |
| GET | `/admin/reports/student/:id` | Student report |

### 6.3 Student APIs
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/student/activities` | Get today's activities |
| POST | `/student/activities/log` | Log activity |
| GET | `/student/progress/daily` | Daily progress |
| GET | `/student/progress/weekly` | Weekly progress |
| GET | `/student/progress/monthly` | Monthly progress |
| GET | `/student/leaderboard` | Get leaderboard |
| GET | `/student/badges` | Get earned badges |
| GET | `/student/profile` | Get profile |
| PUT | `/student/profile` | Update profile |

### 6.4 Teacher APIs
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/teacher/batches` | Get assigned batches |
| GET | `/teacher/students` | Get students in assigned batches |
| GET | `/teacher/student/:id/progress` | Get student progress |
| POST | `/teacher/student/:id/remark` | Add remark |
| GET | `/teacher/batch/:id/analytics` | Batch analytics |

---

## 7. Push Notifications

### 7.1 Notification Types

| Type | Trigger | Target | Message Example |
|------|---------|--------|-----------------|
| Daily Reminder | Scheduled (e.g., 8 PM) | All students | "Don't forget to log today's activities!" |
| Streak Alert | Missed yesterday | Student | "Your 7-day streak is at risk! Log today." |
| Achievement | Badge earned | Student | "🏆 Congratulations! You earned Prayer Champion badge!" |
| Weekly Report | Every Sunday | Parents | "Your child's weekly report is ready." |
| Admin Announcement | Manual | All/Batch | Custom message |
| Teacher Message | Manual | Batch/Student | Custom message |

### 7.2 Notification Settings (User Configurable)
- Enable/Disable notifications
- Reminder time preference
- Weekly report notification
- Achievement notifications

---

## 8. UI/UX Guidelines

### 8.1 Color Scheme
| Purpose | Color | Hex |
|---------|-------|-----|
| Primary | Green | #2E7D32 |
| Secondary | Gold | #FFA000 |
| Excellent | Green | #4CAF50 |
| Satisfactory | Yellow | #FFC107 |
| Needs Improvement | Orange | #FF9800 |
| Not Done | Gray | #9E9E9E |
| Background | Light Green | #E8F5E9 |

### 8.2 Typography
- Primary Font: Support for Malayalam script
- English Font: Poppins/Roboto
- Malayalam Font: Manjari/Noto Sans Malayalam

### 8.3 Design Principles
- Clean, minimal interface
- Large touch targets (mobile-first)
- Clear visual feedback
- Islamic/Moral aesthetic elements
- Bilingual support (Malayalam + English)

---

## 9. Security Requirements

### 9.1 Authentication
- OTP-based authentication (Supabase Auth)
- Session management with JWT
- Auto-logout after inactivity

### 9.2 Authorization
- Role-based access control (RBAC)
- Row-level security in Supabase
- API endpoint protection

### 9.3 Data Protection
- Data encryption at rest (Supabase)
- HTTPS for all communications
- Input validation and sanitization
- Student data privacy compliance

---

## 10. Performance Requirements

| Metric | Requirement |
|--------|-------------|
| API Response Time | < 200ms for most endpoints |
| App Launch Time | < 3 seconds |
| Offline Support | Cache last 7 days data |
| Concurrent Users | Support 1000+ concurrent users |
| Database Size | Scale to 10,000+ students |

---

## 11. Localization

### 11.1 Supported Languages
- Malayalam (Primary)
- English
- Arabic (Future consideration)

### 11.2 Localized Elements
- UI text
- Activity names
- Notifications
- Reports

---

## 12. Future Enhancements (Phase 2)

1. **AI-powered insights** - Personalized recommendations
2. **Voice input** - Log activities via voice
3. **Group challenges** - Batch vs batch competitions
4. **Parent teacher communication** - In-app messaging
5. **Attendance tracking** - Class attendance
6. **Live classes integration** - Video class links
7. **Exam/Quiz module** - Online assessments
8. **Fee management** - Payment tracking

---

## 13. Project Timeline (Estimated)

| Phase | Duration | Deliverables |
|-------|----------|--------------|
| Phase 1: Setup | 1 week | Database, Auth, Basic APIs |
| Phase 2: Admin Panel | 2 weeks | Web admin panel |
| Phase 3: Student App | 2 weeks | Core student features |
| Phase 4: Teacher Module | 1 week | Teacher features |
| Phase 5: Advanced Features | 2 weeks | Badges, Leaderboard, Reports |
| Phase 6: Testing & Launch | 1 week | QA, Bug fixes, Deployment |
| **Total** | **9 weeks** | Complete MVP |

---

## 14. Appendix

### 14.1 Sample Ihthisab Chart Structure (From PDF)

**Header:**
- ALIF ONLINE MORAL SCHOOL
- PRACTICAL RECORD / IHTHISAB CHART
- MONTH: [Month Name]

**Rating Legend:**
- മികച്ചത് (Excellent) = 10 മാർക്ക്
- തൃപ്തികരം (Satisfactory) = 5 മാർക്ക്
- തൃപ്തികരമല്ല (Needs Improvement) = 2 മാർക്ക്

**Special Rules:**
- ജമാഅത്ത് നമസ്കാരം = 10 മാർക്ക്
- സമയത്ത്, ഒറ്റയ്ക്ക് നിർവ്വഹിച്ച നമസ്കാരം = 5 മാർക്ക്
- വൈകി, ഒറ്റയ്ക്ക് നമസ്കരിച്ചത് = 2 മാർക്ക്
- ഖുർആൻ പാരായണം 10 പേജ് = 10 മാർക്ക്
- ഖുർആൻ പാരായണം 5 പേജ് = 5 മാർക്ക്
- ഖുർആൻ പാരായണം 2 പേജ് = 2 മാർക്ക്

**Note:** 
NB: വിദ്യാർത്ഥികളും രക്ഷിതാക്കളും ഒരുമിച്ചിരുന്നാണ് ഫോം Fill ചെയ്യേണ്ടത്.
(Students and parents should fill the form together)

---

**Document Prepared By:** GitHub Copilot  
**Last Updated:** June 17, 2026  
**Status:** Draft v1.0
