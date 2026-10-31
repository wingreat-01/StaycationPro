-- StaycationPro database schema.
-- Run this once in the Supabase dashboard: SQL Editor -> New query -> paste -> Run.

create extension if not exists btree_gist;

-- ---------------------------------------------------------------------------
-- Tables
-- ---------------------------------------------------------------------------

create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  full_name text not null default '',
  phone text,
  role text not null default 'guest' check (role in ('guest', 'owner')),
  created_at timestamptz not null default now()
);

create table public.listings (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references public.profiles (id) on delete cascade,
  title text not null,
  description text not null default '',
  location text not null,
  price_per_night numeric(10, 2) not null check (price_per_night >= 0),
  max_guests int not null default 2 check (max_guests > 0),
  image_url text,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

create table public.bookings (
  id uuid primary key default gen_random_uuid(),
  listing_id uuid not null references public.listings (id) on delete cascade,
  guest_id uuid not null references public.profiles (id) on delete cascade,
  check_in date not null,
  check_out date not null,
  guests int not null default 1 check (guests > 0),
  total_price numeric(10, 2) not null default 0,
  status text not null default 'pending'
    check (status in ('pending', 'accepted', 'declined', 'cancelled')),
  note text,
  created_at timestamptz not null default now(),
  check (check_out > check_in),
  -- Two accepted bookings for the same listing can never overlap.
  -- '[)' leaves the check-out day free for the next guest's check-in.
  constraint no_double_booking exclude using gist (
    listing_id with =,
    daterange(check_in, check_out, '[)') with &&
  ) where (status = 'accepted')
);

create index on public.listings (owner_id);
create index on public.bookings (listing_id);
create index on public.bookings (guest_id);

-- ---------------------------------------------------------------------------
-- Create a profile automatically when someone signs up.
-- The app passes full_name, phone and role as sign-up metadata.
-- ---------------------------------------------------------------------------

create function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles (id, full_name, phone, role)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'full_name', ''),
    new.raw_user_meta_data ->> 'phone',
    case when new.raw_user_meta_data ->> 'role' = 'owner' then 'owner' else 'guest' end
  );
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ---------------------------------------------------------------------------
-- Validate new booking requests and compute the price server-side,
-- so the app can't send a fake total or status.
-- ---------------------------------------------------------------------------

create function public.prepare_booking()
returns trigger
language plpgsql
security definer set search_path = public
as $$
declare
  l public.listings;
begin
  select * into l from public.listings where id = new.listing_id;
  if not found or not l.is_active then
    raise exception 'This staycation is not available.';
  end if;
  if l.owner_id = new.guest_id then
    raise exception 'You cannot book your own listing.';
  end if;
  if new.guests > l.max_guests then
    raise exception 'This place allows up to % guests.', l.max_guests;
  end if;
  if new.check_in < current_date then
    raise exception 'Check-in date is in the past.';
  end if;
  if exists (
    select 1 from public.bookings b
    where b.listing_id = new.listing_id
      and b.status = 'accepted'
      and daterange(b.check_in, b.check_out, '[)') && daterange(new.check_in, new.check_out, '[)')
  ) then
    raise exception 'Those dates are already booked.';
  end if;

  new.status := 'pending';
  new.total_price := l.price_per_night * (new.check_out - new.check_in);
  return new;
end;
$$;

create trigger before_booking_insert
  before insert on public.bookings
  for each row execute function public.prepare_booking();

-- ---------------------------------------------------------------------------
-- Actions (the only way booking status changes)
-- ---------------------------------------------------------------------------

-- Owner accepts or declines a pending request. Accepting also declines any
-- other pending requests for overlapping dates.
create function public.respond_to_booking(p_booking_id uuid, p_accept boolean)
returns void
language plpgsql
security definer set search_path = public
as $$
declare
  b public.bookings;
begin
  select bk.* into b
  from public.bookings bk
  join public.listings l on l.id = bk.listing_id
  where bk.id = p_booking_id and l.owner_id = auth.uid()
  for update of bk;

  if not found then
    raise exception 'Booking not found.';
  end if;
  if b.status <> 'pending' then
    raise exception 'This booking was already %.', b.status;
  end if;

  if p_accept then
    begin
      update public.bookings set status = 'accepted' where id = b.id;
    exception when exclusion_violation then
      raise exception 'These dates overlap another accepted booking.';
    end;
    update public.bookings
    set status = 'declined'
    where listing_id = b.listing_id
      and status = 'pending'
      and id <> b.id
      and daterange(check_in, check_out, '[)') && daterange(b.check_in, b.check_out, '[)');
  else
    update public.bookings set status = 'declined' where id = b.id;
  end if;
end;
$$;

-- Guest cancels their own booking before the check-in day.
create function public.cancel_booking(p_booking_id uuid)
returns void
language plpgsql
security definer set search_path = public
as $$
begin
  update public.bookings
  set status = 'cancelled'
  where id = p_booking_id
    and guest_id = auth.uid()
    and status in ('pending', 'accepted')
    and check_in > current_date;

  if not found then
    raise exception 'This booking can no longer be cancelled.';
  end if;
end;
$$;

-- Accepted date ranges for a listing, so guests can see what's taken
-- without being able to read other guests' bookings.
create function public.listing_booked_ranges(p_listing_id uuid)
returns table (check_in date, check_out date)
language sql
stable
security definer set search_path = public
as $$
  select b.check_in, b.check_out
  from public.bookings b
  where b.listing_id = p_listing_id
    and b.status = 'accepted'
    and b.check_out > current_date
  order by b.check_in;
$$;

revoke execute on function public.respond_to_booking(uuid, boolean) from public, anon;
revoke execute on function public.cancel_booking(uuid) from public, anon;
revoke execute on function public.listing_booked_ranges(uuid) from public, anon;
grant execute on function public.respond_to_booking(uuid, boolean) to authenticated;
grant execute on function public.cancel_booking(uuid) to authenticated;
grant execute on function public.listing_booked_ranges(uuid) to authenticated;

-- ---------------------------------------------------------------------------
-- Row level security
-- ---------------------------------------------------------------------------

alter table public.profiles enable row level security;
alter table public.listings enable row level security;
alter table public.bookings enable row level security;

-- Profiles: you can read your own, plus the guest/owner on the other side
-- of a booking you're part of (so owners see the guest's name and phone).
create policy "Read own or booking-related profiles" on public.profiles
  for select to authenticated
  using (
    id = auth.uid()
    or exists (
      select 1 from public.bookings b
      join public.listings l on l.id = b.listing_id
      where (b.guest_id = profiles.id and l.owner_id = auth.uid())
         or (l.owner_id = profiles.id and b.guest_id = auth.uid())
    )
  );

create policy "Update own profile" on public.profiles
  for update to authenticated
  using (id = auth.uid());

-- Only name and phone are editable; role is fixed at sign-up.
revoke update on public.profiles from authenticated;
grant update (full_name, phone) on public.profiles to authenticated;

-- Listings: everyone signed in sees active listings; owners see all of theirs.
create policy "Read active or own listings" on public.listings
  for select to authenticated
  using (is_active or owner_id = auth.uid());

create policy "Owners create listings" on public.listings
  for insert to authenticated
  with check (
    owner_id = auth.uid()
    and exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'owner')
  );

create policy "Owners update own listings" on public.listings
  for update to authenticated
  using (owner_id = auth.uid())
  with check (owner_id = auth.uid());

create policy "Owners delete own listings" on public.listings
  for delete to authenticated
  using (owner_id = auth.uid());

-- Bookings: guests see their own; owners see bookings for their listings.
-- Status changes go through the functions above, so there's no update policy.
create policy "Read own or owned-listing bookings" on public.bookings
  for select to authenticated
  using (
    guest_id = auth.uid()
    or exists (select 1 from public.listings l where l.id = listing_id and l.owner_id = auth.uid())
  );

create policy "Guests request bookings" on public.bookings
  for insert to authenticated
  with check (guest_id = auth.uid());

-- Live updates so owners see new requests without refreshing.
alter publication supabase_realtime add table public.bookings;
