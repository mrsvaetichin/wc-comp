# 🦇 THE MASK — your World Cup '26 pool

A playful prediction game for you and ~20 friends. Predict scorelines, call upsets,
throw virtual coins on longshots, talk trash, and split a real-money pot at the end.
Built around the **real 2026 World Cup draw** (all 12 groups, 72 group fixtures, opener
Mexico 🇲🇽 v South Africa 🇿🇦 on June 11), with a Gyökeres "mask" theme. Players log in
with **just a name — no email, no password.**

There are two ways to use it.

---

## 1. Try it right now (Demo mode — zero setup)

Open `index.html` in any browser and it boots straight into a fully playable game with
sample friends, results, and a live leaderboard. Make picks, hit the 🃏 Props tab, watch
the 📊 board move. Nothing here is shared — it's a private sandbox in your browser.

> Your live Supabase keys are already in the file, so opening it will show the **live login**.
> To poke around in demo instead, temporarily blank out `SUPABASE_URL` near the top of the script.

---

## 2. Go live for your friends (shared database, name-only login)

You're using **Supabase** (database + login) and **Vercel** (hosting). Here's the whole path.

### Step 1 — Create the tables
In your Supabase project: **SQL Editor → New query**, paste all of **`schema.sql`**, click
**Run**. This builds every table, the security rules, and seeds all 48 teams + 72 fixtures +
the prop bets. (Safe to re-run — and you **must** re-run it after any update, e.g. to apply the
blind-pick / immutable-pick rules and the Banker column.)

### Step 2 — Turn on name-only login
In Supabase: **Authentication → Sign In / Providers** → enable **"Allow anonymous sign-ins."**
That's what lets each friend join with just a name (the app creates an anonymous identity
behind the scenes, so the leaderboard and security rules still work — no email required).

### Step 3 — Your keys are already in
`index.html` already has your Project URL and anon public key filled in near the top:

```js
const SUPABASE_URL  = "https://bjetkgguswexwihossdt.supabase.co";
const SUPABASE_ANON  = "eyJ...";   // public anon key — safe to ship
const ADMIN_PASSWORD = "1234";     // change this to lock down the admin panel
```

(The anon key is meant to be public — it's protected by the security rules in `schema.sql`.
The **service key must never go in here** — and since it was shared earlier, rotate it in
**Project Settings → API**.)

### Step 4 — Deploy to Vercel
Your files sit at the repo root, so there's no Root Directory to set.

- **Git import:** push the folder to GitHub, import it in Vercel, **Framework Preset = Other**,
  no build command. Deploy.
- **CLI:** run `vercel` in the folder, then `vercel --prod`.

The included `vercel.json` serves the app and routes `/admin` correctly. No auth redirect URLs
to configure — anonymous login doesn't need them.

### Step 5 — Invite your friends
Send them the link. Each person types a **name**, picks an emoji badge, taps **Join the pool**,
and they're in. Their session is remembered on that device, so they won't have to do it again.

---

## Running the pool (you, the commissioner 🎩)

Admin is gated by a password — **no special account needed**.

1. Go to **`your-site/admin`** (or tap the 🔒 in the top-right of the app).
2. Enter the password (**default `1234`** — change `ADMIN_PASSWORD` in `index.html` to whatever
   you like). You'll get the 🛠️ Admin tab.

Inside Admin:

- **Results** — after each match, type the final score and hit *Finalize*. Everyone's points
  and coins recompute instantly, standings update, and completed groups auto-score the
  "who advances" picks.
- **Settle props** — pick the correct answer for a prop (champion, Golden Boot total, etc.) and
  settle; points and coin payouts go out automatically.
- **Settings** — buy-in amount, currency, payout split (default 50/30/20), pool name, and
  whether final payouts rank by points or coins. Flip who's paid in the 💰 Pool tab.

> In live mode, entering the admin password also flags your account as admin in the database so
> your result entries actually save. Anyone who knows the password becomes admin — it's a
> trust-based friends pool, so keep the password to yourself (and change it from `1234`).

---

## How scoring works

- **Blind & one-shot:** you can't see anyone else's pick for a game until you've **locked yours**
  (or it kicks off), and once locked a pick **can't be changed**. This is enforced both in the app
  and in the database rules.
- **Exact scoreline:** +5 points. **Correct result** (right winner/draw, wrong score): +2.
- **⭐ Banker:** mark one active pick as your Banker for **double** match points. You can have one
  going at a time; it frees up once that match finishes.
- **Group survivors:** +4 for each team you correctly tip to escape a group (auto-scored when
  the group finishes).
- **🏆 Knockout run:** in the Groups tab, pick the teams you think reach the Quarter-finals (+3
  each), Semi-finals (+5) and Final (+8). The commissioner marks who actually reached each stage
  in **Admin → Knockouts** and everyone scores instantly.
- **Prop bets:** each is worth its own points (the champion pick is a big 30).
- **💸 Buy-in:** it's **50 GEL to play** — paid to the commissioner; the top 3 split the pot.
  Change the amount/currency in **Admin → Settings**.
- **📸 Profile photos:** tap your avatar (top-right) to upload a photo or pick an emoji badge.
- **🔥 Streaks & badges:** consecutive correct results light a streak flame, and you earn badges
  (Sniper, Giant Slayer, On Fire, High Roller, Banker Boss) shown on the leaderboard + podium.
- **Coins** 🪙: everyone starts with 1,000. On matches and some props you can stake coins at
  auto-generated odds — underdogs pay more (winning it all as Haiti pays 300×). Coins drive a
  second leaderboard for bragging rights.
- **The pot** 💰: real-money buy-ins are tracked and projected payouts map to current standings.
  All values are adjustable in Admin.

---

## Customizing

- **Pool name, buy-in, split, settling** — change live in the Admin tab.
- **The background photo** — it's `gyok.jpg` in this folder. Drop in any image with that name
  to swap it (or rename and update the `#gyokbg` line in `index.html`).
- **Admin password** — `ADMIN_PASSWORD` near the top of `index.html`.
- **Props / teams / odds** — `seedProps()`, `GROUPS`, and `POWER` in `index.html` (and the seed
  in `schema.sql` for the live database).

After editing `index.html`, redeploy to Vercel.

---

## Good to know

- **Picks are blind until you commit** — you only see the crowd's picks for a game after you've
  locked your own (or after kickoff). Then it's a fun reveal of who said what.
- **Reload to see others' latest** picks/results — the app loads fresh data on open.
- **Anonymous logins** are per-device: if someone clears their browser data they'll start a new
  identity. Fine for a casual pool.
- **Real money:** the app only *tracks* who's in and what payouts would be — it never processes
  payments. Settle the cash yourselves (Venmo, cash, etc.) and keep it a friendly pool in line
  with the rules where you live.

Do the Gyökeres, and may your longshots come in. 🦇🏆
