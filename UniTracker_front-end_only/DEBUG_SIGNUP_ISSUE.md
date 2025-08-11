# Debug Guide: Driver Signup Data Not Saving

## Quick Diagnosis Steps

### Step 1: Check Console Logs
When you sign up as a driver, look for these debug messages in the console:

```
🔥 AuthService: Testing database connection before signup...
🔥 SupabaseService: Testing database connection...
✅ Users table accessible. Sample data: [...]
✅ Drivers table accessible. Sample data: [...]
🔥 AuthService: Creating new driver account for ID: [YOUR_DRIVER_ID]
✅ AuthService: Auth account created successfully for user: [UUID]
🔥 AuthService: Checking permissions after auth account creation...
🔥 SupabaseService: Creating user profile with data: {...}
✅ SupabaseService: User profile created successfully: {...}
🔥 SupabaseService: Creating driver record with data: {...}
✅ SupabaseService: Driver record created successfully: {...}
```

**If you see error messages instead, note them down.**

### Step 2: Check Database Tables
Go to your Supabase Dashboard → Table Editor and check:

1. **Users table** - Look for a record with your driver ID
2. **Drivers table** - Look for a record with your driver ID

**If no records appear, the issue is with data insertion.**

### Step 3: Common Issues and Solutions

#### Issue A: "new row violates row-level security policy"
**Solution**: Run this SQL in Supabase SQL Editor:

```sql
-- Enable RLS and create proper policies
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE drivers ENABLE ROW LEVEL SECURITY;

-- Allow authenticated users to insert their own data
CREATE POLICY "Users can insert their own profile" ON users
  FOR INSERT WITH CHECK (auth.uid() = id);

CREATE POLICY "Drivers can insert their own record" ON drivers
  FOR INSERT WITH CHECK (auth.uid() = id);

-- Allow users to view their own data
CREATE POLICY "Users can view their own profile" ON users
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Drivers can view their own record" ON drivers
  FOR SELECT USING (auth.uid() = id);
```

#### Issue B: "column does not exist"
**Solution**: Check if your tables have the correct structure:

```sql
-- Check users table structure
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'users'
ORDER BY ordinal_position;

-- Check drivers table structure
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'drivers'
ORDER BY ordinal_position;
```

#### Issue C: "permission denied"
**Solution**: Check user permissions:

```sql
-- Check if current user can insert
SELECT has_table_privilege(current_user, 'users', 'INSERT') as can_insert_users;
SELECT has_table_privilege(current_user, 'drivers', 'INSERT') as can_insert_drivers;
```

### Step 4: Manual Test
Try manually inserting a test record:

```sql
-- Test insert into users table (replace with your actual values)
INSERT INTO users (
  id, email, full_name, role, driver_license, license_expiry, driver_id, is_active
) VALUES (
  'test-uuid-here', 'test@unitracker.driver', 'Test Driver', 'driver', 
  'TEST123', '2025-12-31', 'TEST123', true
);

-- Test insert into drivers table
INSERT INTO drivers (
  id, full_name, email, driver_license, license_expiry, driver_id, is_active
) VALUES (
  'test-uuid-here', 'Test Driver', 'test@unitracker.driver', 
  'TEST123', '2025-12-31', 'TEST123', true
);
```

### Step 5: Check Table Existence
Make sure the tables exist:

```sql
-- Check if tables exist
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('users', 'drivers');
```

If tables don't exist, create them:

```sql
-- Create users table
CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY,
  email TEXT NOT NULL,
  full_name TEXT NOT NULL,
  role TEXT NOT NULL,
  driver_license TEXT,
  license_expiry DATE,
  is_active BOOLEAN DEFAULT true,
  phone_number TEXT,
  driver_id TEXT,
  student_id TEXT,
  university TEXT,
  department TEXT,
  profile_image_url TEXT,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Create drivers table
CREATE TABLE IF NOT EXISTS drivers (
  id UUID PRIMARY KEY,
  full_name TEXT NOT NULL,
  email TEXT NOT NULL,
  phone TEXT,
  driver_license TEXT,
  license_expiry DATE,
  driver_id TEXT UNIQUE NOT NULL,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);
```

## Quick Fix Checklist

- [ ] **RLS Policies**: Applied proper RLS policies for users and drivers tables
- [ ] **Table Structure**: Verified tables exist with correct columns
- [ ] **Permissions**: Confirmed user has INSERT permissions
- [ ] **Field Names**: Verified field names match database schema
- [ ] **Required Fields**: Ensured all required fields are provided
- [ ] **Test Insert**: Successfully inserted test record manually

## If Still Not Working

1. **Check Supabase Logs**: Go to Supabase Dashboard → Logs → Database logs
2. **Enable Debug Mode**: Add more debug prints to the code
3. **Test with Admin Panel**: Try creating a driver through the admin panel first
4. **Check Network**: Ensure the app has proper internet connection
5. **Verify Supabase Config**: Check if Supabase URL and keys are correct

## Emergency Fix

If nothing else works, temporarily disable RLS to test:

```sql
-- TEMPORARY: Disable RLS for testing (remember to re-enable later)
ALTER TABLE users DISABLE ROW LEVEL SECURITY;
ALTER TABLE drivers DISABLE ROW LEVEL SECURITY;

-- Test signup again
-- If it works, the issue is with RLS policies
-- If it doesn't work, the issue is elsewhere

-- Re-enable RLS after testing
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE drivers ENABLE ROW LEVEL SECURITY;
```

## Contact Support

If you're still having issues after trying these steps:

1. **Collect Debug Info**: Save all console logs and error messages
2. **Database State**: Note the current state of your tables and policies
3. **Steps Taken**: Document what you've tried so far
4. **Environment**: Note your Supabase project details and app version

This will help provide more targeted assistance. 