-- ============================================================================
--  GOALPOST  ·  World Cup 2026 friends' pool  ·  Supabase schema
--  HOW TO RUN: Supabase dashboard → SQL Editor → New query → paste all → Run
--  Safe to re-run (uses "if not exists" + "on conflict do nothing").
-- ============================================================================

-- ---------------------------- TABLES ----------------------------------------
create table if not exists profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text,
  display_name text,
  emoji text default '🙂',
  is_admin boolean default false,
  paid boolean default false,
  created_at timestamptz default now()
);

create table if not exists settings (
  id int primary key default 1,
  app_title text default 'GOALPOST',
  starting_coins int default 1000,
  pts_exact int default 5,
  pts_result int default 2,
  pts_advance int default 4,
  buy_in int default 20,
  currency text default '$',
  payout_split jsonb default '[50,30,20]',
  bet_basis text default 'points'
);

create table if not exists teams (
  id text primary key, name text, flag text, grp text, pos int
);

create table if not exists matches (
  id text primary key, stage text, grp text, md int,
  home text references teams(id), away text references teams(id),
  kickoff timestamptz, home_score int, away_score int,
  status text default 'scheduled'
);

create table if not exists props (
  id text primary key, icon text, q text, type text,
  options jsonb, line numeric, pts int,
  status text default 'open', correct text, allow_coins boolean default false
);

create table if not exists predictions (
  id text primary key,
  user_id uuid references auth.users(id) on delete cascade,
  match_id text references matches(id) on delete cascade,
  hp int, ap int, wager int default 0, pick text
);

create table if not exists prop_answers (
  id text primary key,
  user_id uuid references auth.users(id) on delete cascade,
  prop_id text references props(id) on delete cascade,
  answer text, wager int default 0
);

create table if not exists advances (
  id text primary key,
  user_id uuid references auth.users(id) on delete cascade,
  grp text, slot int, team text
);

-- ------------------- ADMIN HELPER (used by policies) ------------------------
create or replace function is_admin() returns boolean
  language sql security definer stable as $func$
  select coalesce((select is_admin from profiles where id = auth.uid()), false);
$func$;

-- --------------------------- ROW-LEVEL SECURITY -----------------------------
alter table profiles      enable row level security;
alter table settings      enable row level security;
alter table teams         enable row level security;
alter table matches       enable row level security;
alter table props         enable row level security;
alter table predictions   enable row level security;
alter table prop_answers  enable row level security;
alter table advances      enable row level security;

-- Shared game data: any signed-in member can read; only admins can change.
drop policy if exists p_read on profiles;
create policy p_read on profiles for select to authenticated using (true);
drop policy if exists p_ins on profiles;
create policy p_ins on profiles for insert to authenticated with check (id = auth.uid());
drop policy if exists p_upd on profiles;
create policy p_upd on profiles for update to authenticated using (id = auth.uid() or is_admin()) with check (id = auth.uid() or is_admin());

drop policy if exists s_read on settings;
create policy s_read on settings for select to authenticated using (true);
drop policy if exists s_admin on settings;
create policy s_admin on settings for all to authenticated using (is_admin()) with check (is_admin());

drop policy if exists t_read on teams;
create policy t_read on teams for select to authenticated using (true);
drop policy if exists t_admin on teams;
create policy t_admin on teams for all to authenticated using (is_admin()) with check (is_admin());

drop policy if exists m_read on matches;
create policy m_read on matches for select to authenticated using (true);
drop policy if exists m_admin on matches;
create policy m_admin on matches for all to authenticated using (is_admin()) with check (is_admin());

drop policy if exists pr_read on props;
create policy pr_read on props for select to authenticated using (true);
drop policy if exists pr_admin on props;
create policy pr_admin on props for all to authenticated using (is_admin()) with check (is_admin());

-- Picks: everyone can READ (powers the leaderboard + trash talk), only owner can WRITE.
drop policy if exists pred_read on predictions;
create policy pred_read on predictions for select to authenticated using (true);
drop policy if exists pred_own on predictions;
create policy pred_own on predictions for all to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());

drop policy if exists pa_read on prop_answers;
create policy pa_read on prop_answers for select to authenticated using (true);
drop policy if exists pa_own on prop_answers;
create policy pa_own on prop_answers for all to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());

drop policy if exists adv_read on advances;
create policy adv_read on advances for select to authenticated using (true);
drop policy if exists adv_own on advances;
create policy adv_own on advances for all to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());

-- ============================================================================
--  SEED DATA  (real 2026 World Cup draw + fixtures + prop bets + settings)
-- ============================================================================
-- 48 teams (real 2026 draw)
insert into teams (id,name,flag,grp,pos) values ('A1','Mexico','🇲🇽','A',1) on conflict (id) do nothing;
insert into teams (id,name,flag,grp,pos) values ('A2','South Africa','🇿🇦','A',2) on conflict (id) do nothing;
insert into teams (id,name,flag,grp,pos) values ('A3','South Korea','🇰🇷','A',3) on conflict (id) do nothing;
insert into teams (id,name,flag,grp,pos) values ('A4','Czechia','🇨🇿','A',4) on conflict (id) do nothing;
insert into teams (id,name,flag,grp,pos) values ('B1','Canada','🇨🇦','B',1) on conflict (id) do nothing;
insert into teams (id,name,flag,grp,pos) values ('B2','Switzerland','🇨🇭','B',2) on conflict (id) do nothing;
insert into teams (id,name,flag,grp,pos) values ('B3','Qatar','🇶🇦','B',3) on conflict (id) do nothing;
insert into teams (id,name,flag,grp,pos) values ('B4','Bosnia & Herz.','🇧🇦','B',4) on conflict (id) do nothing;
insert into teams (id,name,flag,grp,pos) values ('C1','Brazil','🇧🇷','C',1) on conflict (id) do nothing;
insert into teams (id,name,flag,grp,pos) values ('C2','Morocco','🇲🇦','C',2) on conflict (id) do nothing;
insert into teams (id,name,flag,grp,pos) values ('C3','Haiti','🇭🇹','C',3) on conflict (id) do nothing;
insert into teams (id,name,flag,grp,pos) values ('C4','Scotland','🏴󠁧󠁢󠁳󠁣󠁴󠁿','C',4) on conflict (id) do nothing;
insert into teams (id,name,flag,grp,pos) values ('D1','USA','🇺🇸','D',1) on conflict (id) do nothing;
insert into teams (id,name,flag,grp,pos) values ('D2','Paraguay','🇵🇾','D',2) on conflict (id) do nothing;
insert into teams (id,name,flag,grp,pos) values ('D3','Australia','🇦🇺','D',3) on conflict (id) do nothing;
insert into teams (id,name,flag,grp,pos) values ('D4','Türkiye','🇹🇷','D',4) on conflict (id) do nothing;
insert into teams (id,name,flag,grp,pos) values ('E1','Germany','🇩🇪','E',1) on conflict (id) do nothing;
insert into teams (id,name,flag,grp,pos) values ('E2','Curaçao','🇨🇼','E',2) on conflict (id) do nothing;
insert into teams (id,name,flag,grp,pos) values ('E3','Côte d''Ivoire','🇨🇮','E',3) on conflict (id) do nothing;
insert into teams (id,name,flag,grp,pos) values ('E4','Ecuador','🇪🇨','E',4) on conflict (id) do nothing;
insert into teams (id,name,flag,grp,pos) values ('F1','Netherlands','🇳🇱','F',1) on conflict (id) do nothing;
insert into teams (id,name,flag,grp,pos) values ('F2','Japan','🇯🇵','F',2) on conflict (id) do nothing;
insert into teams (id,name,flag,grp,pos) values ('F3','Tunisia','🇹🇳','F',3) on conflict (id) do nothing;
insert into teams (id,name,flag,grp,pos) values ('F4','Sweden','🇸🇪','F',4) on conflict (id) do nothing;
insert into teams (id,name,flag,grp,pos) values ('G1','Belgium','🇧🇪','G',1) on conflict (id) do nothing;
insert into teams (id,name,flag,grp,pos) values ('G2','Egypt','🇪🇬','G',2) on conflict (id) do nothing;
insert into teams (id,name,flag,grp,pos) values ('G3','Iran','🇮🇷','G',3) on conflict (id) do nothing;
insert into teams (id,name,flag,grp,pos) values ('G4','New Zealand','🇳🇿','G',4) on conflict (id) do nothing;
insert into teams (id,name,flag,grp,pos) values ('H1','Spain','🇪🇸','H',1) on conflict (id) do nothing;
insert into teams (id,name,flag,grp,pos) values ('H2','Cabo Verde','🇨🇻','H',2) on conflict (id) do nothing;
insert into teams (id,name,flag,grp,pos) values ('H3','Saudi Arabia','🇸🇦','H',3) on conflict (id) do nothing;
insert into teams (id,name,flag,grp,pos) values ('H4','Uruguay','🇺🇾','H',4) on conflict (id) do nothing;
insert into teams (id,name,flag,grp,pos) values ('I1','France','🇫🇷','I',1) on conflict (id) do nothing;
insert into teams (id,name,flag,grp,pos) values ('I2','Senegal','🇸🇳','I',2) on conflict (id) do nothing;
insert into teams (id,name,flag,grp,pos) values ('I3','Norway','🇳🇴','I',3) on conflict (id) do nothing;
insert into teams (id,name,flag,grp,pos) values ('I4','Iraq','🇮🇶','I',4) on conflict (id) do nothing;
insert into teams (id,name,flag,grp,pos) values ('J1','Argentina','🇦🇷','J',1) on conflict (id) do nothing;
insert into teams (id,name,flag,grp,pos) values ('J2','Algeria','🇩🇿','J',2) on conflict (id) do nothing;
insert into teams (id,name,flag,grp,pos) values ('J3','Austria','🇦🇹','J',3) on conflict (id) do nothing;
insert into teams (id,name,flag,grp,pos) values ('J4','Jordan','🇯🇴','J',4) on conflict (id) do nothing;
insert into teams (id,name,flag,grp,pos) values ('K1','Portugal','🇵🇹','K',1) on conflict (id) do nothing;
insert into teams (id,name,flag,grp,pos) values ('K2','Uzbekistan','🇺🇿','K',2) on conflict (id) do nothing;
insert into teams (id,name,flag,grp,pos) values ('K3','Colombia','🇨🇴','K',3) on conflict (id) do nothing;
insert into teams (id,name,flag,grp,pos) values ('K4','DR Congo','🇨🇩','K',4) on conflict (id) do nothing;
insert into teams (id,name,flag,grp,pos) values ('L1','England','🏴󠁧󠁢󠁥󠁮󠁧󠁿','L',1) on conflict (id) do nothing;
insert into teams (id,name,flag,grp,pos) values ('L2','Croatia','🇭🇷','L',2) on conflict (id) do nothing;
insert into teams (id,name,flag,grp,pos) values ('L3','Ghana','🇬🇭','L',3) on conflict (id) do nothing;
insert into teams (id,name,flag,grp,pos) values ('L4','Panama','🇵🇦','L',4) on conflict (id) do nothing;

-- 72 group-stage fixtures
insert into matches (id,stage,grp,md,home,away,kickoff,home_score,away_score,status) values ('G-A-1','group','A',1,'A1','A2','2026-06-11T20:00:00',null,null,'scheduled') on conflict (id) do nothing;
insert into matches (id,stage,grp,md,home,away,kickoff,home_score,away_score,status) values ('G-A-2','group','A',1,'A3','A4','2026-06-13T15:00:00',null,null,'scheduled') on conflict (id) do nothing;
insert into matches (id,stage,grp,md,home,away,kickoff,home_score,away_score,status) values ('G-A-3','group','A',2,'A1','A3','2026-06-17T18:00:00',null,null,'scheduled') on conflict (id) do nothing;
insert into matches (id,stage,grp,md,home,away,kickoff,home_score,away_score,status) values ('G-A-4','group','A',2,'A4','A2','2026-06-18T21:00:00',null,null,'scheduled') on conflict (id) do nothing;
insert into matches (id,stage,grp,md,home,away,kickoff,home_score,away_score,status) values ('G-A-5','group','A',3,'A4','A1','2026-06-23T12:00:00',null,null,'scheduled') on conflict (id) do nothing;
insert into matches (id,stage,grp,md,home,away,kickoff,home_score,away_score,status) values ('G-A-6','group','A',3,'A2','A3','2026-06-24T15:00:00',null,null,'scheduled') on conflict (id) do nothing;
insert into matches (id,stage,grp,md,home,away,kickoff,home_score,away_score,status) values ('G-B-1','group','B',1,'B1','B2','2026-06-13T15:00:00',null,null,'scheduled') on conflict (id) do nothing;
insert into matches (id,stage,grp,md,home,away,kickoff,home_score,away_score,status) values ('G-B-2','group','B',1,'B3','B4','2026-06-14T18:00:00',null,null,'scheduled') on conflict (id) do nothing;
insert into matches (id,stage,grp,md,home,away,kickoff,home_score,away_score,status) values ('G-B-3','group','B',2,'B1','B3','2026-06-18T21:00:00',null,null,'scheduled') on conflict (id) do nothing;
insert into matches (id,stage,grp,md,home,away,kickoff,home_score,away_score,status) values ('G-B-4','group','B',2,'B4','B2','2026-06-19T12:00:00',null,null,'scheduled') on conflict (id) do nothing;
insert into matches (id,stage,grp,md,home,away,kickoff,home_score,away_score,status) values ('G-B-5','group','B',3,'B4','B1','2026-06-24T15:00:00',null,null,'scheduled') on conflict (id) do nothing;
insert into matches (id,stage,grp,md,home,away,kickoff,home_score,away_score,status) values ('G-B-6','group','B',3,'B2','B3','2026-06-25T18:00:00',null,null,'scheduled') on conflict (id) do nothing;
insert into matches (id,stage,grp,md,home,away,kickoff,home_score,away_score,status) values ('G-C-1','group','C',1,'C1','C2','2026-06-14T18:00:00',null,null,'scheduled') on conflict (id) do nothing;
insert into matches (id,stage,grp,md,home,away,kickoff,home_score,away_score,status) values ('G-C-2','group','C',1,'C3','C4','2026-06-12T21:00:00',null,null,'scheduled') on conflict (id) do nothing;
insert into matches (id,stage,grp,md,home,away,kickoff,home_score,away_score,status) values ('G-C-3','group','C',2,'C1','C3','2026-06-19T12:00:00',null,null,'scheduled') on conflict (id) do nothing;
insert into matches (id,stage,grp,md,home,away,kickoff,home_score,away_score,status) values ('G-C-4','group','C',2,'C4','C2','2026-06-17T15:00:00',null,null,'scheduled') on conflict (id) do nothing;
insert into matches (id,stage,grp,md,home,away,kickoff,home_score,away_score,status) values ('G-C-5','group','C',3,'C4','C1','2026-06-25T18:00:00',null,null,'scheduled') on conflict (id) do nothing;
insert into matches (id,stage,grp,md,home,away,kickoff,home_score,away_score,status) values ('G-C-6','group','C',3,'C2','C3','2026-06-23T21:00:00',null,null,'scheduled') on conflict (id) do nothing;
insert into matches (id,stage,grp,md,home,away,kickoff,home_score,away_score,status) values ('G-D-1','group','D',1,'D1','D2','2026-06-12T21:00:00',null,null,'scheduled') on conflict (id) do nothing;
insert into matches (id,stage,grp,md,home,away,kickoff,home_score,away_score,status) values ('G-D-2','group','D',1,'D3','D4','2026-06-13T12:00:00',null,null,'scheduled') on conflict (id) do nothing;
insert into matches (id,stage,grp,md,home,away,kickoff,home_score,away_score,status) values ('G-D-3','group','D',2,'D1','D3','2026-06-17T15:00:00',null,null,'scheduled') on conflict (id) do nothing;
insert into matches (id,stage,grp,md,home,away,kickoff,home_score,away_score,status) values ('G-D-4','group','D',2,'D4','D2','2026-06-18T18:00:00',null,null,'scheduled') on conflict (id) do nothing;
insert into matches (id,stage,grp,md,home,away,kickoff,home_score,away_score,status) values ('G-D-5','group','D',3,'D4','D1','2026-06-23T21:00:00',null,null,'scheduled') on conflict (id) do nothing;
insert into matches (id,stage,grp,md,home,away,kickoff,home_score,away_score,status) values ('G-D-6','group','D',3,'D2','D3','2026-06-24T12:00:00',null,null,'scheduled') on conflict (id) do nothing;
insert into matches (id,stage,grp,md,home,away,kickoff,home_score,away_score,status) values ('G-E-1','group','E',1,'E1','E2','2026-06-13T12:00:00',null,null,'scheduled') on conflict (id) do nothing;
insert into matches (id,stage,grp,md,home,away,kickoff,home_score,away_score,status) values ('G-E-2','group','E',1,'E3','E4','2026-06-14T15:00:00',null,null,'scheduled') on conflict (id) do nothing;
insert into matches (id,stage,grp,md,home,away,kickoff,home_score,away_score,status) values ('G-E-3','group','E',2,'E1','E3','2026-06-18T18:00:00',null,null,'scheduled') on conflict (id) do nothing;
insert into matches (id,stage,grp,md,home,away,kickoff,home_score,away_score,status) values ('G-E-4','group','E',2,'E4','E2','2026-06-19T21:00:00',null,null,'scheduled') on conflict (id) do nothing;
insert into matches (id,stage,grp,md,home,away,kickoff,home_score,away_score,status) values ('G-E-5','group','E',3,'E4','E1','2026-06-24T12:00:00',null,null,'scheduled') on conflict (id) do nothing;
insert into matches (id,stage,grp,md,home,away,kickoff,home_score,away_score,status) values ('G-E-6','group','E',3,'E2','E3','2026-06-25T15:00:00',null,null,'scheduled') on conflict (id) do nothing;
insert into matches (id,stage,grp,md,home,away,kickoff,home_score,away_score,status) values ('G-F-1','group','F',1,'F1','F2','2026-06-14T15:00:00',null,null,'scheduled') on conflict (id) do nothing;
insert into matches (id,stage,grp,md,home,away,kickoff,home_score,away_score,status) values ('G-F-2','group','F',1,'F3','F4','2026-06-12T18:00:00',null,null,'scheduled') on conflict (id) do nothing;
insert into matches (id,stage,grp,md,home,away,kickoff,home_score,away_score,status) values ('G-F-3','group','F',2,'F1','F3','2026-06-19T21:00:00',null,null,'scheduled') on conflict (id) do nothing;
insert into matches (id,stage,grp,md,home,away,kickoff,home_score,away_score,status) values ('G-F-4','group','F',2,'F4','F2','2026-06-17T12:00:00',null,null,'scheduled') on conflict (id) do nothing;
insert into matches (id,stage,grp,md,home,away,kickoff,home_score,away_score,status) values ('G-F-5','group','F',3,'F4','F1','2026-06-25T15:00:00',null,null,'scheduled') on conflict (id) do nothing;
insert into matches (id,stage,grp,md,home,away,kickoff,home_score,away_score,status) values ('G-F-6','group','F',3,'F2','F3','2026-06-23T18:00:00',null,null,'scheduled') on conflict (id) do nothing;
insert into matches (id,stage,grp,md,home,away,kickoff,home_score,away_score,status) values ('G-G-1','group','G',1,'G1','G2','2026-06-12T18:00:00',null,null,'scheduled') on conflict (id) do nothing;
insert into matches (id,stage,grp,md,home,away,kickoff,home_score,away_score,status) values ('G-G-2','group','G',1,'G3','G4','2026-06-13T21:00:00',null,null,'scheduled') on conflict (id) do nothing;
insert into matches (id,stage,grp,md,home,away,kickoff,home_score,away_score,status) values ('G-G-3','group','G',2,'G1','G3','2026-06-17T12:00:00',null,null,'scheduled') on conflict (id) do nothing;
insert into matches (id,stage,grp,md,home,away,kickoff,home_score,away_score,status) values ('G-G-4','group','G',2,'G4','G2','2026-06-18T15:00:00',null,null,'scheduled') on conflict (id) do nothing;
insert into matches (id,stage,grp,md,home,away,kickoff,home_score,away_score,status) values ('G-G-5','group','G',3,'G4','G1','2026-06-23T18:00:00',null,null,'scheduled') on conflict (id) do nothing;
insert into matches (id,stage,grp,md,home,away,kickoff,home_score,away_score,status) values ('G-G-6','group','G',3,'G2','G3','2026-06-24T21:00:00',null,null,'scheduled') on conflict (id) do nothing;
insert into matches (id,stage,grp,md,home,away,kickoff,home_score,away_score,status) values ('G-H-1','group','H',1,'H1','H2','2026-06-13T21:00:00',null,null,'scheduled') on conflict (id) do nothing;
insert into matches (id,stage,grp,md,home,away,kickoff,home_score,away_score,status) values ('G-H-2','group','H',1,'H3','H4','2026-06-14T12:00:00',null,null,'scheduled') on conflict (id) do nothing;
insert into matches (id,stage,grp,md,home,away,kickoff,home_score,away_score,status) values ('G-H-3','group','H',2,'H1','H3','2026-06-18T15:00:00',null,null,'scheduled') on conflict (id) do nothing;
insert into matches (id,stage,grp,md,home,away,kickoff,home_score,away_score,status) values ('G-H-4','group','H',2,'H4','H2','2026-06-19T18:00:00',null,null,'scheduled') on conflict (id) do nothing;
insert into matches (id,stage,grp,md,home,away,kickoff,home_score,away_score,status) values ('G-H-5','group','H',3,'H4','H1','2026-06-24T21:00:00',null,null,'scheduled') on conflict (id) do nothing;
insert into matches (id,stage,grp,md,home,away,kickoff,home_score,away_score,status) values ('G-H-6','group','H',3,'H2','H3','2026-06-25T12:00:00',null,null,'scheduled') on conflict (id) do nothing;
insert into matches (id,stage,grp,md,home,away,kickoff,home_score,away_score,status) values ('G-I-1','group','I',1,'I1','I2','2026-06-14T12:00:00',null,null,'scheduled') on conflict (id) do nothing;
insert into matches (id,stage,grp,md,home,away,kickoff,home_score,away_score,status) values ('G-I-2','group','I',1,'I3','I4','2026-06-12T15:00:00',null,null,'scheduled') on conflict (id) do nothing;
insert into matches (id,stage,grp,md,home,away,kickoff,home_score,away_score,status) values ('G-I-3','group','I',2,'I1','I3','2026-06-19T18:00:00',null,null,'scheduled') on conflict (id) do nothing;
insert into matches (id,stage,grp,md,home,away,kickoff,home_score,away_score,status) values ('G-I-4','group','I',2,'I4','I2','2026-06-17T21:00:00',null,null,'scheduled') on conflict (id) do nothing;
insert into matches (id,stage,grp,md,home,away,kickoff,home_score,away_score,status) values ('G-I-5','group','I',3,'I4','I1','2026-06-25T12:00:00',null,null,'scheduled') on conflict (id) do nothing;
insert into matches (id,stage,grp,md,home,away,kickoff,home_score,away_score,status) values ('G-I-6','group','I',3,'I2','I3','2026-06-23T15:00:00',null,null,'scheduled') on conflict (id) do nothing;
insert into matches (id,stage,grp,md,home,away,kickoff,home_score,away_score,status) values ('G-J-1','group','J',1,'J1','J2','2026-06-12T15:00:00',null,null,'scheduled') on conflict (id) do nothing;
insert into matches (id,stage,grp,md,home,away,kickoff,home_score,away_score,status) values ('G-J-2','group','J',1,'J3','J4','2026-06-13T18:00:00',null,null,'scheduled') on conflict (id) do nothing;
insert into matches (id,stage,grp,md,home,away,kickoff,home_score,away_score,status) values ('G-J-3','group','J',2,'J1','J3','2026-06-17T21:00:00',null,null,'scheduled') on conflict (id) do nothing;
insert into matches (id,stage,grp,md,home,away,kickoff,home_score,away_score,status) values ('G-J-4','group','J',2,'J4','J2','2026-06-18T12:00:00',null,null,'scheduled') on conflict (id) do nothing;
insert into matches (id,stage,grp,md,home,away,kickoff,home_score,away_score,status) values ('G-J-5','group','J',3,'J4','J1','2026-06-23T15:00:00',null,null,'scheduled') on conflict (id) do nothing;
insert into matches (id,stage,grp,md,home,away,kickoff,home_score,away_score,status) values ('G-J-6','group','J',3,'J2','J3','2026-06-24T18:00:00',null,null,'scheduled') on conflict (id) do nothing;
insert into matches (id,stage,grp,md,home,away,kickoff,home_score,away_score,status) values ('G-K-1','group','K',1,'K1','K2','2026-06-13T18:00:00',null,null,'scheduled') on conflict (id) do nothing;
insert into matches (id,stage,grp,md,home,away,kickoff,home_score,away_score,status) values ('G-K-2','group','K',1,'K3','K4','2026-06-14T21:00:00',null,null,'scheduled') on conflict (id) do nothing;
insert into matches (id,stage,grp,md,home,away,kickoff,home_score,away_score,status) values ('G-K-3','group','K',2,'K1','K3','2026-06-18T12:00:00',null,null,'scheduled') on conflict (id) do nothing;
insert into matches (id,stage,grp,md,home,away,kickoff,home_score,away_score,status) values ('G-K-4','group','K',2,'K4','K2','2026-06-19T15:00:00',null,null,'scheduled') on conflict (id) do nothing;
insert into matches (id,stage,grp,md,home,away,kickoff,home_score,away_score,status) values ('G-K-5','group','K',3,'K4','K1','2026-06-24T18:00:00',null,null,'scheduled') on conflict (id) do nothing;
insert into matches (id,stage,grp,md,home,away,kickoff,home_score,away_score,status) values ('G-K-6','group','K',3,'K2','K3','2026-06-25T21:00:00',null,null,'scheduled') on conflict (id) do nothing;
insert into matches (id,stage,grp,md,home,away,kickoff,home_score,away_score,status) values ('G-L-1','group','L',1,'L1','L2','2026-06-14T21:00:00',null,null,'scheduled') on conflict (id) do nothing;
insert into matches (id,stage,grp,md,home,away,kickoff,home_score,away_score,status) values ('G-L-2','group','L',1,'L3','L4','2026-06-12T12:00:00',null,null,'scheduled') on conflict (id) do nothing;
insert into matches (id,stage,grp,md,home,away,kickoff,home_score,away_score,status) values ('G-L-3','group','L',2,'L1','L3','2026-06-19T15:00:00',null,null,'scheduled') on conflict (id) do nothing;
insert into matches (id,stage,grp,md,home,away,kickoff,home_score,away_score,status) values ('G-L-4','group','L',2,'L4','L2','2026-06-17T18:00:00',null,null,'scheduled') on conflict (id) do nothing;
insert into matches (id,stage,grp,md,home,away,kickoff,home_score,away_score,status) values ('G-L-5','group','L',3,'L4','L1','2026-06-25T21:00:00',null,null,'scheduled') on conflict (id) do nothing;
insert into matches (id,stage,grp,md,home,away,kickoff,home_score,away_score,status) values ('G-L-6','group','L',3,'L2','L3','2026-06-23T12:00:00',null,null,'scheduled') on conflict (id) do nothing;

-- prop bets
insert into props (id,icon,q,type,options,line,pts,status,correct,allow_coins) values ('p-champ','🏆','Who lifts the trophy?','team','[{"v":"A1","label":"🇲🇽 Mexico"},{"v":"A2","label":"🇿🇦 South Africa"},{"v":"A3","label":"🇰🇷 South Korea"},{"v":"A4","label":"🇨🇿 Czechia"},{"v":"B1","label":"🇨🇦 Canada"},{"v":"B2","label":"🇨🇭 Switzerland"},{"v":"B3","label":"🇶🇦 Qatar"},{"v":"B4","label":"🇧🇦 Bosnia & Herz."},{"v":"C1","label":"🇧🇷 Brazil"},{"v":"C2","label":"🇲🇦 Morocco"},{"v":"C3","label":"🇭🇹 Haiti"},{"v":"C4","label":"🏴󠁧󠁢󠁳󠁣󠁴󠁿 Scotland"},{"v":"D1","label":"🇺🇸 USA"},{"v":"D2","label":"🇵🇾 Paraguay"},{"v":"D3","label":"🇦🇺 Australia"},{"v":"D4","label":"🇹🇷 Türkiye"},{"v":"E1","label":"🇩🇪 Germany"},{"v":"E2","label":"🇨🇼 Curaçao"},{"v":"E3","label":"🇨🇮 Côte d''Ivoire"},{"v":"E4","label":"🇪🇨 Ecuador"},{"v":"F1","label":"🇳🇱 Netherlands"},{"v":"F2","label":"🇯🇵 Japan"},{"v":"F3","label":"🇹🇳 Tunisia"},{"v":"F4","label":"🇸🇪 Sweden"},{"v":"G1","label":"🇧🇪 Belgium"},{"v":"G2","label":"🇪🇬 Egypt"},{"v":"G3","label":"🇮🇷 Iran"},{"v":"G4","label":"🇳🇿 New Zealand"},{"v":"H1","label":"🇪🇸 Spain"},{"v":"H2","label":"🇨🇻 Cabo Verde"},{"v":"H3","label":"🇸🇦 Saudi Arabia"},{"v":"H4","label":"🇺🇾 Uruguay"},{"v":"I1","label":"🇫🇷 France"},{"v":"I2","label":"🇸🇳 Senegal"},{"v":"I3","label":"🇳🇴 Norway"},{"v":"I4","label":"🇮🇶 Iraq"},{"v":"J1","label":"🇦🇷 Argentina"},{"v":"J2","label":"🇩🇿 Algeria"},{"v":"J3","label":"🇦🇹 Austria"},{"v":"J4","label":"🇯🇴 Jordan"},{"v":"K1","label":"🇵🇹 Portugal"},{"v":"K2","label":"🇺🇿 Uzbekistan"},{"v":"K3","label":"🇨🇴 Colombia"},{"v":"K4","label":"🇨🇩 DR Congo"},{"v":"L1","label":"🏴󠁧󠁢󠁥󠁮󠁧󠁿 England"},{"v":"L2","label":"🇭🇷 Croatia"},{"v":"L3","label":"🇬🇭 Ghana"},{"v":"L4","label":"🇵🇦 Panama"}]'::jsonb,null,30,'open',null,true) on conflict (id) do nothing;
insert into props (id,icon,q,type,options,line,pts,status,correct,allow_coins) values ('p-flop','😱','Which giant FLOPS out in the group stage?','mc','[{"v":"Brazil","label":"🇧🇷 Brazil"},{"v":"Argentina","label":"🇦🇷 Argentina"},{"v":"France","label":"🇫🇷 France"},{"v":"Spain","label":"🇪🇸 Spain"},{"v":"England","label":"🏴 England"},{"v":"Germany","label":"🇩🇪 Germany"},{"v":"none","label":"🛡️ None of them (boring)"}]'::jsonb,null,8,'open',null,true) on conflict (id) do nothing;
insert into props (id,icon,q,type,options,line,pts,status,correct,allow_coins) values ('p-cinderella','🐴','Best Cinderella run — which underdog goes furthest?','mc','[{"v":"Haiti","label":"🇭🇹 Haiti"},{"v":"Curaçao","label":"🇨🇼 Curaçao"},{"v":"Cabo Verde","label":"🇨🇻 Cabo Verde"},{"v":"Jordan","label":"🇯🇴 Jordan"},{"v":"Panama","label":"🇵🇦 Panama"},{"v":"Uzbekistan","label":"🇺🇿 Uzbekistan"},{"v":"New Zealand","label":"🇳🇿 New Zealand"}]'::jsonb,null,10,'open',null,true) on conflict (id) do nothing;
insert into props (id,icon,q,type,options,line,pts,status,correct,allow_coins) values ('p-usa','🦅','Do the host USA escape Group D?','yesno',null,null,5,'open',null,true) on conflict (id) do nothing;
insert into props (id,icon,q,type,options,line,pts,status,correct,allow_coins) values ('p-pens','🥅','Will the FINAL go to penalties?','yesno',null,null,6,'open',null,false) on conflict (id) do nothing;
insert into props (id,icon,q,type,options,line,pts,status,correct,allow_coins) values ('p-boot','⚽','Golden Boot top scorer — total goals?','ou',null,7.5,6,'open',null,false) on conflict (id) do nothing;
insert into props (id,icon,q,type,options,line,pts,status,correct,allow_coins) values ('p-reds','🟥','Total red cards in the whole tournament?','ou',null,18.5,5,'open',null,false) on conflict (id) do nothing;
insert into props (id,icon,q,type,options,line,pts,status,correct,allow_coins) values ('p-goals','🎯','Goals in the group stage (72 matches)?','ou',null,201.5,7,'open',null,false) on conflict (id) do nothing;

-- league settings (single row)
insert into settings (id,app_title,starting_coins,pts_exact,pts_result,pts_advance,buy_in,currency,payout_split,bet_basis) values (1,'GOALPOST',1000,5,2,4,20,'$','[50,30,20]'::jsonb,'points') on conflict (id) do nothing;

-- Done. Now: (1) paste your project URL + anon key into index.html, (2) make yourself admin:
--   update profiles set is_admin = true where email = 'a.svaetichin@gmail.com';
