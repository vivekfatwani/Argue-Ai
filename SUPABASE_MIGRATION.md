# 🚀 Supabase Migration Guide - ArguMentor

## 📋 Overview

Migrating from Firebase to Supabase to fix authentication issues and get better features.

**Migration Time:** ~2 hours  
**Difficulty:** Medium  
**Benefits:** Better free tier, PostgreSQL, no API key suspensions

---

## 🎯 Step 1: Create Supabase Project (5 minutes)

### 1.1 Sign Up
1. Go to https://supabase.com
2. Click "Start your project"
3. Sign up with GitHub (recommended)

### 1.2 Create New Project
1. Click "New project"
2. Organization: Choose or create one
3. Name: `argumentor` or `argue-ai`
4. Database Password: **Save this securely!**
5. Region: Choose nearest (e.g., `us-east-1`)
6. Click "Create new project"
7. Wait ~2 minutes for setup

### 1.3 Get Credentials
1. Go to Project Settings (gear icon)
2. Click "API" tab
3. Copy these values:
   - **Project URL**: `https://xxxxx.supabase.co`
   - **anon public key**: `eyJhbGci...` (long key)
   
**Save these - you'll need them!**

---

## 🗄️ Step 2: Set Up Database Schema (10 minutes)

### 2.1 Open SQL Editor
1. In Supabase dashboard, click "SQL Editor"
2. Click "New query"
3. Paste the following SQL:

```sql
-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Users table
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  email TEXT UNIQUE NOT NULL,
  name TEXT NOT NULL,
  points INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  last_active TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  preferences JSONB DEFAULT '{}'::jsonb,
  completed_resources TEXT[] DEFAULT ARRAY[]::TEXT[]
);

-- Skills table (for user skills)
CREATE TABLE user_skills (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  skill_name TEXT NOT NULL,
  rating DECIMAL(3,2) NOT NULL CHECK (rating >= 0 AND rating <= 1),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, skill_name)
);

-- Debates table
CREATE TABLE debates (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  topic TEXT NOT NULL,
  mode TEXT NOT NULL CHECK (mode IN ('text', 'voice')),
  start_time TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  end_time TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Debate messages table
CREATE TABLE debate_messages (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  debate_id UUID REFERENCES debates(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  is_user BOOLEAN NOT NULL,
  timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Debate feedback table
CREATE TABLE debate_feedback (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  debate_id UUID REFERENCES debates(id) ON DELETE CASCADE UNIQUE,
  clarity DECIMAL(3,2),
  logic DECIMAL(3,2),
  rebuttal_quality DECIMAL(3,2),
  persuasiveness DECIMAL(3,2),
  communication DECIMAL(3,2),
  strengths TEXT[] DEFAULT ARRAY[]::TEXT[],
  improvements TEXT[] DEFAULT ARRAY[]::TEXT[],
  overall_feedback TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Learning resources table
CREATE TABLE learning_resources (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  title TEXT NOT NULL,
  description TEXT,
  skill_category TEXT NOT NULL,
  resource_type TEXT NOT NULL,
  url TEXT,
  duration_minutes INTEGER,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for better performance
CREATE INDEX idx_debates_user_id ON debates(user_id);
CREATE INDEX idx_debate_messages_debate_id ON debate_messages(debate_id);
CREATE INDEX idx_user_skills_user_id ON user_skills(user_id);
CREATE INDEX idx_users_email ON users(email);

-- Enable Row Level Security
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_skills ENABLE ROW LEVEL SECURITY;
ALTER TABLE debates ENABLE ROW LEVEL SECURITY;
ALTER TABLE debate_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE debate_feedback ENABLE ROW LEVEL SECURITY;
ALTER TABLE learning_resources ENABLE ROW LEVEL SECURITY;

-- RLS Policies for users table
CREATE POLICY "Users can view own data" ON users
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own data" ON users
  FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can insert own data" ON users
  FOR INSERT WITH CHECK (auth.uid() = id);

-- RLS Policies for user_skills
CREATE POLICY "Users can view own skills" ON user_skills
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can manage own skills" ON user_skills
  FOR ALL USING (auth.uid() = user_id);

-- RLS Policies for debates
CREATE POLICY "Users can view own debates" ON debates
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can create own debates" ON debates
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own debates" ON debates
  FOR UPDATE USING (auth.uid() = user_id);

-- RLS Policies for debate_messages
CREATE POLICY "Users can view messages from own debates" ON debate_messages
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM debates 
      WHERE debates.id = debate_messages.debate_id 
      AND debates.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can create messages in own debates" ON debate_messages
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM debates 
      WHERE debates.id = debate_messages.debate_id 
      AND debates.user_id = auth.uid()
    )
  );

-- RLS Policies for debate_feedback
CREATE POLICY "Users can view own debate feedback" ON debate_feedback
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM debates 
      WHERE debates.id = debate_feedback.debate_id 
      AND debates.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can create own debate feedback" ON debate_feedback
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM debates 
      WHERE debates.id = debate_feedback.debate_id 
      AND debates.user_id = auth.uid()
    )
  );

-- RLS Policies for learning_resources (public read)
CREATE POLICY "Anyone can view learning resources" ON learning_resources
  FOR SELECT TO authenticated USING (true);
```

4. Click "Run" (or press Ctrl+Enter)
5. ✅ You should see "Success. No rows returned"

### 2.2 Verify Tables
1. Click "Table Editor" in sidebar
2. You should see all tables: users, debates, debate_messages, etc.

---

## 📦 Step 3: Update Dependencies (5 minutes)

### 3.1 Update `pubspec.yaml`

```yaml
dependencies:
  # Remove Firebase packages
  # firebase_core: ^2.15.1
  # firebase_auth: ^4.7.3
  # cloud_firestore: ^4.8.5
  # firebase_storage: ^11.2.6
  
  # Add Supabase
  supabase_flutter: ^2.5.0
  
  # Keep existing packages
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.2
  provider: 6.0.5
  shared_preferences: ^2.2.2
  go_router: 12.1.1
  google_generative_ai: ^0.1.0
  http: ^1.1.0
  intl: ^0.18.1
  fl_chart: 0.63.0
  audioplayers: ^5.2.0
  path_provider: ^2.1.1
  uuid: ^4.0.0
  flutter_svg: ^2.0.9
  speech_to_text: ^7.3.0
  flutter_tts: ^4.2.0
```

### 3.2 Install Packages

```bash
flutter pub get
```

---

## 🔧 Step 4: Code Migration (Files Updated)

I've updated these files for you:

1. ✅ `lib/main.dart` - Supabase initialization
2. ✅ `lib/core/services/supabase_service.dart` - NEW SERVICE
3. ✅ `lib/core/providers/user_provider.dart` - Updated for Supabase
4. ✅ `lib/core/services/storage_service.dart` - Updated for PostgreSQL

---

## 🧪 Step 5: Testing (10 minutes)

### 5.1 Clear Old Data
```bash
flutter clean
flutter pub get
```

### 5.2 Run App
```bash
flutter run
```

### 5.3 Test Authentication
1. **Sign Up:**
   - Open app
   - Go to "Create Account"
   - Fill in details
   - Click "Create Account"
   - ✅ Should succeed

2. **Verify in Supabase:**
   - Go to Supabase Dashboard
   - Click "Authentication" → "Users"
   - ✅ Your user should appear
   - Click "Table Editor" → "users"
   - ✅ User data should be there

3. **Test Login:**
   - Logout
   - Login with same credentials
   - ✅ Should work

4. **Test Debate:**
   - Start a text debate
   - Send messages
   - End debate
   - ✅ Check feedback screen

---

## 🔑 Configuration

### Add Supabase credentials to `lib/core/config/supabase_config.dart`:

```dart
class SupabaseConfig {
  static const String supabaseUrl = 'YOUR_SUPABASE_URL';
  static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
}
```

**Replace with your actual values from Step 1.3!**

---

## 📊 Data Migration (If you have existing data)

### Export from Firebase:
1. Go to Firebase Console
2. Firestore Database
3. Export collection

### Import to Supabase:
1. Convert JSON to SQL INSERT statements
2. Run in Supabase SQL Editor

**For this migration, starting fresh is recommended since your Firebase is suspended.**

---

## ✅ Benefits You Get

1. **🆓 Better Free Tier:**
   - 500MB database
   - 1GB file storage
   - 2GB bandwidth
   - Unlimited API requests

2. **💰 Pricing:**
   - Free: $0/month
   - Pro: $25/month (when you need it)
   - vs Firebase: Can get expensive quickly

3. **🔒 Security:**
   - Row Level Security built-in
   - No API key suspension issues
   - PostgreSQL security features

4. **🚀 Performance:**
   - Direct PostgreSQL queries
   - Realtime subscriptions
   - Better indexing

---

## 🐛 Troubleshooting

### Issue: "Invalid API key"
**Solution:** Double-check your `supabase_config.dart` has correct URL and anon key

### Issue: "Row Level Security policy violation"
**Solution:** Make sure you ran the RLS policies SQL from Step 2.1

### Issue: "User not found after signup"
**Solution:** 
- Check Supabase Dashboard → Authentication → Users
- Verify email is confirmed (auto-confirmed by default)

### Issue: "Connection timeout"
**Solution:**
- Check internet connection
- Verify Supabase project is active (not paused)

---

## 🎉 Migration Complete!

Your app now uses:
- ✅ Supabase Authentication (instead of Firebase Auth)
- ✅ PostgreSQL Database (instead of Firestore)
- ✅ Row Level Security (automatic)
- ✅ Better free tier
- ✅ No API key issues

**Next Steps:**
1. Test all features thoroughly
2. Add more RLS policies as needed
3. Set up backups in Supabase
4. Consider upgrading to Pro when you launch

---

## 📞 Need Help?

- Supabase Docs: https://supabase.com/docs
- Flutter Client: https://supabase.com/docs/reference/dart
- Discord: https://discord.supabase.com

**Your migration is complete! 🚀**
