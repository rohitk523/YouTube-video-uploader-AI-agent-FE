#!/bin/bash

# Production build script for Flutter Web
echo "🚀 Building Flutter Web for Production..."

# Set production API URL (Railway as primary)
export API_BASE_URL="https://youtube-shorts-api-production.up.railway.app"

# Clean previous builds
echo "🧹 Cleaning previous builds..."
flutter clean

# Get dependencies
echo "📦 Getting dependencies..."
flutter pub get

# Build for web with production settings
echo "🔨 Building for web (production)..."
flutter build web --release \
  --dart-define=API_BASE_URL=$API_BASE_URL \
  --dart-define=FLUTTER_ENV=production \
  --web-renderer html \
  --base-href="/"

echo "✅ Production build completed!"
echo "📁 Build output is in: build/web/"
echo "🌐 API URL configured as: $API_BASE_URL" 