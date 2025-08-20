# Firebase Storage Setup Instructions

## Problem
The app is getting HTTP 404 "Object does not exist at location" when trying to upload to Firebase Storage.

## Root Cause
The Firebase Storage bucket may not be properly initialized or the storage rules are too restrictive.

## Solution Steps

### 1. Install Firebase CLI (Required)
```powershell
npm install -g firebase-tools
```

### 2. Login to Firebase
```powershell
firebase login
```

### 3. Initialize Firebase Storage
```powershell
cd e:\luminachat-2.0
firebase init storage
# Select your project: lumina-chat-app-36597
# Accept the default storage.rules file
```

### 4. Deploy Storage Rules
```powershell
firebase deploy --only storage
```

### 5. Verify Firebase Storage in Console
- Go to: https://console.firebase.google.com/project/lumina-chat-app-36597/storage
- Ensure the bucket `lumina-chat-app-36597.firebasestorage.app` exists
- Check that the Storage rules are applied

## Alternative: Manual Setup in Firebase Console

1. Go to Firebase Console: https://console.firebase.google.com/project/lumina-chat-app-36597
2. Navigate to Storage > Files
3. Click "Get Started" if Storage is not initialized
4. Go to Storage > Rules
5. Replace the rules with the content from `storage.rules` file

## Storage Rules
The rules are already updated in `storage.rules` to allow:
- Profile images: authenticated users can manage their own images in `profile_images/{userId}/`
- Test uploads: authenticated users can upload to root (temporary for testing)

## Testing After Setup
1. Run the Flutter app
2. Navigate to profile photo setup
3. Try uploading a photo
4. Check the detailed logs in the terminal for success/failure

## Expected Behavior After Fix
- Upload should succeed
- Photo should appear in Firebase Storage console
- App should display the uploaded photo
- No "object-not-found" errors in logs
