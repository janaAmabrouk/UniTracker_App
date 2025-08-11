# Database Setup Fix for Driver Signup Issues

## Problem Description
When drivers sign up through the mobile app, their data is not being saved to the database tables (`users` and `drivers`). This is likely due to Row Level Security (RLS) policies or missing database permissions.

## Root Cause Analysis
The issue is most likely one of the following:

1. **Row Level Security (RLS) Policies** - New users don't have permission to insert into tables
2. **Missing Database Permissions** - The service role or anon role lacks proper permissions
3. **Field Name Mismatches** - Database schema doesn't match the code expectations
4. **Missing Required Fields** - Some required fields are not being provided

## Solution Steps

### 1. Check and Fix RLS Policies

Run these SQL commands in your Supabase SQL Editor:

```sql
-- Check current RLS policies
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual 
FROM pg_policies 
WHERE tablename IN ('users', 'drivers');

-- Enable RLS on tables if not already enabled
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE drivers ENABLE ROW LEVEL SECURITY;

-- Drop existing policies that might be blocking inserts
DROP POLICY IF EXISTS "Users can insert their own profile" ON users;
DROP POLICY IF EXISTS "Drivers can insert their own record" ON drivers;

-- Create new policies that allow authenticated users to insert their own data
CREATE POLICY "Users can insert their own profile" ON users
  FOR INSERT WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can view their own profile" ON users
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update their own profile" ON users
  FOR UPDATE USING (auth.uid() = id);

-- For drivers table, allow authenticated users to insert their own record
CREATE POLICY "Drivers can insert their own record" ON drivers
  FOR INSERT WITH CHECK (auth.uid() = id);

CREATE POLICY "Drivers can view their own record" ON drivers
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Drivers can update their own record" ON drivers
  FOR UPDATE USING (auth.uid() = id);

-- Allow service role to manage all records (for admin operations)
CREATE POLICY "Service role can manage all users" ON users
  FOR ALL USING (auth.role() = 'service_role');

CREATE POLICY "Service role can manage all drivers" ON drivers
  FOR ALL USING (auth.role() = 'service_role');
```

### 2. Verify Table Structure

Run this to check the actual table structure:

```sql
-- Check users table structure
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns
WHERE table_name = 'users'
ORDER BY ordinal_position;

-- Check drivers table structure
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns
WHERE table_name = 'drivers'
ORDER BY ordinal_position;
```

### 3. Create Missing Tables (if needed)

If the tables don't exist, create them:

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

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_driver_id ON users(driver_id);
CREATE INDEX IF NOT EXISTS idx_drivers_driver_id ON drivers(driver_id);
CREATE INDEX IF NOT EXISTS idx_drivers_email ON drivers(email);
```

### 4. Test Database Connection

Add this function to test database connectivity:

```sql
-- Create a function to test database connectivity
CREATE OR REPLACE FUNCTION test_database_connection()
RETURNS JSON AS $$
BEGIN
  RETURN json_build_object(
    'status', 'success',
    'message', 'Database connection is working',
    'timestamp', NOW()
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

### 5. Debug Insertion Issues

Create a function to debug insertion issues:

```sql
-- Function to debug insertion issues
CREATE OR REPLACE FUNCTION debug_insert_user(
  user_id UUID,
  user_email TEXT,
  user_full_name TEXT,
  user_role TEXT,
  driver_license TEXT DEFAULT NULL,
  license_expiry DATE DEFAULT NULL,
  driver_id TEXT DEFAULT NULL
)
RETURNS JSON AS $$
DECLARE
  result JSON;
BEGIN
  -- Try to insert into users table
  INSERT INTO users (
    id, email, full_name, role, driver_license, license_expiry, driver_id, is_active
  ) VALUES (
    user_id, user_email, user_full_name, user_role, driver_license, license_expiry, driver_id, true
  );
  
  -- Return success
  result := json_build_object(
    'status', 'success',
    'message', 'User inserted successfully',
    'user_id', user_id
  );
  
  RETURN result;
  
EXCEPTION WHEN OTHERS THEN
  -- Return error details
  result := json_build_object(
    'status', 'error',
    'message', SQLERRM,
    'sqlstate', SQLSTATE,
    'user_id', user_id
  );
  
  RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

### 6. Verify Permissions

Check if the current user has proper permissions:

```sql
-- Check current user permissions
SELECT 
  current_user,
  session_user,
  current_database(),
  current_schema();

-- Check if user can insert into tables
SELECT has_table_privilege(current_user, 'users', 'INSERT') as can_insert_users;
SELECT has_table_privilege(current_user, 'drivers', 'INSERT') as can_insert_drivers;
```

## Testing the Fix

After applying the fixes:

1. **Test with a new driver signup** - Try signing up a new driver
2. **Check the logs** - Look for the debug messages in the console
3. **Verify data in database** - Check if records appear in both tables
4. **Test admin panel** - Verify that admins can see the new driver

## Common Error Messages and Solutions

### "new row violates row-level security policy"
- **Solution**: Apply the RLS policies from step 1

### "column does not exist"
- **Solution**: Check table structure and fix field names

### "permission denied"
- **Solution**: Check user permissions and RLS policies

### "null value in column violates not-null constraint"
- **Solution**: Ensure all required fields are provided

## Monitoring and Debugging

Add these debug statements to your code to monitor the signup process:

```dart
// In AuthService.signUpDriver()
debugPrint('🔥 AuthService: Starting driver signup...');
debugPrint('🔥 AuthService: Driver ID: $driverId');
debugPrint('🔥 AuthService: License Number: $licenseNumber');
debugPrint('🔥 AuthService: License Expiry: ${licenseExpirationDate.toIso8601String()}');

// After each database operation
debugPrint('✅ AuthService: Database operation completed successfully');
```

## Next Steps

1. Apply the database fixes
2. Test the signup process
3. Monitor the debug logs
4. Verify data appears in both tables
5. Test the admin panel integration

If issues persist, check the Supabase logs for more detailed error information. 