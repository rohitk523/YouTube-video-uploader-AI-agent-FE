# YouTube Shorts Creator - Flutter Frontend

A comprehensive Flutter application for creating and managing YouTube Shorts with AI-powered video processing capabilities.

## 🚀 Features

### ✨ Core Functionality
- **Video Upload & Management**: Upload videos with preview and progress tracking
- **Transcript Integration**: Support for both text input and file upload (TXT, SRT, VTT)
- **AI-Powered Processing**: Convert videos with custom voice synthesis
- **Real-time Job Monitoring**: Track processing status with live updates
- **YouTube Integration**: Automatic upload to YouTube with OAuth authentication
- **Responsive Design**: Modern Material Design 3 interface

### 📱 User Experience
- **Interactive Video Player**: Custom video preview with playback controls
- **Progress Tracking**: Real-time status updates and progress indicators
- **File Management**: Drag-and-drop file selection with validation
- **Error Handling**: Comprehensive error states and user feedback
- **Offline Support**: Local state management with BLoC pattern

## 🛠️ Technical Architecture

### State Management
- **BLoC Pattern**: Reactive state management for all features
- **Repository Pattern**: Clean separation of data layer
- **Dependency Injection**: Service locator pattern with GetIt

### Key Technologies
- **Flutter**: Modern cross-platform UI framework
- **BLoC**: Business Logic Component for state management
- **Dio**: HTTP client for API communication
- **Video Player**: Advanced video playback capabilities
- **File Picker**: Cross-platform file selection

## 🔧 Setup Instructions

### Prerequisites
- **Flutter SDK**: 3.16.0 or higher
- **Dart SDK**: 3.2.0 or higher
- **Android Studio** or **VS Code** with Flutter extensions
- **Backend API**: YouTube Shorts Creator API running

### Installation

1. **Clone the Repository**
   ```bash
   git clone <repository-url>
   cd youtube_shorts_frontend
   ```

2. **Install Dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure API Endpoint**
   
   Update the API base URL in `lib/core/constants/api_constants.dart`:
   ```dart
   static const String developmentBaseUrl = 'http://your-backend-url:8000';
   // For production:
   static const String productionBaseUrl = 'https://your-production-domain.com';
   ```

4. **Run the Application**
   ```bash
   # For development
   flutter run
   
   # For specific device
   flutter run -d chrome  # Web
   flutter run -d android # Android
   flutter run -d ios     # iOS
   ```

### Backend Integration

The app integrates with the YouTube Shorts Creator API. Ensure your backend is running and accessible.

#### Required API Endpoints
- `POST /api/v1/oauth/register` - User registration
- `POST /api/v1/oauth/token` - Authentication
- `POST /api/v1/upload/video` - Video upload
- `POST /api/v1/upload/transcript-text` - Transcript upload
- `POST /api/v1/jobs/create` - Job creation
- `GET /api/v1/jobs` - Job listing
- `GET /api/v1/jobs/{id}` - Job details

## 📁 Project Structure

```
lib/
├── core/                       # Core application components
│   ├── constants/             # API constants and configuration
│   ├── di/                    # Dependency injection setup
│   ├── errors/                # Error handling and exceptions
│   ├── network/               # HTTP client and network layer
│   ├── theme/                 # Application theming
│   └── utils/                 # Routing and utilities
├── features/                  # Feature-based modules
│   ├── auth/                  # Authentication
│   │   ├── bloc/             # Authentication BLoC
│   │   ├── repository/       # Auth data layer
│   │   └── screens/          # Auth UI screens
│   ├── create_short/         # Video creation feature
│   ├── jobs/                 # Job management
│   └── upload/               # File upload functionality
├── shared/                   # Shared components
│   ├── models/              # Data models
│   └── widgets/             # Reusable UI components
└── main.dart                # Application entry point
```

## 🎨 UI Components

### Custom Widgets
- **VideoPreviewWidget**: Advanced video player with controls
- **VideoThumbnailWidget**: Efficient thumbnail generation
- **Custom Progress Indicators**: Real-time upload progress
- **Responsive Cards**: Adaptive layout components

### Design System
- **Material Design 3**: Latest design language implementation
- **YouTube Branding**: Consistent color scheme
- **Responsive Layout**: Adapts to different screen sizes
- **Accessibility**: Screen reader support and keyboard navigation

## 🔐 Authentication Flow

1. **User Registration**: Create account with email/password
2. **OAuth Integration**: Secure token-based authentication
3. **YouTube OAuth**: Seamless YouTube account linking
4. **Token Management**: Automatic refresh and secure storage

## 📊 Job Management

### Job Lifecycle
1. **Creation**: User uploads video and transcript
2. **Processing**: AI processes content with selected voice
3. **Completion**: Generated video ready for download
4. **YouTube Upload**: Optional automatic publishing

### Real-time Updates
- **Polling**: Automatic status updates every 5 seconds
- **Progress Tracking**: Visual progress indicators
- **Error Handling**: Detailed error reporting
- **Retry Mechanism**: Failed job retry capability

## 🎵 Voice Synthesis

Supported voices for text-to-speech conversion:
- **Alloy**: Neutral, balanced tone
- **Echo**: Clear, professional voice
- **Fable**: Warm, storytelling style
- **Onyx**: Deep, authoritative tone
- **Nova**: Energetic, youthful voice
- **Shimmer**: Bright, engaging style

## 🚀 Deployment

### Mobile Deployment

**Android**
```bash
flutter build apk --release
# or for app bundle
flutter build appbundle --release
```

**iOS**
```bash
flutter build ios --release
```

### Web Deployment
```bash
flutter build web --release
```

## 🧪 Testing

### Running Tests
```bash
# Unit tests
flutter test

# Integration tests
flutter test integration_test/

# Widget tests
flutter test test/widget_test.dart
```

### Test Coverage
```bash
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

## 🐛 Troubleshooting

### Common Issues

**Video Upload Fails**
- Check network connectivity
- Verify API endpoint configuration
- Ensure file format is supported (MP4, MOV, AVI)

**Authentication Errors**
- Verify backend API is running
- Check OAuth configuration
- Clear app data and retry

**Job Processing Stuck**
- Check backend processing queue
- Verify transcript format
- Review error logs in job details

### Debug Mode
```bash
flutter run --debug
flutter logs
```

## 📚 API Documentation

For detailed API documentation, refer to the backend API documentation. Key endpoints:

- **Authentication**: `/api/v1/oauth/*`
- **File Upload**: `/api/v1/upload/*`
- **Job Management**: `/api/v1/jobs/*`
- **YouTube Integration**: `/api/v1/youtube/*`

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🆘 Support

For support and questions:
- Create an issue on GitHub
- Check the troubleshooting section
- Review the API documentation

---

**Built with ❤️ using Flutter**
