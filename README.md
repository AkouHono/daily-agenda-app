<<<<<<< HEAD
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

```
## Getting Started

### Prerequisites
- Flutter 3.0+
- Dart 3.0+

### Installation

1. Clone the repository:
```bash
git clone https://github.com/AkouHono/daily-agenda-app.git
cd daily-agenda-app
```

2. Get dependencies:
```bash
flutter pub get
```

3. Generate Hive adapters:
```bash
flutter pub run build_runner build
```

4. Run the app:
```bash
flutter run
```

## Configuration

### Notification Settings
Update notification settings in `lib/config/constants.dart`:
- Default reminder times
- Sound settings
- Quiet hours

### Theme Customization
Modify `lib/config/theme/app_theme.dart` for:
- Color schemes
- Typography
- Component styling

## API & Services

### Task Service
```dart
taskProvider.addTask(task);
taskProvider.updateTask(task);
taskProvider.deleteTask(taskId);
taskProvider.getTodaysTasks();
```

### Notification Service
```dart
notificationService.scheduleNotification(task);
notificationService.cancelNotification(taskId);
```

### Analytics Service
```dart
analyticsService.getDailyStats();
analyticsService.getWeeklyStats();
analyticsService.getCategoryStats();
```

## UI Components

- **Task Cards**: Swipeable, animated task display
- **Calendar View**: Monthly overview with task indicators
- **Charts**: Bar and pie charts for analytics
- **Custom Input**: Beautiful task creation form
- **Bottom Sheet**: Quick task addition
- **Floating Action Button**: Primary action for new tasks

## Data Storage

Uses **Hive** for efficient local storage:
- Tasks persisted locally
- Category preferences
- Analytics data
- User settings

## Notifications

Integrated with **Flutter Local Notifications**:
- Scheduled notifications
- Time-zone aware
- Category-specific sounds
- Smart retry logic

## Performance

- Lazy loading of tasks
- Efficient state management with Provider
- Optimized database queries
- Image caching
- Smooth 60 FPS animations

## Future Enhancements

- [ ] Cloud synchronization
- [ ] Collaborative task sharing
- [ ] Voice command integration
- [ ] Recurring tasks with smart patterns
- [ ] Integration with calendar apps
- [ ] AI-powered time estimation
- [ ] Team collaboration features
- [ ] Wearable app support

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## License

MIT License - see LICENSE file for details

## Support

For support, email support@dailytech.com or create an issue on GitHub.

---

**Built with ❤️ using Flutter**
=======
# daily_agenda

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
>>>>>>> 55b24b6 (daily app)
