# Environment Configuration Guide

This guide explains how to configure your Flutter web app for different environments (local development vs production deployment).

## 🏗️ Architecture

The app uses environment-based configuration with the following files:
- `lib/core/config/environment.dart` - Environment configuration manager
- `lib/core/constants/api_constants.dart` - API endpoints using environment config

## 🔧 Environment Variables

### `API_BASE_URL`
The backend API base URL (without `/api/v1`)

### `FLUTTER_ENV`
The deployment environment (`development` or `production`)

## 🚀 Setup for GitHub Pages Deployment

### Step 1: Set Your Backend URL

You need to configure where your production backend is hosted. You have two options:

#### Option A: Use GitHub Secrets (Recommended)
1. Go to your GitHub repository
2. Navigate to **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**
4. Add secret:
   - **Name**: `API_BASE_URL`
   - **Value**: Your production backend URL (e.g., `https://your-app-name.onrender.com`)

#### Option B: Update Default Production URL
1. Edit `lib/core/config/environment.dart`
2. Replace `https://your-backend-domain.com` with your actual backend URL:
```dart
case Environment.production:
  return 'https://your-actual-backend-url.com'; // Update this line
```

### Step 2: Verify Workflow Configuration

The GitHub Actions workflow is already configured to:
- ✅ Use `API_BASE_URL` secret if provided
- ✅ Fall back to default production URL
- ✅ Set `FLUTTER_ENV=production` for production builds

## 🏠 Local Development

### Running Locally
```bash
cd youtube_shorts_frontend

# Development (uses localhost:8000)
flutter run -d chrome

# Or explicitly set environment
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8000 --dart-define=FLUTTER_ENV=development
```

### Testing with Different Backend URLs
```bash
# Test with staging backend
flutter run -d chrome --dart-define=API_BASE_URL=https://staging.yourapi.com --dart-define=FLUTTER_ENV=production

# Test with local backend on different port
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:3000 --dart-define=FLUTTER_ENV=development
```

## 🔍 Environment Detection

Your app can detect the current environment:

```dart
import 'package:your_app/core/config/environment.dart';

// Check current environment
if (EnvironmentConfig.isProduction) {
  print('Running in production');
} else {
  print('Running in development');
}

// Get current API URL
print('API Base URL: ${EnvironmentConfig.apiBaseUrl}');

// Debug info
print('Environment Info: ${EnvironmentConfig.debugInfo}');
```

## 📱 Testing Production Build Locally

To test the production build locally:

```bash
cd youtube_shorts_frontend

# Build for production with your backend URL
flutter build web --release --dart-define=API_BASE_URL=https://your-backend-url.com --dart-define=FLUTTER_ENV=production

# Serve the built files
cd build/web
python -m http.server 8000
```

Then visit `http://localhost:8000`

## 🐛 Troubleshooting

### Backend URL Issues
1. **CORS Errors**: Ensure your backend allows requests from your GitHub Pages domain
2. **Wrong URL**: Check that `API_BASE_URL` doesn't end with `/api/v1` (this is added automatically)
3. **HTTPS Required**: GitHub Pages requires HTTPS, so your backend must support HTTPS

### Environment Not Loading
1. Check GitHub secret name is exactly `API_BASE_URL`
2. Verify the secret value doesn't have trailing slashes
3. Look at GitHub Actions logs for build-time environment values

### Debug Environment in App
Add this to your app's debug screen or console:

```dart
import 'package:your_app/core/config/environment.dart';

print('=== Environment Debug Info ===');
EnvironmentConfig.debugInfo.forEach((key, value) {
  print('$key: $value');
});
```

## 📝 Example Configurations

### Backend URLs Format
```
✅ Correct:   https://api.yourapp.com
✅ Correct:   https://yourapp-backend.onrender.com
✅ Correct:   http://localhost:8000

❌ Wrong:    https://api.yourapp.com/api/v1  (don't include /api/v1)
❌ Wrong:    https://api.yourapp.com/        (don't include trailing slash)
```

### Common Backend Hosts
- **Render**: `https://your-app-name.onrender.com`
- **Railway**: `https://your-app-name.up.railway.app`
- **Heroku**: `https://your-app-name.herokuapp.com`
- **DigitalOcean**: `https://your-droplet-ip`
- **AWS/GCP**: `https://your-custom-domain.com`

## 🔄 Workflow Summary

1. **Local Development**: Uses `http://localhost:8000` automatically
2. **GitHub Pages Build**: Uses `API_BASE_URL` secret or default production URL
3. **Manual Build**: Pass `--dart-define=API_BASE_URL=...` as needed

Your app will be available at: `https://yourusername.github.io/YouTube-video-uploader-AI-agent-FE/` 