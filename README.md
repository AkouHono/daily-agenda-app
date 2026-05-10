# Daily Agenda App

An intelligent, feature-rich daily agenda application built with Flutter, offering a beautiful UI, smart scheduling, and timely notifications.

## Features

### 📅 Core Features
- **Daily Agenda Management**: Create, edit, and organize your daily tasks
- **Smart Scheduling**: Intelligent time-based task organization
- **Push Notifications**: Get notified at scheduled times
- **Task Categories**: Organize tasks by category (Work, Personal, Health, etc.)
- **Priority Levels**: Set task importance (High, Medium, Low)

### 🧠 Intelligent Features
- **AI-Powered Suggestions**: Get smart recommendations based on your habits
- **Time Analytics**: View productivity metrics and task completion patterns
- **Smart Reminders**: Adaptive notification timing based on task type
- **Conflict Detection**: Alerts for overlapping tasks
- **Focus Mode**: Distraction-free time blocking for important tasks

### 🎨 Beautiful UI
- **Modern Design**: Clean, intuitive interface with smooth animations
- **Dark/Light Theme**: System theme support
- **Calendar Integration**: Visual timeline of your schedule
- **Customizable Colors**: Per-category color coding
- **Smooth Transitions**: Animated page navigation

### 📊 Analytics & Insights
- **Daily Statistics**: Task completion rates
- **Weekly Reports**: Productivity trends
- **Category Analytics**: Time spent per category
- **Streak Tracking**: Consistency monitoring

## Getting Started

### Prerequisites
- Flutter 3.27+
- Dart 3.0+
- Node.js 18+ (for backend)

### Installation

1. Clone the repository:
```bash
git clone https://github.com/AkouHono/daily-agenda-app.git
cd daily-agenda-app
```

2. Get Flutter dependencies:
```bash
flutter pub get
```

3. Run the app locally:
```bash
flutter run -d chrome   # Web
flutter run             # Mobile
```

4. Run the backend locally:
```bash
cd server
npm install
node index.js
```

## Deployment

This project deploys automatically to **Vercel** via GitHub Actions on every push to `main`.

- **Frontend**: Flutter web (static) served by Vercel
- **Backend**: Node.js/Express serverless function on Vercel
- **Database**: SQLite via `/tmp` on Vercel (ephemeral; use Supabase/PlanetScale for persistence)

### Required GitHub Secrets
| Secret | Description |
|--------|-------------|
| `VERCEL_TOKEN` | Your Vercel personal access token |
| `VERCEL_ORG_ID` | Found in `.vercel/project.json` |
| `VERCEL_PROJECT_ID` | Found in `.vercel/project.json` |

## Configuration

### Environment Variables
Set these in your Vercel dashboard:
- `JWT_SECRET` — Secret key for signing JWT tokens

## API & Services

### Auth Endpoints
```
POST /register   { username, password }
POST /login      { username, password } → { token }
```

### Task Endpoints (require Authorization: Bearer <token>)
```
GET    /tasks
POST   /tasks
DELETE /tasks/:id
```

## Data Storage

Uses **Hive** for local Flutter storage and **SQLite** for the backend:
- Tasks persisted locally and synced via API
- Category preferences
- Analytics data
- User settings

## Performance

- Lazy loading of tasks
- Efficient state management with Provider
- Smooth 60 FPS animations

## Future Enhancements

- [ ] Migrate backend DB to Supabase/PostgreSQL for persistent cloud storage
- [ ] Cloud synchronization
- [ ] Recurring tasks with smart patterns
- [ ] Voice command integration
- [ ] Wearable app support

## License

MIT License - see LICENSE file for details

---

**Built with ❤️ using Flutter**
