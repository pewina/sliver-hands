-- SilverHands: basic member details
-- Stores the member's age after authentication. Name uses profiles.display_name.

alter table public.profiles
  add column if not exists age integer;

alter table public.profiles
  drop constraint if exists profiles_age_check;

alter table public.profiles
  add constraint profiles_age_check check (age is null or (age >= 18 and age <= 120));
