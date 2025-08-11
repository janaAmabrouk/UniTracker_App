# Profile Image Upload Setup Guide

## Overview
This guide explains how to set up and use the profile image upload functionality in the UniTracker app.

## Prerequisites
1. Supabase project with storage enabled
2. Proper storage bucket configuration
3. Correct RLS (Row Level Security) policies

## Storage Bucket Setup

### 1. Create the Storage Bucket
In your Supabase dashboard, go to Storage and create a new bucket called `profile-images`:

```sql
-- Create the storage bucket (if not exists)
-- This is done through the Supabase dashboard UI
-- Bucket name: profile-images
-- Public bucket: true
```

### 2. Set Up RLS Policies
Create the following RLS policies for the `profile-images` bucket:

```sql
-- Policy for inserting profile images (users can upload their own images)
CREATE POLICY "Users can upload their own profile images" ON storage.objects
FOR INSERT WITH CHECK (
  bucket_id = 'profile-images' AND
  auth.uid()::text = (storage.foldername(name))[1]
);

-- Policy for viewing profile images (public read access)
CREATE POLICY "Profile images are publicly viewable" ON storage.objects
FOR SELECT USING (bucket_id = 'profile-images');

-- Policy for updating profile images (users can update their own images)
CREATE POLICY "Users can update their own profile images" ON storage.objects
FOR UPDATE USING (
  bucket_id = 'profile-images' AND
  auth.uid()::text = (storage.foldername(name))[1]
);

-- Policy for deleting profile images (users can delete their own images)
CREATE POLICY "Users can delete their own profile images" ON storage.objects
FOR DELETE USING (
  bucket_id = 'profile-images' AND
  auth.uid()::text = (storage.foldername(name))[1]
);
```

### 3. Database Schema
Ensure your `users` table has the `profile_image_url` column:

```sql
-- Add profile_image_url column if it doesn't exist
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS profile_image_url TEXT;

-- Add index for better performance
CREATE INDEX IF NOT EXISTS idx_users_profile_image_url 
ON users(profile_image_url);
```

## Usage

### For Students
1. Navigate to the Profile screen
2. Tap the camera icon on the profile image
3. Choose between Camera or Gallery
4. The image will be automatically uploaded and displayed

### For Drivers
1. Navigate to the Driver Profile screen
2. Tap the edit icon on the profile image
3. Choose between Camera or Gallery
4. The image will be automatically uploaded and displayed

## Troubleshooting

### Common Issues

1. **"Permission denied" error**
   - Check that RLS policies are correctly set up
   - Verify the user is authenticated
   - Ensure the storage bucket exists

2. **"Image file does not exist" error**
   - Check file permissions on the device
   - Verify the image picker is working correctly

3. **"Failed to upload profile image" error**
   - Check network connectivity
   - Verify Supabase configuration
   - Check storage bucket permissions

### Debug Information
The app includes detailed debug logging. Check the console output for:
- `📸 AuthService: Starting profile image upload for user: [userId]`
- `📸 AuthService: Uploading to path: [path]`
- `📸 AuthService: File uploaded successfully to: [response]`
- `📸 AuthService: Generated public URL: [url]`

## File Structure
- Images are stored with the format: `{userId}.{extension}`
- Example: `123e4567-e89b-12d3-a456-426614174000.jpg`

## Security Considerations
- Only authenticated users can upload images
- Users can only upload/update/delete their own images
- Profile images are publicly viewable
- File size and type validation should be implemented

## Performance Optimization
- Images are compressed before upload
- Caching is implemented for better performance
- Error handling includes fallback to default avatar 