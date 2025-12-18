# Trigger Codemagic Build Immediately

## Method 1: Using the API Script (Recommended)

1. **Get your Codemagic API Token:**
   - Go to: https://codemagic.io/settings
   - Copy your API token

2. **Get your App ID:**
   - Go to your Codemagic dashboard
   - Click on your FitTravel app
   - The App ID is in the URL or in the app settings

3. **Run the script:**
   ```bash
   chmod +x trigger_codemagic_build.sh
   ./trigger_codemagic_build.sh YOUR_API_TOKEN YOUR_APP_ID
   ```

   Or set environment variables:
   ```bash
   export CODEMAGIC_API_TOKEN='your-token'
   export CODEMAGIC_APP_ID='your-app-id'
   ./trigger_codemagic_build.sh
   ```

## Method 2: Using Codemagic CLI

1. **Install Codemagic CLI:**
   ```bash
   npm install -g codemagic-cli
   ```

2. **Login:**
   ```bash
   codemagic-cli login
   ```

3. **List your apps to find the App ID:**
   ```bash
   codemagic-cli apps list
   ```

4. **Trigger the build:**
   ```bash
   codemagic-cli builds start \
     --workflow ios-release \
     --branch main \
     --app-id YOUR_APP_ID
   ```

## Method 3: Using cURL Directly

```bash
curl -X POST "https://api.codemagic.io/builds" \
  -H "Content-Type: application/json" \
  -H "x-auth-token: YOUR_API_TOKEN" \
  -d '{
    "appId": "YOUR_APP_ID",
    "workflowId": "ios-release",
    "branch": "main"
  }'
```

## Method 4: Commit and Push (Automatic Trigger)

Since your workflow is configured to trigger on push to `main` or `master`:

```bash
git add codemagic.yaml
git commit -m "Update Codemagic config for auto-incrementing build numbers"
git push origin main
```

This will automatically trigger a build with the new configuration.

## What Changed

The updated `codemagic.yaml` now includes:
- ✅ Auto-incrementing build numbers from App Store Connect
- ✅ Dynamic version reading from `pubspec.yaml`
- ✅ Proper Team Key signing support
- ✅ Automatic export options handling

The build will:
1. Fetch the latest build number from App Store Connect
2. Increment it by 1
3. Build the IPA with the new build number
4. Automatically submit to TestFlight

