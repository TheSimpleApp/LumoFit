# FitTravel Web Deployment Guide

This guide covers deploying FitTravel to the web using **Firebase Hosting** (recommended) or **Vercel**.

---

## Prerequisites

- Flutter web is already enabled in this project
- Web build tested and working: `flutter build web --release`

---

## Option 1: Firebase Hosting (Recommended)

Firebase Hosting is simpler for Flutter apps with built-in SPA support.

### Step 1: Install Firebase CLI

```bash
# Install Firebase CLI globally
npm install -g firebase-tools

# Login to Firebase
firebase login
```

### Step 2: Initialize Firebase in Project

```bash
firebase init hosting
```

When prompted:
1. **Select a project**: Choose your existing Firebase project or create a new one
2. **Public directory**: Enter `build/web`
3. **Configure as single-page app?**: Yes
4. **Set up automatic builds with GitHub?**: Optional (Yes if you want CI/CD)
5. **Overwrite index.html?**: **No** (important!)

### Step 3: Build and Deploy

```bash
# Build the Flutter web app
flutter build web --release

# Deploy to Firebase
firebase deploy --only hosting
```

### Step 4: Your Site is Live!

Firebase will output your URL: `https://your-project.web.app`

### Optional: Custom Domain

1. Go to Firebase Console → Hosting → Add custom domain
2. Follow the DNS verification steps
3. Firebase provides free SSL certificates

---

## Option 2: Vercel Deployment

If you prefer Vercel, follow these steps.

### Step 1: Create Vercel Configuration

Create a `vercel.json` file in the project root:

```json
{
  "buildCommand": "flutter build web --release",
  "outputDirectory": "build/web",
  "installCommand": "",
  "framework": null,
  "rewrites": [
    { "source": "/(.*)", "destination": "/index.html" }
  ]
}
```

**Note:** Vercel needs Flutter installed. For automatic builds, you'll need a custom build setup.

### Step 2: Manual Deploy (Easiest)

Since Vercel doesn't have Flutter pre-installed, the easiest approach is:

```bash
# Build locally
flutter build web --release

# Install Vercel CLI
npm install -g vercel

# Deploy the build folder
cd build/web
vercel --prod
```

When prompted:
1. **Set up and deploy?**: Yes
2. **Which scope?**: Select your account
3. **Link to existing project?**: No (or Yes if updating)
4. **Project name**: `fittravel` (or your preference)
5. **Directory**: `./` (current directory)
6. **Override settings?**: No

### Step 3: Your Site is Live!

Vercel will output your URL: `https://fittravel.vercel.app`

### Subsequent Deployments

```bash
# From project root
flutter build web --release
cd build/web && vercel --prod
```

### Optional: Vercel with GitHub Integration

For automatic deployments, create a `vercel-build.sh` script:

```bash
#!/bin/bash
# Install Flutter
git clone https://github.com/flutter/flutter.git -b stable --depth 1
export PATH="$PATH:$(pwd)/flutter/bin"
flutter doctor
flutter build web --release
```

Then update `vercel.json`:

```json
{
  "buildCommand": "chmod +x vercel-build.sh && ./vercel-build.sh",
  "outputDirectory": "build/web",
  "installCommand": "",
  "framework": null,
  "rewrites": [
    { "source": "/(.*)", "destination": "/index.html" }
  ]
}
```

---

## Environment Variables

### Google Maps API Key

The Google Maps API key is currently hardcoded in `web/index.html`. For production:

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new API key or restrict the existing one
3. Under **Application restrictions**, add your production domains:
   - `https://your-domain.com/*`
   - `https://fittravel.web.app/*` (if using Firebase)
   - `https://fittravel.vercel.app/*` (if using Vercel)

### Supabase

Supabase configuration is already set up and works on web automatically.

---

## Quick Reference Commands

```bash
# Build for web
flutter build web --release

# Test locally before deploying
flutter run -d chrome

# Firebase deploy
firebase deploy --only hosting

# Vercel deploy (from build/web folder)
vercel --prod
```

---

## Troubleshooting

### CORS Issues
If you encounter CORS errors, ensure your Supabase project allows your web domain in the API settings.

### Google Maps Not Loading
- Verify the API key is correct in `web/index.html`
- Ensure the Maps JavaScript API is enabled in Google Cloud Console
- Check domain restrictions on the API key

### Blank Page After Deploy
- Ensure the SPA rewrite rules are configured correctly
- Check browser console for JavaScript errors
- Verify all assets are being served correctly

---

## Recommendation

**Use Firebase Hosting** for the easiest deployment experience:
- Native SPA support
- Free SSL
- Fast global CDN
- Simple CLI workflow
- Easy custom domain setup
