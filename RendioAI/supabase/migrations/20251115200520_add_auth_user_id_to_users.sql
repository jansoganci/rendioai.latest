-- Add auth_user_id to users table to link custom user records with Supabase auth
-- This enables proper Storage RLS policies while maintaining backward compatibility

-- Add the auth_user_id column
ALTER TABLE public.users
ADD COLUMN IF NOT EXISTS auth_user_id UUID REFERENCES auth.users(id);

-- Create index for efficient lookups
CREATE INDEX IF NOT EXISTS idx_users_auth_user_id
ON public.users(auth_user_id);

-- Add comment explaining the column
COMMENT ON COLUMN public.users.auth_user_id IS
'Links custom user record to Supabase auth.users for Storage RLS. Set when user authenticates via anonymous auth or Apple Sign-In.';

-- Update RLS policy to allow users to read their own records via auth_user_id
CREATE POLICY "Users can read own record via auth"
ON public.users
FOR SELECT
USING (auth_user_id = auth.uid());

-- Update RLS policy to allow users to update their own records via auth_user_id
CREATE POLICY "Users can update own record via auth"
ON public.users
FOR UPDATE
USING (auth_user_id = auth.uid());

-- Note: We keep existing policies for backward compatibility with device_id
-- The device-check endpoint will be updated to create auth sessions and link them