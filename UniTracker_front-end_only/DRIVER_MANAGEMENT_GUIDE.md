# UniTracker Driver Management System

## Overview

The UniTracker driver management system now supports two ways for drivers to join the platform:

1. **Self-Signup**: Drivers can register themselves through the mobile app
2. **Admin-Created**: Admins can create driver accounts through the admin panel

## Driver Account Creation Flow

### Method 1: Self-Signup (Driver Registration)

**Process:**
1. Driver downloads the UniTracker mobile app
2. Selects "Driver" role during signup
3. Fills out the signup form with:
   - Full name
   - Driver ID (unique identifier)
   - License number
   - License expiration date
   - License image upload
   - Password
4. System automatically creates:
   - Supabase Auth account with email: `{driverId}@unitracker.driver`
   - User profile in the `users` table
   - Driver record in the `drivers` table

**Code Location:** `unitracker/lib/screens/auth/signup_screen.dart`

### Method 2: Admin-Created Accounts

**Process:**
1. Admin logs into the admin panel
2. Navigates to Drivers section
3. Clicks "Add Driver" button
4. Fills out driver information:
   - Full name
   - Email address
   - Phone number
   - License number
   - License expiration date
   - Status (active/inactive)
5. System automatically:
   - Generates a unique Driver ID
   - Creates driver record in `drivers` table
   - Creates user profile in `users` table
   - Sends welcome email with setup instructions

**Code Location:** `admin_web/lib/admin/services/admin_data_service.dart`

## Data Flow and Storage

### For Self-Signup Drivers:

1. **Supabase Auth Account:**
   - Email: `{driverId}@unitracker.driver`
   - Password: User-provided password
   - Role: "driver"

2. **Users Table:**
   - ID: Auth user ID
   - Email: Generated driver email
   - Full name: Driver's name
   - Role: "driver"
   - Driver license: License number
   - License expiry: Expiration date
   - Is active: true
   - Driver ID: User-provided driver ID

3. **Drivers Table:**
   - ID: Same as Auth user ID
   - Full name: Driver's name
   - Email: Generated driver email
   - Driver license: License number
   - License expiry: Expiration date
   - Driver ID: User-provided driver ID
   - Is active: true

### For Admin-Created Drivers:

1. **Drivers Table:**
   - ID: Auto-generated UUID
   - Full name: Driver's name
   - Email: Admin-provided email
   - Phone: Phone number
   - Driver license: License number
   - License expiry: Expiration date
   - Driver ID: Auto-generated (format: DR{initials}{timestamp})
   - Is active: Status from admin

2. **Users Table:**
   - ID: Same as driver record ID
   - Email: Admin-provided email
   - Full name: Driver's name
   - Role: "driver"
   - Driver license: License number
   - License expiry: Expiration date
   - Is active: Status from admin
   - Phone number: Admin-provided phone
   - Driver ID: Auto-generated driver ID

## Account Linking Process

When an admin-created driver tries to sign up in the mobile app:

1. **System checks** if driver ID already exists in `drivers` table
2. **If found:**
   - Creates Supabase Auth account
   - Links existing driver record to new auth account
   - Updates driver record with auth user ID
   - Creates user profile linking to existing data
3. **If not found:**
   - Proceeds with normal self-signup flow

**Code Location:** `unitracker/lib/services/auth_service.dart` - `signUpDriver` method

## Login Process

### For Self-Signup Drivers:
- **Login with:** Driver ID (converted to email format)
- **Password:** Their chosen password
- **System:** Converts driver ID to `{driverId}@unitracker.driver` for authentication

### For Admin-Created Drivers:
- **Login with:** Driver ID (converted to email format)
- **Password:** Password they set during signup
- **System:** Converts driver ID to `{driverId}@unitracker.driver` for authentication

## Email Notifications

### Welcome Email for Admin-Created Drivers:
- Sent automatically when admin creates driver account
- Contains:
  - Driver ID
  - Setup instructions
  - Link to download mobile app
  - Step-by-step signup process

**Code Location:** `admin_web/lib/admin/services/email_service.dart`

## Admin Panel Features

### Driver Management:
- View all drivers (both self-signup and admin-created)
- Edit driver information
- Activate/deactivate drivers
- Assign drivers to buses and routes
- View driver statistics and performance

### Driver Creation:
- Add new drivers with all required information
- Automatic Driver ID generation
- Email notification system
- Status management

## Error Handling

### Duplicate Driver Accounts:
- System detects if driver ID already exists
- Shows user-friendly dialog
- Redirects to login screen
- Prevents duplicate account creation

### Missing Information:
- Validates all required fields
- Shows specific error messages
- Prevents incomplete account creation

## Security Features

### Password Management:
- Drivers create their own passwords
- No temporary passwords sent via email
- Secure password validation
- Password reset functionality

### Data Validation:
- Email format validation
- Driver ID uniqueness check
- License information validation
- Phone number format validation

## Future Enhancements

### Planned Features:
1. **Email Service Integration:**
   - SendGrid or AWS SES integration
   - HTML email templates
   - Email tracking and delivery confirmation

2. **Bulk Driver Import:**
   - CSV file upload for multiple drivers
   - Batch processing
   - Error reporting

3. **Driver Onboarding:**
   - Multi-step onboarding process
   - Document upload (license, ID, etc.)
   - Background check integration

4. **Advanced Notifications:**
   - SMS notifications
   - Push notifications
   - In-app notifications

## Technical Implementation

### Database Schema:
```sql
-- Drivers table
CREATE TABLE drivers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
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

-- Users table
CREATE TABLE users (
  id UUID PRIMARY KEY,
  email TEXT NOT NULL,
  full_name TEXT NOT NULL,
  role TEXT NOT NULL,
  driver_license TEXT,
  license_expiry DATE,
  is_active BOOLEAN DEFAULT true,
  phone_number TEXT,
  driver_id TEXT,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);
```

### Key Methods:
- `AdminDataService.createDriver()` - Admin driver creation
- `AuthService.signUpDriver()` - Self-signup and account linking
- `EmailService.sendWelcomeEmail()` - Email notifications
- `SignupScreen._signup()` - Mobile app signup handling

## Troubleshooting

### Common Issues:

1. **Driver ID Already Exists:**
   - Check if driver was created by admin
   - Guide user to login instead of signup
   - Verify driver ID format

2. **Email Not Received:**
   - Check spam folder
   - Verify email address format
   - Check email service logs

3. **Login Issues:**
   - Verify driver ID format
   - Check if account is active
   - Confirm password is correct

4. **Data Sync Issues:**
   - Check database connectivity
   - Verify user permissions
   - Check for data consistency

## Support

For technical support or questions about the driver management system, please contact the development team or refer to the code documentation in the respective service files. 