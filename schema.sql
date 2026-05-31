-- ============================================================================
--  THE MASK  ·  World Cup 2026 friends' pool  ·  Supabase schema
--  Run in: Supabase dashboard -> SQL Editor -> New query -> paste all -> Run.
--  Safe (and recommended) to re-run after any app update.
-- ============================================================================
create table if not exists profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text, display_name text, emoji text default '🙂', avatar text, fav_team text,
  is_admin boolean default false, paid boolean default false, created_at timestamptz default now());
-- 📊 Audit columns for the admin user-detail view ("where from + when").
-- All additive + safe to re-run.
alter table profiles add column if not exists signup_tz     text;          -- IANA timezone of the browser at signup ("Europe/Stockholm", "Asia/Tokyo", …)
alter table profiles add column if not exists signup_locale text;          -- navigator.language at signup ("en-US", "sv-SE", …)
alter table profiles add column if not exists last_seen_at  timestamptz;   -- updated on every load — admin can see who's active
create table if not exists settings (
  id int primary key default 1, app_title text default 'THE MASK', starting_coins int default 1000,
  pts_exact int default 5, pts_result int default 2, pts_advance int default 4,
  buy_in int default 50, currency text default 'USD', payout_split jsonb default '[50,30,20]',
  bet_basis text default 'points', ko jsonb default '{"qf":[],"sf":[],"final":[]}');
create table if not exists teams (id text primary key, name text, flag text, grp text, pos int);
create table if not exists matches (id text primary key, stage text, grp text, md int,
  home text references teams(id), away text references teams(id), kickoff timestamptz,
  home_score int, away_score int, status text default 'scheduled');
create table if not exists props (id text primary key, icon text, q text, type text,
  options jsonb, line numeric, pts int, status text default 'open', correct text, allow_coins boolean default false);
create table if not exists predictions (id text primary key,
  user_id uuid references auth.users(id) on delete cascade,
  match_id text references matches(id) on delete cascade,
  hp int, ap int, wager int default 0, pick text, banker boolean default false);
create table if not exists prop_answers (id text primary key,
  user_id uuid references auth.users(id) on delete cascade,
  prop_id text references props(id) on delete cascade, answer text, wager int default 0);
create table if not exists advances (id text primary key,
  user_id uuid references auth.users(id) on delete cascade, grp text, slot int, team text);
create table if not exists ko_picks (id text primary key,
  user_id uuid references auth.users(id) on delete cascade, stage text, team text);
create table if not exists repicks (id text primary key,
  user_id uuid references auth.users(id) on delete cascade, match_id text, hp int, ap int, created_at timestamptz default now());
-- 🏆 private leagues + who's in them
create table if not exists leagues (id text primary key,
  name text not null, code text unique not null,
  buy_in int default 50, currency text default 'USD', payout_split jsonb default '[50,30,20]',
  created_by uuid references auth.users(id) on delete set null, created_at timestamptz default now());
create table if not exists memberships (
  league_id text references leagues(id) on delete cascade,
  user_id uuid references auth.users(id) on delete cascade,
  paid boolean default false, joined_at timestamptz default now(),
  primary key (league_id, user_id));
-- 💬 banter feed + 🟨🟥 cards
create table if not exists comments (id text primary key,
  league_id text references leagues(id) on delete cascade,
  user_id uuid references auth.users(id) on delete cascade,
  body text, created_at timestamptz default now());
create table if not exists cards (id text primary key,
  league_id text references leagues(id) on delete cascade,
  comment_id text, from_id uuid references auth.users(id) on delete cascade,
  target_id uuid, kind text, created_at timestamptz default now());
create table if not exists likes (id text primary key,
  league_id text references leagues(id) on delete cascade,
  comment_id text, user_id uuid references auth.users(id) on delete cascade, created_at timestamptz default now());
-- 🏆 knockout bracket picks (one winner per tie, per user, per league — drag-drop tree)
create table if not exists bracket_picks (id text primary key,
  league_id text references leagues(id) on delete cascade,
  user_id uuid references auth.users(id) on delete cascade,
  tie text not null, team text not null, created_at timestamptz default now(),
  unique (league_id, user_id, tie));

-- patch older databases
alter table profiles    add column if not exists avatar text;
alter table profiles    add column if not exists fav_team text;
alter table settings    add column if not exists ko jsonb default '{"r16":[],"qf":[],"sf":[],"final":[]}';
alter table predictions add column if not exists banker boolean default false;
-- predictions/answers/etc. are now scoped to a league
alter table predictions  add column if not exists league_id text;
alter table prop_answers add column if not exists league_id text;
alter table advances     add column if not exists league_id text;
alter table ko_picks     add column if not exists league_id text;
alter table repicks      add column if not exists league_id text;

create or replace function is_admin() returns boolean language sql security definer stable as $func$
  select coalesce((select is_admin from profiles where id = auth.uid()), false);
$func$;

alter table profiles enable row level security;
alter table settings enable row level security;
alter table teams enable row level security;
alter table matches enable row level security;
alter table props enable row level security;
alter table predictions enable row level security;
alter table prop_answers enable row level security;
alter table advances enable row level security;
alter table ko_picks enable row level security;
alter table repicks enable row level security;
alter table leagues enable row level security;
alter table memberships enable row level security;
alter table comments enable row level security;
alter table cards enable row level security;
alter table likes enable row level security;
alter table bracket_picks enable row level security;

drop policy if exists p_read on profiles;   create policy p_read on profiles for select to authenticated using (true);
drop policy if exists p_ins on profiles;    create policy p_ins on profiles for insert to authenticated with check (id = auth.uid());
drop policy if exists p_upd on profiles;    create policy p_upd on profiles for update to authenticated using (id = auth.uid() or is_admin()) with check (id = auth.uid() or is_admin());
drop policy if exists s_read on settings;   create policy s_read on settings for select to authenticated using (true);
drop policy if exists s_admin on settings;  create policy s_admin on settings for all to authenticated using (is_admin()) with check (is_admin());
drop policy if exists t_read on teams;      create policy t_read on teams for select to authenticated using (true);
drop policy if exists t_admin on teams;     create policy t_admin on teams for all to authenticated using (is_admin()) with check (is_admin());
drop policy if exists m_read on matches;    create policy m_read on matches for select to authenticated using (true);
drop policy if exists m_admin on matches;   create policy m_admin on matches for all to authenticated using (is_admin()) with check (is_admin());
drop policy if exists pr_read on props;     create policy pr_read on props for select to authenticated using (true);
drop policy if exists pr_admin on props;    create policy pr_admin on props for all to authenticated using (is_admin()) with check (is_admin());

-- Helper fns are SECURITY DEFINER so their internal lookups run as the owner and DON'T re-trigger
-- the table's own RLS — this is what prevents the "infinite recursion in policy" 500 errors.
create or replace function public.is_member(lid text) returns boolean
  language sql security definer stable set search_path = public as $$
  select exists(select 1 from memberships where league_id = lid and user_id = auth.uid()); $$;
create or replace function public.has_pick(mid text, lid text) returns boolean
  language sql security definer stable set search_path = public as $$
  select exists(select 1 from predictions where match_id = mid and league_id = lid and user_id = auth.uid()); $$;
create or replace function public.has_answer(pid text, lid text) returns boolean
  language sql security definer stable set search_path = public as $$
  select exists(select 1 from prop_answers where prop_id = pid and league_id = lid and user_id = auth.uid()); $$;
grant execute on function public.is_member(text), public.has_pick(text,text), public.has_answer(text,text) to authenticated, anon;

-- PICKS ARE BLIND + IMMUTABLE, and only visible inside leagues you belong to:
-- read a row if you're a member AND (it's yours, you've picked the same match in this league, or it kicked off).
drop policy if exists pred_read on predictions;
create policy pred_read on predictions for select to authenticated using (
  is_member(league_id) and (
    user_id = auth.uid()
    or public.has_pick(match_id, league_id)
    or exists (select 1 from matches m where m.id = predictions.match_id and (m.status='finished' or m.kickoff <= now()))));
drop policy if exists pred_own on predictions;
drop policy if exists pred_insert on predictions;
create policy pred_insert on predictions for insert to authenticated with check (user_id = auth.uid() and is_member(league_id));
-- Picks are now editable until the round locks (30 min before that matchday's first kickoff).
-- The deadline itself is enforced app-side; RLS just lets you update/delete your own rows.
drop policy if exists pred_upd on predictions;
create policy pred_upd on predictions for update to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());
drop policy if exists pred_del on predictions;
create policy pred_del on predictions for delete to authenticated using (user_id = auth.uid());

drop policy if exists pa_read on prop_answers;
create policy pa_read on prop_answers for select to authenticated using (
  is_member(league_id) and (
    user_id = auth.uid()
    or public.has_answer(prop_id, league_id)
    or exists (select 1 from props p where p.id = prop_answers.prop_id and p.status='settled')));
drop policy if exists pa_own on prop_answers;
drop policy if exists pa_insert on prop_answers;
create policy pa_insert on prop_answers for insert to authenticated with check (user_id = auth.uid() and is_member(league_id));

drop policy if exists adv_read on advances;   create policy adv_read on advances for select to authenticated using (is_member(league_id));
drop policy if exists adv_own on advances;
drop policy if exists adv_insert on advances; create policy adv_insert on advances for insert to authenticated with check (user_id = auth.uid() and is_member(league_id));

drop policy if exists ko_read on ko_picks;    create policy ko_read on ko_picks for select to authenticated using (is_member(league_id));
drop policy if exists ko_insert on ko_picks;  create policy ko_insert on ko_picks for insert to authenticated with check (user_id = auth.uid() and is_member(league_id));
drop policy if exists rp_read on repicks;     create policy rp_read on repicks for select to authenticated using (is_member(league_id));
drop policy if exists rp_insert on repicks;   create policy rp_insert on repicks for insert to authenticated with check (user_id = auth.uid() and is_member(league_id));

-- leagues: anyone signed-in can look one up (needed to join by code); only the creator edits it.
drop policy if exists lg_read on leagues;   create policy lg_read on leagues for select to authenticated using (true);
drop policy if exists lg_ins on leagues;    create policy lg_ins on leagues for insert to authenticated with check (created_by = auth.uid());
drop policy if exists lg_upd on leagues;    create policy lg_upd on leagues for update to authenticated using (created_by = auth.uid()) with check (created_by = auth.uid());
-- memberships: see members of leagues you're in; join yourself; you (or the league owner) can update paid.
drop policy if exists mb_read on memberships; create policy mb_read on memberships for select to authenticated using (user_id = auth.uid() or is_member(league_id));
drop policy if exists mb_ins on memberships;  create policy mb_ins on memberships for insert to authenticated with check (user_id = auth.uid());
drop policy if exists mb_upd on memberships;  create policy mb_upd on memberships for update to authenticated using (user_id = auth.uid() or exists(select 1 from leagues l where l.id = league_id and l.created_by = auth.uid())) with check (true);
-- banter + cards: read/write only inside leagues you belong to
drop policy if exists cm_read on comments;  create policy cm_read on comments for select to authenticated using (is_member(league_id));
drop policy if exists cm_ins on comments;   create policy cm_ins on comments for insert to authenticated with check (user_id = auth.uid() and is_member(league_id));
drop policy if exists cd_read on cards;      create policy cd_read on cards for select to authenticated using (is_member(league_id));
drop policy if exists cd_ins on cards;       create policy cd_ins on cards for insert to authenticated with check (from_id = auth.uid() and is_member(league_id));
drop policy if exists lk_read on likes;      create policy lk_read on likes for select to authenticated using (is_member(league_id));
drop policy if exists lk_ins on likes;       create policy lk_ins on likes for insert to authenticated with check (user_id = auth.uid() and is_member(league_id));
drop policy if exists lk_del on likes;       create policy lk_del on likes for delete to authenticated using (user_id = auth.uid());
-- 🏆 bracket picks: read in your leagues; you can only insert/update/delete your own.
drop policy if exists bp_read on bracket_picks; create policy bp_read on bracket_picks for select to authenticated using (is_member(league_id));
drop policy if exists bp_ins on bracket_picks;  create policy bp_ins on bracket_picks for insert to authenticated with check (user_id = auth.uid() and is_member(league_id));
drop policy if exists bp_upd on bracket_picks;  create policy bp_upd on bracket_picks for update to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());
drop policy if exists bp_del on bracket_picks;  create policy bp_del on bracket_picks for delete to authenticated using (user_id = auth.uid());

-- 🛠️ SUPER-ADMIN escape hatches — when profiles.is_admin = true, the admin can SEE and DELETE every row.
-- Pairs with the in-app password gate (admin/1234) which flips your is_admin flag on unlock and back off on exit.
-- READ overrides — admin sees data in EVERY league, not just the ones they're a member of.
drop policy if exists mb_read on memberships;       create policy mb_read on memberships     for select to authenticated using (user_id = auth.uid() or is_member(league_id) or is_admin());
drop policy if exists pred_read on predictions;     create policy pred_read on predictions   for select to authenticated using (is_admin() or (is_member(league_id) and (user_id = auth.uid() or public.has_pick(match_id, league_id) or exists (select 1 from matches m where m.id = predictions.match_id and (m.status='finished' or m.kickoff <= now())))));
drop policy if exists pa_read on prop_answers;      create policy pa_read on prop_answers   for select to authenticated using (is_admin() or (is_member(league_id) and (user_id = auth.uid() or public.has_answer(prop_id, league_id) or exists (select 1 from props p where p.id = prop_answers.prop_id and p.status='settled'))));
drop policy if exists adv_read on advances;         create policy adv_read on advances       for select to authenticated using (is_member(league_id) or is_admin());
drop policy if exists ko_read on ko_picks;          create policy ko_read on ko_picks         for select to authenticated using (is_member(league_id) or is_admin());
drop policy if exists rp_read on repicks;           create policy rp_read on repicks         for select to authenticated using (is_member(league_id) or is_admin());
drop policy if exists bp_read on bracket_picks;     create policy bp_read on bracket_picks   for select to authenticated using (is_member(league_id) or is_admin());
drop policy if exists cm_read on comments;          create policy cm_read on comments         for select to authenticated using (is_member(league_id) or is_admin());
drop policy if exists cd_read on cards;             create policy cd_read on cards             for select to authenticated using (is_member(league_id) or is_admin());
drop policy if exists lk_read on likes;             create policy lk_read on likes             for select to authenticated using (is_member(league_id) or is_admin());
-- DELETE overrides — admin can wipe any row.
drop policy if exists pred_admin_del on predictions;     create policy pred_admin_del on predictions     for delete to authenticated using (is_admin());
drop policy if exists pa_admin_del on prop_answers;      create policy pa_admin_del on prop_answers     for delete to authenticated using (is_admin());
drop policy if exists adv_admin_del on advances;         create policy adv_admin_del on advances         for delete to authenticated using (is_admin());
drop policy if exists ko_admin_del on ko_picks;          create policy ko_admin_del on ko_picks          for delete to authenticated using (is_admin());
drop policy if exists rp_admin_del on repicks;           create policy rp_admin_del on repicks           for delete to authenticated using (is_admin());
drop policy if exists bp_admin_del on bracket_picks;     create policy bp_admin_del on bracket_picks     for delete to authenticated using (is_admin());
drop policy if exists cm_admin_del on comments;          create policy cm_admin_del on comments          for delete to authenticated using (is_admin());
drop policy if exists cd_admin_del on cards;             create policy cd_admin_del on cards             for delete to authenticated using (is_admin());
drop policy if exists lk_admin_del on likes;             create policy lk_admin_del on likes             for delete using (user_id = auth.uid() or is_admin());
drop policy if exists mb_admin_del on memberships;       create policy mb_admin_del on memberships       for delete to authenticated using (user_id = auth.uid() or is_admin() or exists(select 1 from leagues l where l.id = league_id and l.created_by = auth.uid()));
drop policy if exists lg_del on leagues;                 create policy lg_del on leagues                 for delete to authenticated using (created_by = auth.uid() or is_admin());
drop policy if exists p_del on profiles;                 create policy p_del on profiles                 for delete to authenticated using (is_admin());

-- ============================================================================
--  SEED DATA  (real 2026 World Cup draw, official matchday dates, props)
-- ============================================================================

-- 48 teams
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

-- 72 group-stage fixtures (real dates; re-running updates kickoff without touching scores)
insert into matches (id,stage,grp,md,home,away,kickoff,home_score,away_score,status) values ('G-A-1','group','A',1,'A1','A2','2026-06-11T20:00:00-04:00',null,null,'scheduled') on conflict (id) do update set kickoff=excluded.kickoff, grp=excluded.grp, md=excluded.md, home=excluded.home, away=excluded.away;
insert into matches (id,stage,grp,md,home,away,kickoff,home_score,away_score,status) values ('G-A-2','group','A',1,'A3','A4','2026-06-11T15:00:00-04:00',null,null,'scheduled') on conflict (id) do update set kickoff=excluded.kickoff, grp=excluded.grp, md=excluded.md, home=excluded.home, away=excluded.away;
insert into matches (id,stage,grp,md,home,away,kickoff,home_score,away_score,status) values ('G-A-3','group','A',2,'A1','A3','2026-06-18T18:00:00-04:00',null,null,'scheduled') on conflict (id) do update set kickoff=excluded.kickoff, grp=excluded.grp, md=excluded.md, home=excluded.home, away=excluded.away;
insert into matches (id,stage,grp,md,home,away,kickoff,home_score,away_score,status) values ('G-A-4','group','A',2,'A4','A2','2026-06-18T21:00:00-04:00',null,null,'scheduled') on conflict (id) do update set kickoff=excluded.kickoff, grp=excluded.grp, md=excluded.md, home=excluded.home, away=excluded.away;
insert into matches (id,stage,grp,md,home,away,kickoff,home_score,away_score,status) values ('G-A-5','group','A',3,'A4','A1','2026-06-24T12:00:00-04:00',null,null,'scheduled') on conflict (id) do update set kickoff=excluded.kickoff, grp=excluded.grp, md=excluded.md, home=excluded.home, away=excluded.away;
insert into matches (id,stage,grp,md,home,away,kickoff,home_score,away_score,status) values ('G-A-6','group','A',3,'A2','A3','2026-06-24T15:00:00-04:00',null,null,'scheduled') on conflict (id) do update set kickoff=excluded.kickoff, grp=excluded.grp, md=excluded.md, home=excluded.home, away=excluded.away;
insert into matches (id,stage,grp,md,home,away,kickoff,home_score,away_score,status) values ('G-B-1','group','B',1,'B1','B2','2026-06-12T15:00:00-04:00',null,null,'scheduled') on conflict (id) do update set kickoff=excluded.kickoff, grp=excluded.grp, md=excluded.md, home=excluded.home, away=excluded.away;
insert into matches (id,stage,grp,md,home,away,kickoff,home_score,away_score,status) values ('G-B-2','group','B',1,'B3','B4','2026-06-12T18:00:00-04:00',null,null,'scheduled') on conflict (id) do update set kickoff=excluded.kickoff, grp=excluded.grp, md=excluded.md, home=excluded.home, away=excluded.away;
insert into matches (id,stage,grp,md,home,away,kickoff,home_score,away_score,status) values ('G-B-3','group','B',2,'B1','B3','2026-06-18T21:00:00-04:00',null,null,'scheduled') on conflict (id) do update set kickoff=excluded.kickoff, grp=excluded.grp, md=excluded.md, home=excluded.home, away=excluded.away;
insert into matches (id,stage,grp,md,home,away,kickoff,home_score,away_score,status) values ('G-B-4','group','B',2,'B4','B2','2026-06-18T12:00:00-04:00',null,null,'scheduled') on conflict (id) do update set kickoff=excluded.kickoff, grp=excluded.grp, md=excluded.md, home=excluded.home, away=excluded.away;
insert into matches (id,stage,grp,md,home,away,kickoff,home_score,away_score,status) values ('G-B-5','group','B',3,'B4','B1','2026-06-24T15:00:00-04:00',null,null,'scheduled') on conflict (id) do update set kickoff=excluded.kickoff, grp=excluded.grp, md=excluded.md, home=excluded.home, away=excluded.away;
insert into matches (id,stage,grp,md,home,away,kickoff,home_score,away_score,status) values ('G-B-6','group','B',3,'B2','B3','2026-06-24T18:00:00-04:00',null,null,'scheduled') on conflict (id) do update set kickoff=excluded.kickoff, grp=excluded.grp, md=excluded.md, home=excluded.home, away=excluded.away;
insert into matches (id,stage,grp,md,home,away,kickoff,home_score,away_score,status) values ('G-C-1','group','C',1,'C1','C2','2026-06-13T18:00:00-04:00',null,null,'scheduled') on conflict (id) do update set kickoff=excluded.kickoff, grp=excluded.grp, md=excluded.md, home=excluded.home, away=excluded.away;
insert into matches (id,stage,grp,md,home,away,kickoff,home_score,away_score,status) values ('G-C-2','group','C',1,'C3','C4','2026-06-13T21:00:00-04:00',null,null,'scheduled') on conflict (id) do update set kickoff=excluded.kickoff, grp=excluded.grp, md=excluded.md, home=excluded.home, away=excluded.away;
insert into matches (id,stage,grp,md,home,away,kickoff,home_score,away_score,status) values ('G-C-3','group','C',2,'C1','C3','2026-06-19T12:00:00-04:00',null,null,'scheduled') on conflict (id) do update set kickoff=excluded.kickoff, grp=excluded.grp, md=excluded.md, home=excluded.home, away=excluded.away;
insert into matches (id,stage,grp,md,home,away,kickoff,home_score,away_score,status) values ('G-C-4','group','C',2,'C4','C2','2026-06-19T15:00:00-04:00',null,null,'scheduled') on conflict (id) do update set kickoff=excluded.kickoff, grp=excluded.grp, md=excluded.md, home=excluded.home, away=excluded.away;
insert into matches (id,stage,grp,md,home,away,kickoff,home_score,away_score,status) values ('G-C-5','group','C',3,'C4','C1','2026-06-24T18:00:00-04:00',null,null,'scheduled') on conflict (id) do update set kickoff=excluded.kickoff, grp=excluded.grp, md=excluded.md, home=excluded.home, away=excluded.away;
insert into matches (id,stage,grp,md,home,away,kickoff,home_score,away_score,status) values ('G-C-6','group','C',3,'C2','C3','2026-06-24T21:00:00-04:00',null,null,'scheduled') on conflict (id) do update set kickoff=excluded.kickoff, grp=excluded.grp, md=excluded.md, home=excluded.home, away=excluded.away;
insert into matches (id,stage,grp,md,home,away,kickoff,home_score,away_score,status) values ('G-D-1','group','D',1,'D1','D2','2026-06-12T21:00:00-04:00',null,null,'scheduled') on conflict (id) do update set kickoff=excluded.kickoff, grp=excluded.grp, md=excluded.md, home=excluded.home, away=excluded.away;
insert into matches (id,stage,grp,md,home,away,kickoff,home_score,away_score,status) values ('G-D-2','group','D',1,'D3','D4','2026-06-12T12:00:00-04:00',null,null,'scheduled') on conflict (id) do update set kickoff=excluded.kickoff, grp=excluded.grp, md=excluded.md, home=excluded.home, away=excluded.away;
insert into matches (id,stage,grp,md,home,away,kickoff,home_score,away_score,status) values ('G-D-3','group','D',2,'D1','D3','2026-06-19T15:00:00-04:00',null,null,'scheduled') on conflict (id) do update set kickoff=excluded.kickoff, grp=excluded.grp, md=excluded.md, home=excluded.home, away=excluded.away;
insert into matches (id,stage,grp,md,home,away,kickoff,home_score,away_score,status) values ('G-D-4','group','D',2,'D4','D2','2026-06-19T18:00:00-04:00',null,null,'scheduled') on conflict (id) do update set kickoff=excluded.kickoff, grp=excluded.grp, md=excluded.md, home=excluded.home, away=excluded.away;
insert into matches (id,stage,grp,md,home,away,kickoff,home_score,away_score,status) values ('G-D-5','group','D',3,'D4','D1','2026-06-25T21:00:00-04:00',null,null,'scheduled') on conflict (id) do update set kickoff=excluded.kickoff, grp=excluded.grp, md=excluded.md, home=excluded.home, away=excluded.away;
insert into matches (id,stage,grp,md,home,away,kickoff,home_score,away_score,status) values ('G-D-6','group','D',3,'D2','D3','2026-06-25T12:00:00-04:00',null,null,'scheduled') on conflict (id) do update set kickoff=excluded.kickoff, grp=excluded.grp, md=excluded.md, home=excluded.home, away=excluded.away;
insert into matches (id,stage,grp,md,home,away,kickoff,home_score,away_score,status) values ('G-E-1','group','E',1,'E1','E2','2026-06-14T12:00:00-04:00',null,null,'scheduled') on conflict (id) do update set kickoff=excluded.kickoff, grp=excluded.grp, md=excluded.md, home=excluded.home, away=excluded.away;
insert into matches (id,stage,grp,md,home,away,kickoff,home_score,away_score,status) values ('G-E-2','group','E',1,'E3','E4','2026-06-14T15:00:00-04:00',null,null,'scheduled') on conflict (id) do update set kickoff=excluded.kickoff, grp=excluded.grp, md=excluded.md, home=excluded.home, away=excluded.away;
insert into matches (id,stage,grp,md,home,away,kickoff,home_score,away_score,status) values ('G-E-3','group','E',2,'E1','E3','2026-06-20T18:00:00-04:00',null,null,'scheduled') on conflict (id) do update set kickoff=excluded.kickoff, grp=excluded.grp, md=excluded.md, home=excluded.home, away=excluded.away;
insert into matches (id,stage,grp,md,home,away,kickoff,home_score,away_score,status) values ('G-E-4','group','E',2,'E4','E2','2026-06-20T21:00:00-04:00',null,null,'scheduled') on conflict (id) do update set kickoff=excluded.kickoff, grp=excluded.grp, md=excluded.md, home=excluded.home, away=excluded.away;
insert into matches (id,stage,grp,md,home,away,kickoff,home_score,away_score,status) values ('G-E-5','group','E',3,'E4','E1','2026-06-25T12:00:00-04:00',null,null,'scheduled') on conflict (id) do update set kickoff=excluded.kickoff, grp=excluded.grp, md=excluded.md, home=excluded.home, away=excluded.away;
insert into matches (id,stage,grp,md,home,away,kickoff,home_score,away_score,status) values ('G-E-6','group','E',3,'E2','E3','2026-06-25T15:00:00-04:00',null,null,'scheduled') on conflict (id) do update set kickoff=excluded.kickoff, grp=excluded.grp, md=excluded.md, home=excluded.home, away=excluded.away;
insert into matches (id,stage,grp,md,home,away,kickoff,home_score,away_score,status) values ('G-F-1','group','F',1,'F1','F2','2026-06-14T15:00:00-04:00',null,null,'scheduled') on conflict (id) do update set kickoff=excluded.kickoff, grp=excluded.grp, md=excluded.md, home=excluded.home, away=excluded.away;
insert into matches (id,stage,grp,md,home,away,kickoff,home_score,away_score,status) values ('G-F-2','group','F',1,'F3','F4','2026-06-14T18:00:00-04:00',null,null,'scheduled') on conflict (id) do update set kickoff=excluded.kickoff, grp=excluded.grp, md=excluded.md, home=excluded.home, away=excluded.away;
insert into matches (id,stage,grp,md,home,away,kickoff,home_score,away_score,status) values ('G-F-3','group','F',2,'F1','F3','2026-06-20T21:00:00-04:00',null,null,'scheduled') on conflict (id) do update set kickoff=excluded.kickoff, grp=excluded.grp, md=excluded.md, home=excluded.home, away=excluded.away;
insert into matches (id,stage,grp,md,home,away,kickoff,home_score,away_score,status) values ('G-F-4','group','F',2,'F4','F2','2026-06-20T12:00:00-04:00',null,null,'scheduled') on conflict (id) do update set kickoff=excluded.kickoff, grp=excluded.grp, md=excluded.md, home=excluded.home, away=excluded.away;
insert into matches (id,stage,grp,md,home,away,kickoff,home_score,away_score,status) values ('G-F-5','group','F',3,'F4','F1','2026-06-25T15:00:00-04:00',null,null,'scheduled') on conflict (id) do update set kickoff=excluded.kickoff, grp=excluded.grp, md=excluded.md, home=excluded.home, away=excluded.away;
insert into matches (id,stage,grp,md,home,away,kickoff,home_score,away_score,status) values ('G-F-6','group','F',3,'F2','F3','2026-06-25T18:00:00-04:00',null,null,'scheduled') on conflict (id) do update set kickoff=excluded.kickoff, grp=excluded.grp, md=excluded.md, home=excluded.home, away=excluded.away;
insert into matches (id,stage,grp,md,home,away,kickoff,home_score,away_score,status) values ('G-G-1','group','G',1,'G1','G2','2026-06-15T18:00:00-04:00',null,null,'scheduled') on conflict (id) do update set kickoff=excluded.kickoff, grp=excluded.grp, md=excluded.md, home=excluded.home, away=excluded.away;
insert into matches (id,stage,grp,md,home,away,kickoff,home_score,away_score,status) values ('G-G-2','group','G',1,'G3','G4','2026-06-15T21:00:00-04:00',null,null,'scheduled') on conflict (id) do update set kickoff=excluded.kickoff, grp=excluded.grp, md=excluded.md, home=excluded.home, away=excluded.away;
insert into matches (id,stage,grp,md,home,away,kickoff,home_score,away_score,status) values ('G-G-3','group','G',2,'G1','G3','2026-06-21T12:00:00-04:00',null,null,'scheduled') on conflict (id) do update set kickoff=excluded.kickoff, grp=excluded.grp, md=excluded.md, home=excluded.home, away=excluded.away;
insert into matches (id,stage,grp,md,home,away,kickoff,home_score,away_score,status) values ('G-G-4','group','G',2,'G4','G2','2026-06-21T15:00:00-04:00',null,null,'scheduled') on conflict (id) do update set kickoff=excluded.kickoff, grp=excluded.grp, md=excluded.md, home=excluded.home, away=excluded.away;
insert into matches (id,stage,grp,md,home,away,kickoff,home_score,away_score,status) values ('G-G-5','group','G',3,'G4','G1','2026-06-26T18:00:00-04:00',null,null,'scheduled') on conflict (id) do update set kickoff=excluded.kickoff, grp=excluded.grp, md=excluded.md, home=excluded.home, away=excluded.away;
insert into matches (id,stage,grp,md,home,away,kickoff,home_score,away_score,status) values ('G-G-6','group','G',3,'G2','G3','2026-06-26T21:00:00-04:00',null,null,'scheduled') on conflict (id) do update set kickoff=excluded.kickoff, grp=excluded.grp, md=excluded.md, home=excluded.home, away=excluded.away;
insert into matches (id,stage,grp,md,home,away,kickoff,home_score,away_score,status) values ('G-H-1','group','H',1,'H1','H2','2026-06-15T21:00:00-04:00',null,null,'scheduled') on conflict (id) do update set kickoff=excluded.kickoff, grp=excluded.grp, md=excluded.md, home=excluded.home, away=excluded.away;
insert into matches (id,stage,grp,md,home,away,kickoff,home_score,away_score,status) values ('G-H-2','group','H',1,'H3','H4','2026-06-15T12:00:00-04:00',null,null,'scheduled') on conflict (id) do update set kickoff=excluded.kickoff, grp=excluded.grp, md=excluded.md, home=excluded.home, away=excluded.away;
insert into matches (id,stage,grp,md,home,away,kickoff,home_score,away_score,status) values ('G-H-3','group','H',2,'H1','H3','2026-06-21T15:00:00-04:00',null,null,'scheduled') on conflict (id) do update set kickoff=excluded.kickoff, grp=excluded.grp, md=excluded.md, home=excluded.home, away=excluded.away;
insert into matches (id,stage,grp,md,home,away,kickoff,home_score,away_score,status) values ('G-H-4','group','H',2,'H4','H2','2026-06-21T18:00:00-04:00',null,null,'scheduled') on conflict (id) do update set kickoff=excluded.kickoff, grp=excluded.grp, md=excluded.md, home=excluded.home, away=excluded.away;
insert into matches (id,stage,grp,md,home,away,kickoff,home_score,away_score,status) values ('G-H-5','group','H',3,'H4','H1','2026-06-26T21:00:00-04:00',null,null,'scheduled') on conflict (id) do update set kickoff=excluded.kickoff, grp=excluded.grp, md=excluded.md, home=excluded.home, away=excluded.away;
insert into matches (id,stage,grp,md,home,away,kickoff,home_score,away_score,status) values ('G-H-6','group','H',3,'H2','H3','2026-06-26T12:00:00-04:00',null,null,'scheduled') on conflict (id) do update set kickoff=excluded.kickoff, grp=excluded.grp, md=excluded.md, home=excluded.home, away=excluded.away;
insert into matches (id,stage,grp,md,home,away,kickoff,home_score,away_score,status) values ('G-I-1','group','I',1,'I1','I2','2026-06-16T12:00:00-04:00',null,null,'scheduled') on conflict (id) do update set kickoff=excluded.kickoff, grp=excluded.grp, md=excluded.md, home=excluded.home, away=excluded.away;
insert into matches (id,stage,grp,md,home,away,kickoff,home_score,away_score,status) values ('G-I-2','group','I',1,'I3','I4','2026-06-16T15:00:00-04:00',null,null,'scheduled') on conflict (id) do update set kickoff=excluded.kickoff, grp=excluded.grp, md=excluded.md, home=excluded.home, away=excluded.away;
insert into matches (id,stage,grp,md,home,away,kickoff,home_score,away_score,status) values ('G-I-3','group','I',2,'I1','I3','2026-06-22T18:00:00-04:00',null,null,'scheduled') on conflict (id) do update set kickoff=excluded.kickoff, grp=excluded.grp, md=excluded.md, home=excluded.home, away=excluded.away;
insert into matches (id,stage,grp,md,home,away,kickoff,home_score,away_score,status) values ('G-I-4','group','I',2,'I4','I2','2026-06-22T21:00:00-04:00',null,null,'scheduled') on conflict (id) do update set kickoff=excluded.kickoff, grp=excluded.grp, md=excluded.md, home=excluded.home, away=excluded.away;
insert into matches (id,stage,grp,md,home,away,kickoff,home_score,away_score,status) values ('G-I-5','group','I',3,'I4','I1','2026-06-26T12:00:00-04:00',null,null,'scheduled') on conflict (id) do update set kickoff=excluded.kickoff, grp=excluded.grp, md=excluded.md, home=excluded.home, away=excluded.away;
insert into matches (id,stage,grp,md,home,away,kickoff,home_score,away_score,status) values ('G-I-6','group','I',3,'I2','I3','2026-06-26T15:00:00-04:00',null,null,'scheduled') on conflict (id) do update set kickoff=excluded.kickoff, grp=excluded.grp, md=excluded.md, home=excluded.home, away=excluded.away;
insert into matches (id,stage,grp,md,home,away,kickoff,home_score,away_score,status) values ('G-J-1','group','J',1,'J1','J2','2026-06-16T15:00:00-04:00',null,null,'scheduled') on conflict (id) do update set kickoff=excluded.kickoff, grp=excluded.grp, md=excluded.md, home=excluded.home, away=excluded.away;
insert into matches (id,stage,grp,md,home,away,kickoff,home_score,away_score,status) values ('G-J-2','group','J',1,'J3','J4','2026-06-16T18:00:00-04:00',null,null,'scheduled') on conflict (id) do update set kickoff=excluded.kickoff, grp=excluded.grp, md=excluded.md, home=excluded.home, away=excluded.away;
insert into matches (id,stage,grp,md,home,away,kickoff,home_score,away_score,status) values ('G-J-3','group','J',2,'J1','J3','2026-06-22T21:00:00-04:00',null,null,'scheduled') on conflict (id) do update set kickoff=excluded.kickoff, grp=excluded.grp, md=excluded.md, home=excluded.home, away=excluded.away;
insert into matches (id,stage,grp,md,home,away,kickoff,home_score,away_score,status) values ('G-J-4','group','J',2,'J4','J2','2026-06-22T12:00:00-04:00',null,null,'scheduled') on conflict (id) do update set kickoff=excluded.kickoff, grp=excluded.grp, md=excluded.md, home=excluded.home, away=excluded.away;
insert into matches (id,stage,grp,md,home,away,kickoff,home_score,away_score,status) values ('G-J-5','group','J',3,'J4','J1','2026-06-27T15:00:00-04:00',null,null,'scheduled') on conflict (id) do update set kickoff=excluded.kickoff, grp=excluded.grp, md=excluded.md, home=excluded.home, away=excluded.away;
insert into matches (id,stage,grp,md,home,away,kickoff,home_score,away_score,status) values ('G-J-6','group','J',3,'J2','J3','2026-06-27T18:00:00-04:00',null,null,'scheduled') on conflict (id) do update set kickoff=excluded.kickoff, grp=excluded.grp, md=excluded.md, home=excluded.home, away=excluded.away;
insert into matches (id,stage,grp,md,home,away,kickoff,home_score,away_score,status) values ('G-K-1','group','K',1,'K1','K2','2026-06-17T18:00:00-04:00',null,null,'scheduled') on conflict (id) do update set kickoff=excluded.kickoff, grp=excluded.grp, md=excluded.md, home=excluded.home, away=excluded.away;
insert into matches (id,stage,grp,md,home,away,kickoff,home_score,away_score,status) values ('G-K-2','group','K',1,'K3','K4','2026-06-17T21:00:00-04:00',null,null,'scheduled') on conflict (id) do update set kickoff=excluded.kickoff, grp=excluded.grp, md=excluded.md, home=excluded.home, away=excluded.away;
insert into matches (id,stage,grp,md,home,away,kickoff,home_score,away_score,status) values ('G-K-3','group','K',2,'K1','K3','2026-06-23T12:00:00-04:00',null,null,'scheduled') on conflict (id) do update set kickoff=excluded.kickoff, grp=excluded.grp, md=excluded.md, home=excluded.home, away=excluded.away;
insert into matches (id,stage,grp,md,home,away,kickoff,home_score,away_score,status) values ('G-K-4','group','K',2,'K4','K2','2026-06-23T15:00:00-04:00',null,null,'scheduled') on conflict (id) do update set kickoff=excluded.kickoff, grp=excluded.grp, md=excluded.md, home=excluded.home, away=excluded.away;
insert into matches (id,stage,grp,md,home,away,kickoff,home_score,away_score,status) values ('G-K-5','group','K',3,'K4','K1','2026-06-27T18:00:00-04:00',null,null,'scheduled') on conflict (id) do update set kickoff=excluded.kickoff, grp=excluded.grp, md=excluded.md, home=excluded.home, away=excluded.away;
insert into matches (id,stage,grp,md,home,away,kickoff,home_score,away_score,status) values ('G-K-6','group','K',3,'K2','K3','2026-06-27T21:00:00-04:00',null,null,'scheduled') on conflict (id) do update set kickoff=excluded.kickoff, grp=excluded.grp, md=excluded.md, home=excluded.home, away=excluded.away;
insert into matches (id,stage,grp,md,home,away,kickoff,home_score,away_score,status) values ('G-L-1','group','L',1,'L1','L2','2026-06-17T21:00:00-04:00',null,null,'scheduled') on conflict (id) do update set kickoff=excluded.kickoff, grp=excluded.grp, md=excluded.md, home=excluded.home, away=excluded.away;
insert into matches (id,stage,grp,md,home,away,kickoff,home_score,away_score,status) values ('G-L-2','group','L',1,'L3','L4','2026-06-17T12:00:00-04:00',null,null,'scheduled') on conflict (id) do update set kickoff=excluded.kickoff, grp=excluded.grp, md=excluded.md, home=excluded.home, away=excluded.away;
insert into matches (id,stage,grp,md,home,away,kickoff,home_score,away_score,status) values ('G-L-3','group','L',2,'L1','L3','2026-06-23T15:00:00-04:00',null,null,'scheduled') on conflict (id) do update set kickoff=excluded.kickoff, grp=excluded.grp, md=excluded.md, home=excluded.home, away=excluded.away;
insert into matches (id,stage,grp,md,home,away,kickoff,home_score,away_score,status) values ('G-L-4','group','L',2,'L4','L2','2026-06-23T18:00:00-04:00',null,null,'scheduled') on conflict (id) do update set kickoff=excluded.kickoff, grp=excluded.grp, md=excluded.md, home=excluded.home, away=excluded.away;
insert into matches (id,stage,grp,md,home,away,kickoff,home_score,away_score,status) values ('G-L-5','group','L',3,'L4','L1','2026-06-27T21:00:00-04:00',null,null,'scheduled') on conflict (id) do update set kickoff=excluded.kickoff, grp=excluded.grp, md=excluded.md, home=excluded.home, away=excluded.away;
insert into matches (id,stage,grp,md,home,away,kickoff,home_score,away_score,status) values ('G-L-6','group','L',3,'L2','L3','2026-06-27T12:00:00-04:00',null,null,'scheduled') on conflict (id) do update set kickoff=excluded.kickoff, grp=excluded.grp, md=excluded.md, home=excluded.home, away=excluded.away;

-- prop bets
insert into props (id,icon,q,type,options,line,pts,status,correct,allow_coins) values ('p-goat','🐐','Settle it — who''s the GOAT? (choose wisely 😉)','mc','[{"v":"zlatan","label":"🇸🇪 Zlatan"},{"v":"ronaldo","label":"🇵🇹 Ronaldo"}]'::jsonb,null,1,'open',null,false) on conflict (id) do nothing;
insert into props (id,icon,q,type,options,line,pts,status,correct,allow_coins) values ('p-champ','🏆','Who lifts the trophy?','team','[{"v":"A1","label":"🇲🇽 Mexico"},{"v":"A2","label":"🇿🇦 South Africa"},{"v":"A3","label":"🇰🇷 South Korea"},{"v":"A4","label":"🇨🇿 Czechia"},{"v":"B1","label":"🇨🇦 Canada"},{"v":"B2","label":"🇨🇭 Switzerland"},{"v":"B3","label":"🇶🇦 Qatar"},{"v":"B4","label":"🇧🇦 Bosnia & Herz."},{"v":"C1","label":"🇧🇷 Brazil"},{"v":"C2","label":"🇲🇦 Morocco"},{"v":"C3","label":"🇭🇹 Haiti"},{"v":"C4","label":"🏴󠁧󠁢󠁳󠁣󠁴󠁿 Scotland"},{"v":"D1","label":"🇺🇸 USA"},{"v":"D2","label":"🇵🇾 Paraguay"},{"v":"D3","label":"🇦🇺 Australia"},{"v":"D4","label":"🇹🇷 Türkiye"},{"v":"E1","label":"🇩🇪 Germany"},{"v":"E2","label":"🇨🇼 Curaçao"},{"v":"E3","label":"🇨🇮 Côte d''Ivoire"},{"v":"E4","label":"🇪🇨 Ecuador"},{"v":"F1","label":"🇳🇱 Netherlands"},{"v":"F2","label":"🇯🇵 Japan"},{"v":"F3","label":"🇹🇳 Tunisia"},{"v":"F4","label":"🇸🇪 Sweden"},{"v":"G1","label":"🇧🇪 Belgium"},{"v":"G2","label":"🇪🇬 Egypt"},{"v":"G3","label":"🇮🇷 Iran"},{"v":"G4","label":"🇳🇿 New Zealand"},{"v":"H1","label":"🇪🇸 Spain"},{"v":"H2","label":"🇨🇻 Cabo Verde"},{"v":"H3","label":"🇸🇦 Saudi Arabia"},{"v":"H4","label":"🇺🇾 Uruguay"},{"v":"I1","label":"🇫🇷 France"},{"v":"I2","label":"🇸🇳 Senegal"},{"v":"I3","label":"🇳🇴 Norway"},{"v":"I4","label":"🇮🇶 Iraq"},{"v":"J1","label":"🇦🇷 Argentina"},{"v":"J2","label":"🇩🇿 Algeria"},{"v":"J3","label":"🇦🇹 Austria"},{"v":"J4","label":"🇯🇴 Jordan"},{"v":"K1","label":"🇵🇹 Portugal"},{"v":"K2","label":"🇺🇿 Uzbekistan"},{"v":"K3","label":"🇨🇴 Colombia"},{"v":"K4","label":"🇨🇩 DR Congo"},{"v":"L1","label":"🏴󠁧󠁢󠁥󠁮󠁧󠁿 England"},{"v":"L2","label":"🇭🇷 Croatia"},{"v":"L3","label":"🇬🇭 Ghana"},{"v":"L4","label":"🇵🇦 Panama"}]'::jsonb,null,30,'open',null,true) on conflict (id) do nothing;
insert into props (id,icon,q,type,options,line,pts,status,correct,allow_coins) values ('p-flop','😱','Which giant FLOPS out in the group stage?','mc','[{"v":"Brazil","label":"🇧🇷 Brazil"},{"v":"Argentina","label":"🇦🇷 Argentina"},{"v":"France","label":"🇫🇷 France"},{"v":"Spain","label":"🇪🇸 Spain"},{"v":"England","label":"🏴 England"},{"v":"Germany","label":"🇩🇪 Germany"},{"v":"none","label":"🛡️ None of them (boring)"}]'::jsonb,null,8,'open',null,true) on conflict (id) do nothing;
insert into props (id,icon,q,type,options,line,pts,status,correct,allow_coins) values ('p-cinderella','🐴','Best Cinderella run — which underdog goes furthest?','mc','[{"v":"Haiti","label":"🇭🇹 Haiti"},{"v":"Curaçao","label":"🇨🇼 Curaçao"},{"v":"Cabo Verde","label":"🇨🇻 Cabo Verde"},{"v":"Jordan","label":"🇯🇴 Jordan"},{"v":"Panama","label":"🇵🇦 Panama"},{"v":"Uzbekistan","label":"🇺🇿 Uzbekistan"},{"v":"New Zealand","label":"🇳🇿 New Zealand"}]'::jsonb,null,10,'open',null,true) on conflict (id) do nothing;
insert into props (id,icon,q,type,options,line,pts,status,correct,allow_coins) values ('p-usa','🦅','Do the host USA escape Group D?','yesno',null,null,5,'open',null,true) on conflict (id) do nothing;
insert into props (id,icon,q,type,options,line,pts,status,correct,allow_coins) values ('p-pens','🥅','Will the FINAL go to penalties?','yesno',null,null,6,'open',null,false) on conflict (id) do nothing;
insert into props (id,icon,q,type,options,line,pts,status,correct,allow_coins) values ('p-boot','⚽','Golden Boot top scorer — total goals?','ou',null,7.5,6,'open',null,false) on conflict (id) do nothing;
insert into props (id,icon,q,type,options,line,pts,status,correct,allow_coins) values ('p-reds','🟥','Total red cards in the whole tournament?','ou',null,18.5,5,'open',null,false) on conflict (id) do nothing;
insert into props (id,icon,q,type,options,line,pts,status,correct,allow_coins) values ('p-goals','🎯','Goals in the group stage (72 matches)?','ou',null,201.5,7,'open',null,false) on conflict (id) do nothing;

-- global scoring settings (re-running keeps these in sync)
insert into settings (id,app_title,starting_coins,pts_exact,pts_result,pts_advance,buy_in,currency,payout_split,bet_basis,ko) values (1,'THE MASK',1000,5,2,4,50,'USD','[50,30,20]'::jsonb,'points','{"r16":[],"qf":[],"sf":[],"final":[]}'::jsonb) on conflict (id) do update set app_title=excluded.app_title, buy_in=excluded.buy_in, currency=excluded.currency;

-- ============================================================================
--  MIGRATION → PRIVATE LEAGUES
--  Puts every existing PLAYER + all their existing picks into one "Default League"
--  so nothing is lost when you upgrade. Safe to re-run.
--  🛡️ Admins are intentionally excluded — admin is a separate role with no league
--  participation, and must never appear as a player in any leaderboard or member list.
-- ============================================================================
insert into leagues (id,name,code,buy_in,currency,payout_split,created_by)
  values ('lg-default','THE MASK','MASK26',50,'USD','[50,30,20]'::jsonb,null)
  on conflict (id) do nothing;
-- everyone who already has a profile joins the Default League (carry over their paid flag)
insert into memberships (league_id,user_id,paid)
  select 'lg-default', id, coalesce(paid,false) from profiles
  on conflict (league_id,user_id) do nothing;
-- tag every pre-league pick to the Default League
update predictions  set league_id='lg-default' where league_id is null;
update prop_answers set league_id='lg-default' where league_id is null;
update advances     set league_id='lg-default' where league_id is null;
update ko_picks     set league_id='lg-default' where league_id is null;
update repicks      set league_id='lg-default' where league_id is null;

-- 🧹 Demote any LEGACY player profiles that got a stale is_admin=true flag from the old
-- "admin = elevate current player" flow. New architecture: admin is a separate account
-- (admin@themask.local). Anyone NOT that account who has is_admin=true is a misflag.
-- We keep their memberships and picks intact — they're a normal player.
update profiles
   set is_admin = false
 where coalesce(is_admin,false) = true
   and lower(coalesce(email,'')) <> 'admin@themask.local';

-- 🛡️ The dedicated admin account must never be a member of any league.
-- (After the demote above, this only matches admin@themask.local.)
delete from memberships m
  using profiles p
  where m.user_id = p.id and coalesce(p.is_admin,false) = true;

-- After running:
--   1. Authentication → Providers → Email: enable Email; uncheck "Confirm email"
--      (login is username + password under a fake @themask.local email — no real email
--      is ever sent, so confirmation must be off).
--   2. Player login: visit "/" → pick a username + password (6+ chars) + nation.
--   3. Admin login : visit "/admin" → username "admin", password "1234".
--      (The app internally pads the short admin password so Supabase's 6-char minimum
--      isn't a problem — change ADMIN_PASSWORD in index.html to override the friendly default.)
