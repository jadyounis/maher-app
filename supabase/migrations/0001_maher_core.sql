-- MAHER core database schema
-- Apply with Supabase migrations before production use.

create extension if not exists pgcrypto;

create type public.user_role as enum ('customer','professional','admin');
create type public.pricing_mode as enum ('hourly','daily','contract');
create type public.request_status as enum ('draft','published','offers_received','professional_selected','scheduled','en_route','arrived','in_progress','completed','cancelled','paid','reviewed');
create type public.offer_status as enum ('pending','accepted','rejected','withdrawn','expired');
create type public.moderation_action_type as enum ('note','warning','penalty','temporary_ban','permanent_ban','unban');

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  role public.user_role not null default 'customer',
  full_name text,
  phone text,
  email text,
  avatar_url text,
  city text default 'Amman',
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.professional_profiles (
  user_id uuid primary key references public.profiles(id) on delete cascade,
  bio text,
  skills text[] not null default '{}',
  service_areas text[] not null default '{Amman}',
  verification_status text not null default 'pending',
  identity_document_url text,
  rating numeric(3,2) not null default 0,
  completed_jobs integer not null default 0,
  portfolio_count integer not null default 0,
  is_available boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.service_categories (
  id uuid primary key default gen_random_uuid(),
  name_ar text not null,
  name_en text not null,
  icon text,
  is_active boolean not null default true,
  sort_order integer not null default 0,
  created_at timestamptz not null default now()
);

create table public.requests (
  id uuid primary key default gen_random_uuid(),
  customer_id uuid not null references public.profiles(id),
  category_id uuid references public.service_categories(id),
  pricing_mode public.pricing_mode not null,
  title text not null,
  description text,
  media_urls text[] not null default '{}',
  address_text text,
  latitude double precision,
  longitude double precision,
  scheduled_at timestamptz,
  hourly_rate numeric(10,2),
  daily_rate numeric(10,2),
  budget_min numeric(10,2),
  budget_max numeric(10,2),
  status public.request_status not null default 'draft',
  selected_professional_id uuid references public.profiles(id),
  accepted_offer_id uuid,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.offers (
  id uuid primary key default gen_random_uuid(),
  request_id uuid not null references public.requests(id) on delete cascade,
  professional_id uuid not null references public.profiles(id),
  price numeric(10,2) not null check (price >= 0),
  estimated_duration_minutes integer,
  note text,
  status public.offer_status not null default 'pending',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (request_id, professional_id)
);

alter table public.requests
  add constraint requests_accepted_offer_fk
  foreign key (accepted_offer_id) references public.offers(id);

create table public.jobs (
  id uuid primary key default gen_random_uuid(),
  request_id uuid not null unique references public.requests(id) on delete cascade,
  customer_id uuid not null references public.profiles(id),
  professional_id uuid not null references public.profiles(id),
  agreed_amount numeric(10,2) not null,
  pricing_mode public.pricing_mode not null,
  started_at timestamptz,
  arrived_at timestamptz,
  completed_at timestamptz,
  paid_at timestamptz,
  created_at timestamptz not null default now()
);

create table public.job_status_events (
  id uuid primary key default gen_random_uuid(),
  job_id uuid not null references public.jobs(id) on delete cascade,
  status public.request_status not null,
  actor_id uuid references public.profiles(id),
  note text,
  created_at timestamptz not null default now()
);

create table public.platform_settings (
  key text primary key,
  value_numeric numeric(10,4),
  value_text text,
  value_boolean boolean,
  updated_at timestamptz not null default now()
);

insert into public.platform_settings(key, value_numeric, value_text)
values
  ('commission_rate_percent', 30, '30% platform commission'),
  ('default_hourly_price', 10, 'Default example hourly price in JOD'),
  ('default_daily_price', 50, 'Default example daily price in JOD')
on conflict (key) do nothing;

create table public.transactions (
  id uuid primary key default gen_random_uuid(),
  job_id uuid not null references public.jobs(id) on delete cascade,
  gross_amount numeric(10,2) not null,
  commission_rate numeric(6,3) not null,
  commission_amount numeric(10,2) not null,
  professional_amount numeric(10,2) not null,
  currency text not null default 'JOD',
  payment_status text not null default 'pending',
  created_at timestamptz not null default now()
);

create table public.reviews (
  id uuid primary key default gen_random_uuid(),
  job_id uuid not null references public.jobs(id) on delete cascade,
  reviewer_id uuid not null references public.profiles(id),
  reviewee_id uuid not null references public.profiles(id),
  rating integer not null check (rating between 1 and 5),
  comment text,
  created_at timestamptz not null default now(),
  unique(job_id, reviewer_id)
);

create table public.reports (
  id uuid primary key default gen_random_uuid(),
  reporter_id uuid not null references public.profiles(id),
  reported_user_id uuid not null references public.profiles(id),
  job_id uuid references public.jobs(id),
  reason text not null,
  details text,
  status text not null default 'open',
  resolution text,
  resolved_by uuid references public.profiles(id),
  resolved_at timestamptz,
  created_at timestamptz not null default now()
);

create table public.moderation_actions (
  id uuid primary key default gen_random_uuid(),
  target_user_id uuid not null references public.profiles(id),
  admin_id uuid not null references public.profiles(id),
  action_type public.moderation_action_type not null,
  reason text,
  expires_at timestamptz,
  amount numeric(10,2),
  created_at timestamptz not null default now()
);

create table public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  title text not null,
  body text not null,
  data jsonb not null default '{}',
  read_at timestamptz,
  created_at timestamptz not null default now()
);

create index requests_customer_idx on public.requests(customer_id, created_at desc);
create index requests_status_idx on public.requests(status, created_at desc);
create index requests_location_idx on public.requests(latitude, longitude);
create index offers_request_idx on public.offers(request_id, status, created_at desc);
create index offers_professional_idx on public.offers(professional_id, created_at desc);
create index reports_target_idx on public.reports(reported_user_id, created_at desc);
create index notifications_user_idx on public.notifications(user_id, created_at desc);

create or replace function public.calculate_commission(gross numeric, rate numeric default null)
returns table (gross_amount numeric, commission_rate numeric, commission_amount numeric, professional_amount numeric)
language plpgsql
as $$
declare
  effective_rate numeric;
begin
  select coalesce(rate, value_numeric) into effective_rate
  from public.platform_settings
  where key = 'commission_rate_percent';
  effective_rate := coalesce(effective_rate, 30);
  return query
  select round(gross,2), effective_rate, round(gross * effective_rate / 100, 2), round(gross - (gross * effective_rate / 100), 2);
end;
$$;

create or replace function public.accept_offer(p_offer_id uuid)
returns uuid
language plpgsql
security definer
as $$
declare
  v_request_id uuid;
  v_customer uuid;
  v_professional uuid;
  v_price numeric;
  v_mode public.pricing_mode;
  v_job_id uuid;
begin
  select o.request_id, o.professional_id, o.price, r.customer_id, r.pricing_mode
    into v_request_id, v_professional, v_price, v_customer, v_mode
  from public.offers o join public.requests r on r.id=o.request_id
  where o.id=p_offer_id and o.status='pending' and r.status in ('published','offers_received');
  if v_request_id is null then raise exception 'Offer is not available'; end if;

  update public.offers set status = case when id=p_offer_id then 'accepted' else 'rejected' end, updated_at=now()
  where request_id=v_request_id and status='pending';

  update public.requests set status='professional_selected', selected_professional_id=v_professional, accepted_offer_id=p_offer_id, updated_at=now()
  where id=v_request_id;

  insert into public.jobs(request_id, customer_id, professional_id, agreed_amount, pricing_mode)
  values(v_request_id, v_customer, v_professional, v_price, v_mode)
  returning id into v_job_id;

  insert into public.job_status_events(job_id,status,actor_id) values(v_job_id,'professional_selected',auth.uid());
  return v_job_id;
end;
$$;

alter table public.profiles enable row level security;
alter table public.professional_profiles enable row level security;
alter table public.service_categories enable row level security;
alter table public.requests enable row level security;
alter table public.offers enable row level security;
alter table public.jobs enable row level security;
alter table public.job_status_events enable row level security;
alter table public.platform_settings enable row level security;
alter table public.transactions enable row level security;
alter table public.reviews enable row level security;
alter table public.reports enable row level security;
alter table public.moderation_actions enable row level security;
alter table public.notifications enable row level security;

create policy "profiles own or visible" on public.profiles for select using (id=auth.uid() or true);
create policy "profiles update own" on public.profiles for update using (id=auth.uid()) with check (id=auth.uid());
create policy "service categories public read" on public.service_categories for select using (is_active=true);
create policy "professional profiles public read" on public.professional_profiles for select using (true);
create policy "requests customer own" on public.requests for select using (customer_id=auth.uid() or selected_professional_id=auth.uid());
create policy "requests customer insert" on public.requests for insert with check (customer_id=auth.uid());
create policy "requests customer update" on public.requests for update using (customer_id=auth.uid()) with check (customer_id=auth.uid());
create policy "offers professional insert" on public.offers for insert with check (professional_id=auth.uid());
create policy "offers customer/professional read" on public.offers for select using (professional_id=auth.uid() or exists (select 1 from public.requests r where r.id=request_id and r.customer_id=auth.uid()));
create policy "offers professional update" on public.offers for update using (professional_id=auth.uid()) with check (professional_id=auth.uid());
create policy "jobs participants read" on public.jobs for select using (customer_id=auth.uid() or professional_id=auth.uid());
create policy "job events participants read" on public.job_status_events for select using (exists(select 1 from public.jobs j where j.id=job_id and (j.customer_id=auth.uid() or j.professional_id=auth.uid())));
create policy "reviews participants read" on public.reviews for select using (true);
create policy "reviews reviewer insert" on public.reviews for insert with check (reviewer_id=auth.uid());
create policy "reports reporter insert" on public.reports for insert with check (reporter_id=auth.uid());
create policy "notifications own" on public.notifications for select using (user_id=auth.uid());
create policy "notifications update own" on public.notifications for update using (user_id=auth.uid()) with check (user_id=auth.uid());

-- Admin policies are intentionally role-based and should be tightened to a separate admin claim/RBAC function in production.
