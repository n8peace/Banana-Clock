-- Auto-confirm all new users immediately upon creation
-- This is useful for development and testing environments

create or replace function confirm_users()
returns trigger as $$
begin
  update auth.users
  set confirmed_at = now()
  where id = new.id;
  return new;
end;
$$ language plpgsql security definer;

create trigger set_user_confirmed
after insert on auth.users
for each row
execute function confirm_users();

-- One-time update to confirm all existing unconfirmed users
update auth.users
set confirmed_at = now()
where confirmed_at is null;