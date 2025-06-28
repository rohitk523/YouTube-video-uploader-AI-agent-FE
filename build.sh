#!/bin/bash

# Navigate to Flutter project
cd youtube_shorts_frontend

# Install Flutter
if [ ! -d "flutter" ]; then
  echo "Installing Flutter..."
  git clone https://github.com/flutter/flutter.git -b stable
fi

export PATH="$PATH:`pwd`/flutter/bin"

# Configure Flutter for web
flutter config --enable-web

# Get dependencies
flutter pub get

# Build for web with production API URL
flutter build web --release \
  --dart-define=API_BASE_URL=https://youtube-video-uploader-ai-agent-be.onrender.com \
  --web-renderer html \
  --base-href="/"

echo "Build completed! Output in: youtube_shorts_frontend/build/web" 