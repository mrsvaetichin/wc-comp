# 🦇 THE MASK — your World Cup '26 pool

A playful prediction game for you and your friends. Predict scorelines, call upsets,
back who goes deep, talk trash, and split a real-money pot at the end.
Built around the **real 2026 World Cup draw** (all 12 groups, 72 group fixtures, opener
Mexico 🇲🇽 v South Africa 🇿🇦 on June 11), with a Gyökeres "mask" theme. Players log in
with **just a name — no email, no password.**

### 🏆 Private leagues
After signing in, each player **creates a league** (name + buy-in + currency) or **joins one
with an invite code/link** (`…/?join=CODE`). You can be in several leagues at once and switch
between them with the 🏆 chip in the header. Predictions, leaderboards and the pot are
**separate in each league**; the real World Cup results are shared and sync in automatically.

There are two ways to use it.

---

## 1. Try it right now (Demo mode — zero setup)

Open `index.html` in any browser and it boots straight into a fully playable game with
sample friends, results, and a live leaderboard. Make picks, hit the 🃏 Extras tab, watch
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

### Step 2 — Turn on username + password login (no email)
THE MASK uses username + password — friends never have to give an email address. Behind the
scenes the app uses Supabase's Email provider, but generates a fake `username@themask.local`
email that's never sent to or seen by anyone. For this to work you need two settings:

1. In Supabase: **Authentication → Providers → Email** — make sure **Email** is enabled, then
   **uncheck "Confirm email"** (so Supabase doesn't try to send a confirmation email to the
   fake address). Save.
2. In Supabase: **Authentication → Providers → Email** — keep the default "Enable email +
   password" on. Nothing else needs touching.

(You can leave "Allow anonymous sign-ins" OFF — the new flow doesn't use it.)

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

- **Results** — scores normally sync in **automatically** from a live feed. You can also type a
  final score and hit *Finalize* (or **🔄 Sync now**); everyone's points recompute instantly,
  standings update, and completed groups auto-score the "who advances" picks.
- **Settle props** — pick the correct answer for a prop (champion, Golden Boot total, etc.) and settle.
- **Knockouts** — mark which teams reached the QF / SF / Final to score everyone's knockout picks.
- **Settings** — buy-in amount, currency, payout split (default 50/30/20), pool name. Flip who's
  paid in the 💰 Pool tab.

> In live mode, entering the admin password also flags your account as admin in the database so
> your result entries actually save. Anyone who knows the password becomes admin — it's a
> trust-based friends pool, so keep the password to yourself (and change it from `1234`).

---

## How scoring works

It's **one simple Points pool** — no coins, no virtual currency. Most points wins.

- **Blind & one-shot:** you can't see anyone else's pick for a game until you've **locked yours**
  (or it kicks off), and once locked a pick **can't be changed**. Enforced in the app and in the DB.
- **Exact scoreline:** +5 points. **Correct result** (right winner/draw, wrong score): +2.
- **⭐ Banker:** mark one pick each round (MD1/MD2/MD3 of group stage + each knockout round) as
  your Banker for **double** match points. A fresh Banker every round, with no penalty if it misses.
- **🔁 Half-time re-pick:** 3 times all tournament you can change a pick on a **live** match,
  for **−3 points** each. Otherwise picks are final.
- **Group survivors:** +4 for each team you correctly tip to escape a group.
- **🏆 Knockout run:** this is how you bet on the games after the groups — pick which teams reach
  each stage: Round of 16 (+2 each), Quarter-finals (+3), Semi-finals (+5), Final (+8). The
  commissioner marks who actually reached each stage in **Admin → Knockouts** and it scores instantly.
- **⚽ Your team:** when you join you pick the nation you personally support (locked in for good).
  You earn **+3 points every time they win a match** — pick a nation that goes deep and it adds up fast.
- **Extras (tournament calls):** the 🃏 Extras tab holds whole-tournament predictions — champion (a big 30), top scorer, plus fun side questions — each worth its own points. **All Extras lock the moment Round 1 locks** (30 min before the first match), and everyone's answers stay completely blind until that moment — then the crowd is revealed on every card and the whole set is sealed for the rest of the tournament.
- **💬 Banter bonus:** the funniest people earn real points — and a lot of them. The top 3 on the Banter leaderboard (ranked by ❤️ likes on their posts) bank bonus points toward the main standings: **🥇 +15, 🥈 +10, 🥉 +5**. You need at least one like to place, and it updates live as likes come in — being witty can swing podium spots right up to the final whistle.
- **💸 Buy-in:** **50 USD to play** — paid to the commissioner; the top 3 split the pot. (Change the amount/currency anytime in **Admin → Settings**.)
- **📸 Profile photos:** tap your avatar (top-right) to upload a photo or pick an emoji badge.
- **🔥 Streaks & badges:** correct-result streaks light a flame; badges (Sniper, Giant Slayer,
  On Fire, Banker Boss) show on the leaderboard + podium.
- **📡 Live results:** scores sync automatically from a third-party feed, so usually nobody types
  anything — the commissioner can still correct a result by hand.

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

- **🌍 Times in your local timezone.** Friends in Tokyo and friends in Stockholm each see
  kickoff in their own clock — the actual moment is the same for everyone, the displayed time
  just matches the viewer's location. A short timezone tag (CET, JST, ET…) is shown next to
  every kickoff so there's no confusion.
- **📱 Mobile-first.** Designed to look great on a phone — top bar packs down on narrow widths
  and there's no horizontal scroll. Drop it on the home screen via Safari/Chrome → Share → "Add
  to Home Screen" for a near-native feel (the icon + name are wired up).
- **Picks are blind until you commit** — you only see the crowd's picks for a game after you've
  locked your own (or after kickoff). Then it's a fun reveal of who said what.
- **Reload to see others' latest** picks/results — the app loads fresh data on open.
- **Anonymous logins** are per-device: if someone clears their browser data they'll start a new
  identity. Fine for a casual pool.
- **Real money:** the app only *tracks* who's in and what payouts would be — it never processes
  payments. Settle the cash yourselves (Venmo, cash, etc.) and keep it a friendly pool in line
  with the rules where you live.

Do the Gyökeres, and may your longshots come in. 🦇🏆
