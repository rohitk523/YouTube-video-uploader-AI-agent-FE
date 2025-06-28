# Deploy Flutter Frontend to Render

Simple guide to deploy your YouTube Shorts Creator frontend to production.

## 🚀 Quick Deployment Steps

### 1. Push Code to GitHub
Make sure your frontend code is in a GitHub repository.

### 2. Connect to Render
1. Go to [Render Dashboard](https://dashboard.render.com)
2. Click "New +" → "Static Site"
3. Connect your GitHub repository
4. Select the `YouTube-video-uploader-AI-agent-FE/youtube_shorts_frontend` directory

### 3. Configure Build Settings
Render will automatically detect the `render.yaml` file and configure:

- **Build Command**: Installs Flutter and builds the web app
- **Publish Directory**: `build/web`
- **API URL**: Points to your backend at `https://youtube-video-uploader-ai-agent-be.onrender.com`

### 4. Deploy
Click "Create Static Site" and Render will:
1. Install Flutter
2. Run the production build script
3. Deploy your app as a static site

### 5. Update Backend CORS (Important!)
After deployment, update your backend's CORS settings to include your frontend domain.

In your backend's Render dashboard, add this environment variable:
```
CORS_ORIGINS_STR=https://your-frontend-name.onrender.com,http://localhost:3000
```

## 📱 Build Configuration

The build uses these settings:
- **API URL**: `https://youtube-video-uploader-ai-agent-be.onrender.com`
- **Web Renderer**: HTML (better compatibility)
- **Build Mode**: Release (optimized)

## 🔧 Local Testing

To test the production build locally:
```bash
chmod +x build_production.sh
./build_production.sh
cd build/web
python -m http.server 8080
```

Then visit: http://localhost:8080

## 🌐 Expected URLs

After deployment:
- **Frontend**: `https://your-frontend-name.onrender.com`
- **Backend**: `https://youtube-video-uploader-ai-agent-be.onrender.com`

## 🐛 Troubleshooting

**Build Fails**: Check Flutter installation in build logs
**CORS Errors**: Update backend CORS settings
**Routes Don't Work**: Ensure `_redirects` file is in `web/` directory
**API Calls Fail**: Verify API_BASE_URL in build logs

## 📈 Performance Tips

- Render automatically provides CDN and caching
- Flutter web builds are optimized for production
- Static assets are served efficiently 