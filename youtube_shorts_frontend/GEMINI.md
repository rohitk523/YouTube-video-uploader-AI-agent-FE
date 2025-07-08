# Frontend Context and Architecture

This frontend service is part of a YouTube video uploader AI agent, designed to automate the process of uploading videos to YouTube, potentially with AI-generated content like transcripts and voiceovers.

## Key Technologies:

*   **UI Framework:** Flutter (for building natively compiled applications for mobile, web, and desktop from a single codebase)
*   **State Management:** BLoC Pattern (Business Logic Component for reactive state management)
*   **Dependency Injection:** GetIt (service locator pattern)
*   **Network:** Dio (HTTP client for API communication)
*   **File Handling:** file_picker (cross-platform file selection)
*   **Video Playback:** video_player (advanced video playback capabilities)
*   **Local Storage:** shared_preferences (for persisting simple data)
*   **UI/UX:** Material Design 3 (latest design language implementation)
*   **Utilities:** `url_launcher`, `uuid`, `intl`, `lottie`, `fluttertoast`, `percent_indicator`, `cached_network_image`

## Architecture Overview:

The frontend follows a modular and layered architecture, emphasizing separation of concerns and reactive programming principles.

1.  **Core Layer:**
    *   **`config/`**: Environment-specific configurations (e.g., API base URLs).
    *   **`constants/`**: API endpoints and other static constants.
    *   **`di/`**: Dependency Injection setup using GetIt.
    *   **`errors/`**: Custom application exceptions.
    *   **`network/`**: HTTP client (`ApiClient`) for interacting with the backend API, including error handling and token management.
    *   **`theme/`**: Application theming and theme management.
    *   **`utils/`**: Application routing (`AppRouter`) and other utility functions.

2.  **Features Layer:**
    *   Organized by feature (e.g., `auth`, `create_short`, `jobs`, `upload`, `videos`).
    *   Each feature typically contains:
        *   **`bloc/`**: BLoC (Business Logic Component) for managing the feature's state and business logic.
        *   **`repository/`**: Abstraction layer for data operations, interacting with the `ApiClient`.
        *   **`screens/`**: User interface components (widgets) for the feature.
        *   **`widgets/`**: Reusable UI components specific to the feature.

3.  **Shared Layer:**
    *   **`models/`**: Data models used across different features (e.g., `user_models.dart`, `job_models.dart`, `upload_models.dart`, `video_models.dart`).
    *   **`widgets/`**: Generic, reusable UI components (e.g., `video_preview_widget.dart`, `api_status_widget.dart`).

## State Management (BLoC Pattern):

The application heavily utilizes the BLoC pattern for state management. Each significant feature has its own BLoC, which:
*   Receives `Events` (user actions or external triggers).
*   Processes business logic (often by interacting with repositories).
*   Emits new `States` to update the UI.

This ensures a clear separation between UI, business logic, and data layers, promoting testability and maintainability.

## API Communication:

The `ApiClient` handles all HTTP requests to the backend. It includes:
*   Interceptor for adding authentication tokens.
*   Error handling and transformation of Dio errors into custom `AppException` types.
*   Automatic failover mechanism for production environments, switching between primary and fallback backend URLs in case of network issues.

## Environment Configuration:

The application supports environment-based configuration using `dart-define` flags during build time (`FLUTTER_ENV`, `API_BASE_URL`). This allows for different API endpoints and behaviors in development vs. production.

*   **`lib/core/config/environment.dart`**: Manages environment variables and provides access to the correct API base URL based on the current environment.
*   **`lib/core/constants/api_constants.dart`**: Defines all API endpoints, dynamically constructing full URLs using the `EnvironmentConfig.apiBaseUrl`.

## Deployment:

The frontend can be deployed to various platforms, with specific configurations for:
*   **GitHub Pages**: Automated deployment via GitHub Actions, including `base-href` configuration and backend URL handling via GitHub Secrets.
*   **Render**: Automated deployment with specific build commands and publish directories.

This architecture ensures scalability, maintainability, and a robust user experience by leveraging modern Flutter development practices and clear separation of concerns.
