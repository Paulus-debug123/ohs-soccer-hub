-- OHS SOCCER HUB DATABASE
create extension if not exists pgcrypto;

create type public.user_role as enum ('player','admin');
create type public.match_status as enum ('scheduled','live','finished','postponed');
create type public.transfer_status as enum ('pending','completed','cancelled');
create type public.tournament_type as enum ('league','cup','shield');

create table if not exists public.seasons (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  is_current boolean default false,
  created_at timestamptz default now()
);

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text unique not null,
  display_name text not null,
  role public.user_role default 'player',
  created_at timestamptz default now()
);

create table if not exists public.teams (
  id uuid primary key default gen_random_uuid(),
  season_id uuid references public.seasons(id) on delete set null,
  name text not null,
  short_name text,
  primary_color text default '#16a765',
  secondary_color text default '#ffffff',
  logo_url text,
  created_at timestamptz default now()
);

create table if not exists public.players (
  id uuid primary key default gen_random_uuid(),
  user_id uuid unique references public.profiles(id) on delete set null,
  team_id uuid references public.teams(id) on delete set null,
  name text not null,
  position text not null default 'MID',
  kit_number integer,
  photo_url text,
  rating numeric(4,1) not null default 50.0,
  appearances integer default 0,
  minutes integer default 0,
  goals integer default 0,
  assists integer default 0,
  clean_sheets integer default 0,
  saves integer default 0,
  yellow_cards integer default 0,
  red_cards integer default 0,
  created_at timestamptz default now()
);

create table if not exists public.matches (
  id uuid primary key default gen_random_uuid(),
  season_id uuid references public.seasons(id) on delete cascade,
  tournament public.tournament_type not null default 'league',
  round_name text,
  home_team_id uuid references public.teams(id) on delete cascade,
  away_team_id uuid references public.teams(id) on delete cascade,
  kickoff timestamptz,
  status public.match_status default 'scheduled',
  home_score integer default 0,
  away_score integer default 0,
  created_at timestamptz default now()
);

create table if not exists public.match_events (
  id uuid primary key default gen_random_uuid(),
  match_id uuid references public.matches(id) on delete cascade,
  minute integer,
  event_type text not null check (event_type in ('goal','assist','yellow','red','save','substitution')),
  player_id uuid references public.players(id) on delete set null,
  related_player_id uuid references public.players(id) on delete set null,
  created_at timestamptz default now()
);

create table if not exists public.match_player_stats (
  id uuid primary key default gen_random_uuid(),
  match_id uuid references public.matches(id) on delete cascade,
  player_id uuid references public.players(id) on delete cascade,
  minutes integer default 0,
  rating numeric(4,1),
  goals integer default 0,
  assists integer default 0,
  clean_sheet boolean default false,
  saves integer default 0,
  yellow_cards integer default 0,
  red_cards integer default 0,
  unique(match_id, player_id)
);

create table if not exists public.transfers (
  id uuid primary key default gen_random_uuid(),
  player_id uuid references public.players(id) on delete cascade,
  from_team_id uuid references public.teams(id) on delete set null,
  to_team_id uuid references public.teams(id) on delete set null,
  fee text,
  status public.transfer_status default 'completed',
  transfer_date timestamptz default now()
);

create table if not exists public.news (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  body text not null,
  category text default 'League',
  published_at timestamptz default now(),
  expires_at timestamptz default (now() + interval '7 days')
);

create table if not exists public.tournaments (
  id uuid primary key default gen_random_uuid(),
  season_id uuid references public.seasons(id) on delete cascade,
  name text not null,
  type public.tournament_type not null,
  created_at timestamptz default now()
);

create table if not exists public.tournament_ties (
  id uuid primary key default gen_random_uuid(),
  tournament_id uuid references public.tournaments(id) on delete cascade,
  home_team_id uuid references public.teams(id) on delete cascade,
  away_team_id uuid references public.teams(id) on delete cascade,
  leg integer default 1,
  match_id uuid references public.matches(id) on delete set null
);

create table if not exists public.awards (
  id uuid primary key default gen_random_uuid(),
  season_id uuid references public.seasons(id) on delete cascade,
  award_name text not null,
  player_id uuid references public.players(id) on delete set null,
  team_id uuid references public.teams(id) on delete set null,
  value text
);

-- automatic league table
create or replace view public.league_table as
with completed as (
  select * from public.matches where status='finished' and tournament='league'
),
rows as (
  select home_team_id team_id,
    case when home_score > away_score then 1 else 0 end w,
    case when home_score = away_score then 1 else 0 end d,
    case when home_score < away_score then 1 else 0 end l,
    home_score gf, away_score ga
  from completed
  union all
  select away_team_id,
    case when away_score > home_score then 1 else 0 end,
    case when away_score = home_score then 1 else 0 end,
    case when away_score < home_score then 1 else 0 end,
    away_score, home_score
  from completed
)
select t.id team_id,t.name,
 count(r.team_id)::int played,
 coalesce(sum(r.w),0)::int wins,
 coalesce(sum(r.d),0)::int draws,
 coalesce(sum(r.l),0)::int losses,
 coalesce(sum(r.gf),0)::int goals_for,
 coalesce(sum(r.ga),0)::int goals_against,
 (coalesce(sum(r.gf),0)-coalesce(sum(r.ga),0))::int goal_difference,
 (coalesce(sum(r.w),0)*3+coalesce(sum(r.d),0))::int points
from public.teams t left join rows r on r.team_id=t.id
group by t.id,t.name;

-- rating calculation: new players start at 50.
create or replace function public.calculate_player_rating(
  p_player uuid, p_goals integer, p_assists integer, p_clean boolean,
  p_saves integer, p_yellow integer, p_red integer, p_minutes integer
) returns numeric language plpgsql as $$
declare base numeric; result numeric;
begin
 select rating into base from public.players where id=p_player;
 if base is null then base:=50; end if;
 result := base
   + least(12, p_goals*3)
   + least(8, p_assists*2)
   + case when p_clean then 2 else 0 end
   + least(6, p_saves*0.4)
   - p_yellow*0.5
   - p_red*2
   + case when p_minutes >= 60 then 0.5 else 0 end;
 return greatest(1,least(100,round(result,1)));
end; $$;

-- RLS
alter table public.profiles enable row level security;
alter table public.teams enable row level security;
alter table public.players enable row level security;
alter table public.matches enable row level security;
alter table public.match_events enable row level security;
alter table public.match_player_stats enable row level security;
alter table public.transfers enable row level security;
alter table public.news enable row level security;
alter table public.seasons enable row level security;
alter table public.tournaments enable row level security;
alter table public.tournament_ties enable row level security;
alter table public.awards enable row level security;

create or replace function public.is_admin()
returns boolean language sql security definer stable as $$
  select exists(select 1 from public.profiles where id=auth.uid() and role='admin');
$$;

create policy "public read teams" on public.teams for select using (true);
create policy "public read players" on public.players for select using (true);
create policy "public read matches" on public.matches for select using (true);
create policy "public read events" on public.match_events for select using (true);
create policy "public read stats" on public.match_player_stats for select using (true);
create policy "public read news" on public.news for select using (expires_at > now());
create policy "public read transfers" on public.transfers for select using (true);
create policy "public read seasons" on public.seasons for select using (true);
create policy "public read tournaments" on public.tournaments for select using (true);
create policy "public read ties" on public.tournament_ties for select using (true);
create policy "public read awards" on public.awards for select using (true);
create policy "read own profile" on public.profiles for select using (id=auth.uid() or public.is_admin());

create policy "admin teams insert" on public.teams for insert with check (public.is_admin());
create policy "admin teams update" on public.teams for update using (public.is_admin());
create policy "admin teams delete" on public.teams for delete using (public.is_admin());
create policy "admin players insert" on public.players for insert with check (public.is_admin());
create policy "admin players update" on public.players for update using (public.is_admin());
create policy "admin players delete" on public.players for delete using (public.is_admin());
create policy "admin matches insert" on public.matches for insert with check (public.is_admin());
create policy "admin matches update" on public.matches for update using (public.is_admin());
create policy "admin matches delete" on public.matches for delete using (public.is_admin());
create policy "admin events insert" on public.match_events for insert with check (public.is_admin());
create policy "admin events update" on public.match_events for update using (public.is_admin());
create policy "admin events delete" on public.match_events for delete using (public.is_admin());
create policy "admin stats insert" on public.match_player_stats for insert with check (public.is_admin());
create policy "admin stats update" on public.match_player_stats for update using (public.is_admin());
create policy "admin stats delete" on public.match_player_stats for delete using (public.is_admin());
create policy "admin news insert" on public.news for insert with check (public.is_admin());
create policy "admin news update" on public.news for update using (public.is_admin());
create policy "admin news delete" on public.news for delete using (public.is_admin());
create policy "admin transfers insert" on public.transfers for insert with check (public.is_admin());
create policy "admin transfers update" on public.transfers for update using (public.is_admin());
create policy "admin transfers delete" on public.transfers for delete using (public.is_admin());
create policy "admin seasons insert" on public.seasons for insert with check (public.is_admin());
create policy "admin seasons update" on public.seasons for update using (public.is_admin());
create policy "admin tournaments insert" on public.tournaments for insert with check (public.is_admin());
create policy "admin tournaments update" on public.tournaments for update using (public.is_admin());
create policy "admin ties insert" on public.tournament_ties for insert with check (public.is_admin());
create policy "admin ties update" on public.tournament_ties for update using (public.is_admin());
create policy "admin awards insert" on public.awards for insert with check (public.is_admin());
create policy "admin awards update" on public.awards for update using (public.is_admin());

-- create profile automatically when a user registers
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path=public as $$
begin
 insert into public.profiles(id,email,display_name)
 values(new.id,new.email,coalesce(new.raw_user_meta_data->>'display_name',split_part(new.email,'@',1)));
 return new;
end; $$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users
for each row execute procedure public.handle_new_user();

insert into public.seasons(name,is_current)
values('2026/27',true)
on conflict (name) do nothing;
