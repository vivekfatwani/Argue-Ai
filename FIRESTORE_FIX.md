# 🔥 Fix Firestore Database Error

## Error Message
```
W/Firestore(28312): (24.11.0) [WriteStream]: (c352403) Stream closed with status: Status{code=NOT_FOUND, description=The database (default) does not exist for project argueai-2f86d Please visit https://console.cloud.google.com/datastore/setup?project=argueai-2f86d to add a Cloud Datastore or Cloud Firestore database.
```

## Solution: Create Firestore Database

### Step 1: Go to Firebase Console
1. Open your browser
2. Go to: https://console.firebase.google.com/
3. Select your project: **argueai-2f86d**

### Step 2: Create Firestore Database
1. In the left sidebar, click **"Firestore Database"** (or "Build" → "Firestore Database")
2. Click **"Create database"** button
3. Select **"Start in test mode"** for now (we'll secure it later)
4. Choose a location (select the one closest to your users):
   - For US: `us-central1`
   - For Europe: `europe-west1`
   - For Asia: `asia-southeast1`
5. Click **"Enable"**

### Step 3: Wait for Setup
- It will take 1-2 minutes to provision the database
- You'll see a message saying "Provisioning Cloud Firestore..."
- Once complete, you'll see the Firestore console

### Step 4: Test the App
1. Stop your Flutter app (if running)
2. Run it again: `flutter run`
3. Try signing out - it should work now!

## Alternative: Skip Firestore for Logout (Already Fixed!)

I've already updated the logout function to:
- **Timeout after 3 seconds** if Firestore is slow
- **Continue logout** even if Firestore fails
- **Not block the logout process** with Firestore errors

So the sign-out button should work even if Firestore isn't set up yet!

## Verify It's Working

After clicking sign out, check the console. You should see:
```
=== LOGOUT START ===
Firebase signOut completed
User set to null, isLoggedIn: false
Local storage cleared
=== LOGOUT COMPLETE, notifyListeners called ===
```

Then the app should redirect to the onboarding screen.
