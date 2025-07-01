# YouTube Shorts Creator - Flutter Frontend

A Flutter application for creating YouTube Shorts with AI-powered content generation.

## 🚀 Features

- **Video Upload**: Upload long-form videos (MP4, MOV, AVI)
- **Transcript Management**: Add transcripts or scripts for better AI processing
- **AI-Powered Short Creation**: Automatically generate engaging short-form content
- **Job Management**: Track the progress of your video processing jobs
- **YouTube Integration**: Direct upload to YouTube with customizable settings
- **Modern UI**: Beautiful, responsive design with Material Design 3

## 📱 Screenshots

*Screenshots will be added as the app development progresses*

## 🏗️ Architecture

This project follows **Clean Architecture** principles with the following structure:

```
lib/
├── core/                    # Core utilities and shared code
│   ├── constants/          # App-wide constants
│   ├── errors/             # Error handling and exceptions
│   ├── network/            # Network layer and API client
│   ├── utils/              # Utility functions
│   └── theme/              # App theming and styling
├── features/               # Feature-based modules
│   ├── upload/             # File upload functionality
│   ├── create_short/       # Short creation and job management
│   └── jobs/               # Job listing and management
└── shared/                 # Shared widgets and services
    ├── widgets/            # Reusable UI components
    └── services/           # Shared services
```

### Feature Structure (Clean Architecture)

Each feature follows the clean architecture pattern:

```
feature/
├── data/
│   ├── datasources/        # Remote and local data sources
│   ├── models/             # Data models
│   └── repositories/       # Repository implementations
├── domain/
│   ├── entities/           # Business entities
│   ├── repositories/       # Repository interfaces
│   └── usecases/           # Business logic
└── presentation/
    ├── bloc/               # State management (BLoC)
    ├── pages/              # UI screens
    └── widgets/            # Feature-specific widgets
```

## 🛠️ Setup & Installation

### Prerequisites

- Flutter SDK (>=3.1.0)
- Dart SDK
- Android Studio / VS Code
- iOS development tools (for iOS builds)

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd youtube_shorts_frontend
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run code generation**
   ```bash
   flutter packages pub run build_runner build
   ```

4. **Configure environment**
   - Update API endpoints in `lib/core/constants/api_constants.dart`
   - Add your backend URL

5. **Run the app**
   ```bash
   flutter run
   ```

## 📦 Dependencies

### Core Dependencies
- `flutter_bloc` - State management
- `equatable` - Value equality
- `dio` - HTTP client
- `get_it` - Dependency injection
- `injectable` - Code generation for DI

### UI Dependencies
- `flutter_spinkit` - Loading animations
- `lottie` - Lottie animations
- `percent_indicator` - Progress indicators
- `fluttertoast` - Toast notifications

### File Handling
- `file_picker` - File selection
- `video_player` - Video playback
- `path` - Path manipulation
- `mime` - MIME type detection

### Storage & Utils
- `shared_preferences` - Local storage
- `url_launcher` - URL launching
- `uuid` - UUID generation
- `intl` - Internationalization

## 🎨 UI/UX Guidelines

### Design System

- **Colors**: Material Design 3 color system with custom YouTube branding
- **Typography**: Roboto font family with consistent text styles
- **Spacing**: 8px grid system for consistent spacing
- **Components**: Reusable components following Material Design guidelines

### Responsive Design

- Mobile-first approach
- Adaptive layouts for different screen sizes
- Support for both portrait and landscape orientations

## 🔧 Development

### State Management

The app uses **BLoC (Business Logic Component)** pattern for state management:

```dart
// Example BLoC usage
BlocBuilder<UploadBloc, UploadState>(
  builder: (context, state) {
    if (state is UploadLoading) {
      return const LoadingWidget();
    } else if (state is UploadSuccess) {
      return const SuccessWidget();
    } else if (state is UploadError) {
      return ErrorWidget(state.message);
    }
    return const InitialWidget();
  },
)
```

### API Integration

The app communicates with the backend through a robust API client:

```dart
// Example API call
final response = await apiClient.uploadFile(
  '/upload/video',
  file,
  onSendProgress: (sent, total) {
    // Update progress
  },
);
```

### Error Handling

Comprehensive error handling with custom exceptions and user-friendly messages:

```dart
try {
  await uploadUseCase.call(params);
} on NetworkException catch (e) {
  emit(UploadError('Please check your internet connection'));
} on ServerException catch (e) {
  emit(UploadError('Server error: ${e.message}'));
}
```

## 🧪 Testing

### Running Tests

```bash
# Run all tests
flutter test

# Run tests with coverage
flutter test --coverage

# Run integration tests
flutter drive --target=test_driver/app.dart
```

### Test Structure

```
test/
├── unit/                   # Unit tests
├── widget/                 # Widget tests
└── integration/            # Integration tests
```

## 📱 Platform Support

- ✅ Android (API 21+)
- ✅ iOS (iOS 12+)
- ✅ Web (Chrome, Firefox, Safari, Edge)
- ⏳ Desktop (Windows, macOS, Linux) - Coming soon

## 🚀 Deployment

### Android

```bash
flutter build apk --release
```

### iOS

```bash
flutter build ios --release
```

### Web

```bash
flutter build web --release
```

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Code Style

- Follow Dart/Flutter style guidelines
- Use meaningful variable and function names
- Add comments for complex logic
- Write tests for new features

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Material Design team for design guidelines
- YouTube API for integration capabilities

## 📞 Support

For support and questions:
- Create an issue on GitHub
- Contact the development team

---
secret added

**Built with ❤️ using Flutter**
