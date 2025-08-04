-- Auto-confirm all new users immediately upon creation
-- This is useful for development and testing environments
-- Note: This migration addresses the fact that confirmed_at is a generated column
-- that cannot be directly updated. The proper approach is configuration-based.

-- For auto-confirmation in development, the recommended approach is to:
-- 1. Set GOTRUE_MAILER_AUTOCONFIRM=true in your Supabase configuration
-- 2. Or disable email confirmation in the Supabase Dashboard under Authentication > Settings

-- Since we cannot directly modify confirmed_at, we'll create a helper function
-- that can be used by the application to check if auto-confirmation is enabled
create or replace function is_auto_confirm_enabled()
returns boolean as $$
begin
  -- This can be used by your application logic to determine
  -- if users should be treated as automatically confirmed
  -- You can modify this logic based on your environment needs
  return true; -- Set to true for development, false for production
end;
$$ language plpgsql;

-- Create a view that shows user confirmation status including auto-confirmation
create or replace view public.user_confirmation_status as
select 
  id,
  email,
  confirmed_at,
  case 
    when confirmed_at is not null then true
    when is_auto_confirm_enabled() then true
    else false
  end as is_confirmed,
  case
    when confirmed_at is not null then 'email_confirmed'
    when is_auto_confirm_enabled() then 'auto_confirmed'
    else 'pending_confirmation'
  end as confirmation_method
from auth.users;