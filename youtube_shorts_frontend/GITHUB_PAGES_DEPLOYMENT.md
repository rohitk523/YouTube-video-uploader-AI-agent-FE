# GitHub Pages Deployment Guide

This guide explains how to deploy your Flutter web app to GitHub Pages using the automated GitHub Actions workflow.

## Setup Instructions

### 1. Push the Workflow Files
The following files have been created for you:
- `.github/workflows/deploy.yml` - GitHub Actions workflow (at repository root)
- `youtube_shorts_frontend/web/.nojekyll` - Prevents Jekyll processing
- `youtube_shorts_frontend/lib/core/config/environment.dart` - Environment configuration
- `youtube_shorts_frontend/ENVIRONMENT_SETUP.md` - Detailed environment setup guide

Make sure to commit and push these files to your repository.

### 2. Configure Backend URL (IMPORTANT!)

Your Flutter app needs to know your production backend URL. See `ENVIRONMENT_SETUP.md` for detailed instructions.

**Quick Setup:**
1. Go to your GitHub repository
2. Navigate to **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**
4. Add secret:
   - **Name**: `API_BASE_URL`
   - **Value**: Your production backend URL (e.g., `https://your-backend.onrender.com`)

### 3. Enable GitHub Pages in Repository Settings

1. Go to your GitHub repository
2. Navigate to **Settings** → **Pages** (in the left sidebar)
3. Under **Source**, select **GitHub Actions**
4. The workflow will automatically trigger on the next push to the `main` branch

### 3. Repository Settings
The workflow is configured for your repository structure:
- Repository name: `YouTube-video-uploader-AI-agent-FE`
- Flutter project location: `youtube_shorts_frontend/` subdirectory
- The base href is set to: `/YouTube-video-uploader-AI-agent-FE/`

### 4. First Deployment
After setting up GitHub Pages and backend URL:
1. Make any small change to your Flutter code
2. Commit and push to the `main` branch
3. The workflow will automatically run and deploy your app
4. Your app will be available at: `https://yourusername.github.io/YouTube-video-uploader-AI-agent-FE/`

**Note**: Without setting `API_BASE_URL`, your app will try to connect to `https://your-backend-domain.com` (placeholder URL).

## Workflow Details

The workflow:
- ✅ Triggers on push to `main` branch
- ✅ Sets up Flutter 3.32.2 (latest stable)
- ✅ Navigates to `youtube_shorts_frontend/` directory
- ✅ Installs dependencies
- ✅ Configures production environment with backend URL
- ✅ Builds the web app with proper base href (auto web renderer)
- ✅ Uses latest GitHub Actions (v4/v5) for deployment

## Monitoring Deployments

1. Go to the **Actions** tab in your GitHub repository
2. You'll see the deployment workflow runs
3. Click on any run to see the build logs
4. The deployment URL will be shown in the deploy job

## Troubleshooting

### Build Fails
- Check the Actions tab for error logs
- Ensure all dependencies in `pubspec.yaml` are compatible with web
- Verify Flutter version compatibility

### Site Not Loading
- Check that GitHub Pages is enabled
- Verify the base href matches your repository name
- Ensure `.nojekyll` file is present in the `web` directory

### Wrong Base URL
If your repository name is different from `YouTube-video-uploader-AI-agent-FE`, update the base-href in `.github/workflows/deploy.yml`:
```yaml
flutter build web --release --web-renderer html --base-href="/your-actual-repo-name/"
```

## Manual Testing Locally

To test the web build locally:
```bash
cd youtube_shorts_frontend
flutter build web --release
cd build/web
python -m http.server 8000
```

Then visit `http://localhost:8000` to test your app.

**Note**: The `--web-renderer` flag has been removed as it's deprecated in Flutter 3.32.2+. Flutter now automatically selects the best renderer. 