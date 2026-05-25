# ⚽ GOALPOST — your World Cup '26 pool

A playful prediction game for you and ~20 friends. Predict scorelines, call upsets,
throw virtual coins on longshots, talk trash, and split a real-money pot at the end.
Built around the **real 2026 World Cup draw** (all 12 groups, 72 group fixtures, opener
Mexico 🇲🇽 v South Africa 🇿🇦 on June 11).

There are two ways to use it.

---

## 1. Try it right now (Demo mode — zero setup)

Just **open `index.html` in any browser**. It boots straight into a fully playable game
with sample friends, results, and a live leaderboard so you can feel how it plays. Make
picks, hit the 🃏 Props tab, watch the 📊 board move. Nothing you do here is shared — it's
your private sandbox (saved in your browser only).

When you're ready to play for real with your crew, do the 10-minute setup below.

---

## 2. Go live for your friends (real logins + shared database)

You'll use **Supabase** — a free hosted database with built-in logins. Free tier is way
more than enough for 20 people.

### Step 1 — Create the database
1. Go to **supabase.com** → sign up (free) → **New project**. Pick any name, set a database
   password (save it somewhere), choose the region closest to your friends.
2. Wait ~2 min for it to spin up.

### Step 2 — Create the tables
1. In your project, open **SQL Editor** (left sidebar) → **New query**.
2. Open the included **`schema.sql`**, copy the **whole file**, paste it in, and click **Run**.
   This creates every table, the security rules, and seeds all 48 teams + fixtures + prop bets.
   (It's safe to re-run if you ever need to.)

### Step 3 — Grab your two keys
1. Go to **Project Settings → API**.
2. Copy the **Project URL** (looks like `https://abcd1234.supabase.co`).
3. Copy the **anon public** key (a long string starting with `eyJ...`). This one is safe to
   ship in a web page — it's the public key.

### Step 4 — Plug the keys into the app
Open **`index.html`** in a text editor. Near the top of the `<script>` you'll see:

```js
const SUPABASE_URL  = "";   // ← paste your Project URL here
const SUPABASE_ANON = "";   // ← paste your anon public key here
const ADMIN_EMAILS  = ["a.svaetichin@gmail.com"]; // ← emails that get the Admin panel
```

Paste your URL and anon key between the quotes, and put **your** email (and any co-commissioner
emails) in `ADMIN_EMAILS`. Save the file. The moment those keys are filled in, the app switches
from demo to **live mode** automatically — real magic-link logins, real shared data.

### Step 5 — Make yourself the admin
Log in once (Step 7) so your profile exists, then in Supabase **SQL Editor** run:

```sql
update profiles set is_admin = true where email = 'a.svaetichin@gmail.com';
```

(The `ADMIN_EMAILS` list also auto-grants admin on first login; this SQL line is the
guaranteed way.)

### Step 6 — Put it on the internet
Friends need a link, so host the file somewhere. Easiest options, all free:

- **Netlify Drop** — go to **app.netlify.com/drop** and drag this whole `world-cup-pool`
  folder onto the page. You instantly get a public link. (Recommended — takes 30 seconds.)
- **Vercel** — `vercel` CLI or drag-and-drop import.
- **GitHub Pages** — push the folder to a repo, enable Pages.

> One config note: in Supabase go to **Authentication → URL Configuration** and add your
> hosted link (e.g. `https://your-pool.netlify.app`) to **Site URL / Redirect URLs**, so the
> magic-link emails send people back to the right place.

### Step 7 — Invite your friends
Send them the link. Each person enters their email, gets a one-tap **magic link** (no
passwords), picks a name + emoji, and they're in. That's it.

---

## Running the pool (you, the commissioner 🎩)

Open the **🛠️ Admin** tab (only you see it):

- **Results** — after each match, type the final score and hit *Finalize*. Everyone's points
  and coins recompute instantly, group standings update, and any completed group auto-scores
  everyone's "who advances" picks.
- **Settle props** — when a prop bet resolves (e.g. the Golden Boot total, or the champion),
  pick the correct answer and settle. Points and coin payouts go out automatically.
- **Pool settings** — set the buy-in amount, currency, payout split (default 50/30/20), the
  pool name, and whether final payouts rank by **points** or **coins**. Flip who's paid in the
  💰 Pool tab.

---

## How scoring works

- **Exact scoreline:** +5 points. **Correct result** (right winner/draw, wrong score): +2.
- **Group survivors:** +4 for each team you correctly tip to escape a group (auto-scored when
  the group finishes).
- **Prop bets:** each is worth its own points (the champion pick is worth a big 30).
- **Coins** 🪙: everyone starts with 1,000. On matches and some props you can stake coins on an
  outcome at auto-generated odds — underdogs pay more (winning the whole thing as Haiti pays
  300×). Coins drive a second, separate leaderboard for bragging rights.
- **The pot** 💰: real-money buy-ins are tracked, and projected payouts map to the current
  standings. All point values, the buy-in, and the split are adjustable in Admin.

---

## Customizing

Most things (pool name, buy-in, payout split, settling) are changeable live in the Admin tab.
For deeper edits, open `index.html`:

- **`DEFAULTS`** — starting coins, point values, default buy-in/split.
- **`seedProps()`** — add or change prop bets (yes/no, over/under, multiple-choice, or team-pick).
- **`GROUPS`** / **`POWER`** — teams per group and the rough strength ratings that generate odds.

After editing `index.html`, re-upload it to your host. (Structural seed data like teams/fixtures
lives in the database once you've run `schema.sql`, so edit those in Supabase or re-run the seed.)

---

## Good to know

- **Picks are visible to all members.** That's intentional — it fuels the trash talk. If you'd
  rather hide picks until kickoff, that needs extra work; ask and it can be added.
- **To see other people's latest picks/results, reload the page.** The app loads fresh data on
  open. (Live auto-refresh can be added later.)
- **Magic-link emails** on Supabase's free tier have hourly rate limits. For 20 people that's
  usually fine; if you hit a limit, you can connect your own email sender (Resend/SMTP) in
  Supabase → Authentication settings, or switch to password login.
- **Admin is trust-based** among friends. Keep the `ADMIN_EMAILS` list short.
- **Real money:** the app only *tracks* who's in and what the payouts would be — it never
  processes payments. Settle the cash among yourselves (Venmo, cash, etc.), and keep it a
  friendly pool in line with the rules where you live.

Have fun, and may your group-stage longshots come in. 🏆
