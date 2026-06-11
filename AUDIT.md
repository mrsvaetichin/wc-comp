# THE MASK — Full Audit (June 11, 2026)

> **Update:** the kickoff-time issues in §1 have been **fixed** in `index.html` and `schema.sql` (all 72 fixtures, verified 0 mismatches between the two files). To make it live: re-run `schema.sql` in the Supabase SQL editor (the fixture upserts update `kickoff` only — saved scores and picks are untouched) and redeploy `index.html`. The logic items in §2–3 are reported but not changed.

Audit of `index.html`, `schema.sql`, and `api/admin-reset-password.js` against the official 2026 World Cup draw and schedule, plus a review of the scoring engine, deadlines, and app logic. Security topics were deliberately skipped per your request.

**Verdict in one line:** teams, groups and all 72 fixture pairings are correct; kickoff times are wrong for 62 of 72 matches (2 on the wrong calendar day); the scoring engine is mostly correct but has one real scoring bug (free "survivor" points), one orphaned feature (the knockout bracket is unreachable), and several rules-text mismatches.

---

## 1. Matches — teams & pairings ✅, times ❌

### Correct ✓
- **All 48 teams and all 12 groups match the official Dec 5, 2025 draw**, including the late playoff winners (Czechia A4, Sweden F3, Bosnia B2, Iraq I3, DR Congo K2, etc.). Draw positions (pot order) are right — the earlier B/F/I/K position fix in `schema.sql` was correct.
- **All 72 pairings, home/away order, and matchday assignments are correct** (verified against the official fixture list: e.g. Czechia–South Africa MD2, Switzerland–Bosnia MD2, Tunisia–Japan MD2, Jordan–Argentina MD3 all match).
- `index.html` (generated fixtures) and `schema.sql` (seeded fixtures) agree with each other exactly: 0 of 72 mismatches.

### Wrong ✗ — kickoff times
The app generates times from a synthetic rotation (`12/15/18/21 ET`). The real schedule doesn't follow it: **57 matches have the wrong time, 5 land on the wrong ET date; only 10 are coincidentally right.** Two matches are on the wrong *local* day entirely: **Qatar–Switzerland and Australia–Türkiye are June 13, not June 12.**

Most urgent (today): the app has the opener **Mexico–South Africa at 8:00 PM ET — it actually kicks off 3:00 PM ET**, and **South Korea–Czechia at 3:00 PM ET — actually 10:00 PM ET.**

Full corrections (all times US Eastern):

| Match | In app | Actual |
|---|---|---|
| A-1 Mexico–South Africa | Jun 11, 8:00 PM | **Jun 11, 3:00 PM** |
| A-2 South Korea–Czechia | Jun 11, 3:00 PM | **Jun 11, 10:00 PM** |
| B-1 Canada–Bosnia | Jun 12, 3:00 PM | ✓ correct |
| D-1 USA–Paraguay | Jun 12, 9:00 PM | ✓ correct |
| B-2 Qatar–Switzerland | Jun 12, 6:00 PM | **Jun 13, 3:00 PM** |
| C-1 Brazil–Morocco | Jun 13, 6:00 PM | ✓ correct |
| C-2 Haiti–Scotland | Jun 13, 9:00 PM | ✓ correct |
| D-2 Australia–Türkiye | Jun 12, 12:00 PM | **Jun 13, 9:00 PM PT (Jun 14, 12:00 AM ET)** |
| E-1 Germany–Curaçao | Jun 14, 12:00 PM | **Jun 14, 1:00 PM** |
| F-1 Netherlands–Japan | Jun 14, 3:00 PM | **Jun 14, 4:00 PM** |
| E-2 Côte d'Ivoire–Ecuador | Jun 14, 3:00 PM | **Jun 14, 7:00 PM** |
| F-2 Sweden–Tunisia | Jun 14, 6:00 PM | **Jun 14, 10:00 PM** |
| H-1 Spain–Cabo Verde | Jun 15, 9:00 PM | **Jun 15, 12:00 PM** |
| G-1 Belgium–Egypt | Jun 15, 6:00 PM | **Jun 15, 3:00 PM** |
| H-2 Saudi Arabia–Uruguay | Jun 15, 12:00 PM | **Jun 15, 6:00 PM** |
| G-2 Iran–New Zealand | Jun 15, 9:00 PM | ✓ correct |
| I-1 France–Senegal | Jun 16, 12:00 PM | **Jun 16, 3:00 PM** |
| I-2 Iraq–Norway | Jun 16, 3:00 PM | **Jun 16, 6:00 PM** |
| J-1 Argentina–Algeria | Jun 16, 3:00 PM | **Jun 16, 9:00 PM** |
| J-2 Austria–Jordan | Jun 16, 6:00 PM | **Jun 16, 9:00 PM PT (Jun 17, 12:00 AM ET)** |
| K-1 Portugal–DR Congo | Jun 17, 6:00 PM | **Jun 17, 1:00 PM** |
| L-1 England–Croatia | Jun 17, 9:00 PM | **Jun 17, 4:00 PM** |
| L-2 Ghana–Panama | Jun 17, 12:00 PM | **Jun 17, 7:00 PM** |
| K-2 Uzbekistan–Colombia | Jun 17, 9:00 PM | **Jun 17, 10:00 PM** |
| A-4 Czechia–South Africa | Jun 18, 9:00 PM | **Jun 18, 12:00 PM** |
| B-4 Switzerland–Bosnia | Jun 18, 12:00 PM | **Jun 18, 3:00 PM** |
| B-3 Canada–Qatar | Jun 18, 9:00 PM | **Jun 18, 6:00 PM** |
| A-3 Mexico–South Korea | Jun 18, 6:00 PM | **Jun 18, 9:00 PM** |
| D-3 USA–Australia | Jun 19, 3:00 PM | ✓ correct |
| C-4 Scotland–Morocco | Jun 19, 3:00 PM | **Jun 19, 6:00 PM** |
| C-3 Brazil–Haiti | Jun 19, 12:00 PM | **Jun 19, 8:30 PM** |
| D-4 Türkiye–Paraguay | Jun 19, 6:00 PM | **Jun 19, 9:00 PM PT (Jun 20, 12:00 AM ET)** |
| F-3 Netherlands–Sweden | Jun 20, 9:00 PM | **Jun 20, 1:00 PM** |
| E-3 Germany–Côte d'Ivoire | Jun 20, 6:00 PM | **Jun 20, 4:00 PM** |
| E-4 Ecuador–Curaçao | Jun 20, 9:00 PM | **Jun 20, 8:00 PM** |
| F-4 Tunisia–Japan | Jun 20, 12:00 PM | **Jun 20, 10:00 PM CST (Jun 21, 12:00 AM ET)** |
| H-3 Spain–Saudi Arabia | Jun 21, 3:00 PM | **Jun 21, 12:00 PM** |
| G-3 Belgium–Iran | Jun 21, 12:00 PM | **Jun 21, 3:00 PM** |
| H-4 Uruguay–Cabo Verde | Jun 21, 6:00 PM | ✓ correct |
| G-4 New Zealand–Egypt | Jun 21, 3:00 PM | **Jun 21, 9:00 PM** |
| J-3 Argentina–Austria | Jun 22, 9:00 PM | **Jun 22, 1:00 PM** |
| I-3 France–Iraq | Jun 22, 6:00 PM | **Jun 22, 5:00 PM** |
| I-4 Norway–Senegal | Jun 22, 9:00 PM | **Jun 22, 8:00 PM** |
| J-4 Jordan–Algeria | Jun 22, 12:00 PM | **Jun 22, 11:00 PM** |
| K-3 Portugal–Uzbekistan | Jun 23, 12:00 PM | **Jun 23, 1:00 PM** |
| L-3 England–Ghana | Jun 23, 3:00 PM | **Jun 23, 4:00 PM** |
| L-4 Panama–Croatia | Jun 23, 6:00 PM | **Jun 23, 7:00 PM** |
| K-4 Colombia–DR Congo | Jun 23, 3:00 PM | **Jun 23, 10:00 PM** |
| B-5 Switzerland–Canada | Jun 24, 3:00 PM | ✓ correct |
| B-6 Bosnia–Qatar | Jun 24, 6:00 PM | **Jun 24, 3:00 PM** |
| C-5 Scotland–Brazil | Jun 24, 6:00 PM | ✓ correct |
| C-6 Morocco–Haiti | Jun 24, 9:00 PM | **Jun 24, 6:00 PM** |
| A-5 Czechia–Mexico | Jun 24, 12:00 PM | **Jun 24, 9:00 PM** |
| A-6 South Africa–South Korea | Jun 24, 3:00 PM | **Jun 24, 9:00 PM** |
| E-5 Ecuador–Germany | Jun 25, 12:00 PM | **Jun 25, 4:00 PM** |
| E-6 Curaçao–Côte d'Ivoire | Jun 25, 3:00 PM | **Jun 25, 4:00 PM** |
| F-5 Tunisia–Netherlands | Jun 25, 3:00 PM | **Jun 25, 7:00 PM** |
| F-6 Japan–Sweden | Jun 25, 6:00 PM | **Jun 25, 7:00 PM** |
| D-5 Türkiye–USA | Jun 25, 9:00 PM | **Jun 25, 10:00 PM** |
| D-6 Paraguay–Australia | Jun 25, 12:00 PM | **Jun 25, 10:00 PM** |
| I-5 Norway–France | Jun 26, 12:00 PM | **Jun 26, 3:00 PM** |
| I-6 Senegal–Iraq | Jun 26, 3:00 PM | ✓ correct |
| H-5 Uruguay–Spain | Jun 26, 9:00 PM | **Jun 26, 8:00 PM** |
| H-6 Cabo Verde–Saudi Arabia | Jun 26, 12:00 PM | **Jun 26, 8:00 PM** |
| G-5 New Zealand–Belgium | Jun 26, 6:00 PM | **Jun 26, 11:00 PM** |
| G-6 Egypt–Iran | Jun 26, 9:00 PM | **Jun 26, 11:00 PM** |
| L-5 Panama–England | Jun 27, 9:00 PM | **Jun 27, 5:00 PM** |
| L-6 Croatia–Ghana | Jun 27, 12:00 PM | **Jun 27, 5:00 PM** |
| K-5 Colombia–Portugal | Jun 27, 6:00 PM | **Jun 27, 7:30 PM** |
| K-6 DR Congo–Uzbekistan | Jun 27, 9:00 PM | **Jun 27, 7:30 PM** |
| J-5 Jordan–Argentina | Jun 27, 3:00 PM | **Jun 27, 10:00 PM** |
| J-6 Algeria–Austria | Jun 27, 6:00 PM | **Jun 27, 10:00 PM** |

### What the wrong times break
- **Round-lock deadlines:** MD1 (today, 2:30 PM ET) and MD2 (Jun 18, 11:30 AM ET) are coincidentally **correct**. **MD3 locks 3 hours early** (app: Jun 24, 11:30 AM ET; real earliest kickoff is 3 PM ET → should be 2:30 PM ET).
- "Next kickoff" countdowns, the 🟢 LIVE / "kicked off" status, the half-time re-pick window, and the per-match blind-reveal trigger are wrong by 1–9 hours for most matches.
- Live score sync (`syncResults`) can mark a match finished while the app still thinks it hasn't kicked off — confusing but self-consistent points-wise.

---

## 2. Scoring engine

### Correct ✓ (verified by code review)
- Exact score (5) / right result via `Math.sign` comparison (2) — handles draws correctly.
- ⭐ Banker doubling, one-per-round enforcement in the UI (saved + draft), no miss penalty.
- 🔁 Re-pick: max 3, −3 pts each, only while a match is in play; latest re-pick wins; banker carries over.
- Fan bonus +3 per win of supported team.
- Props: one-shot, settle/re-settle math correct; GOAT joke prop ±1 as designed.
- Banter: +1 per ❤️, capped at 6 in `banterBonus`; red-carded posts earn 0; likes/cards freeze on round change; send-off math (every red + every 2nd yellow, 3 events → 30 min ban) matches the described rules.
- Group survivor points: derived top-2 vs real top-2, +4 each, only when the group is complete.
- KO "reached" sets correctly treat a later stage as implying earlier ones.

### Bugs ✗
1. **Free survivor points with zero picks.** `predictedGroupStandings` on a group where the user predicted nothing returns an all-zero table sorted alphabetically — so `derivedSurvivors` "predicts" the alphabetically-first two teams. If those advance (e.g. Group A: *Czechia, Mexico* — Mexico very likely advances), a player who never made a single pick in that group banks +4/+8. Fix: award survivor points only if the user predicted all (or at least one) match in the group.
2. **The knockout bracket is unreachable.** `viewBracket`/`bracketTree` (tap-to-advance tree, scoring +2/+3/+5/+8) exists and `scoreFor` counts bracket points, but **no nav tab or button ever sets `VIEW="bracket"`** — players can't open it. Likewise the Picks tab's KO rounds say "fixtures will be wired in shortly" and no R32–Final fixtures exist in app or schema (real R32 starts June 28). As shipped, the whole knockout layer (~40% of promised points) has no input UI.
3. **Points-race chart uses the legacy `advances` table** (`matchPtsAsOf` reads `ADV`) while the actual score uses derived survivors — mid-tournament chart points won't match the board (the final point is force-corrected, masking it).
4. **Banter bonus display is uncapped.** Dashboard "Top banter" and the banter podium show `+N pts` from raw like counts, while the real bonus caps at +6. A player with 15 likes sees "+15 pts" but receives 6.
5. **Re-pick penalty timing inconsistency:** the board deducts −3 immediately on re-pick; the chart deducts only when the match finishes. Cosmetic divergence.
6. **Tiebreakers simplified:** standings use Pts → GD → GF → alphabetical. FIFA's real order inserts head-to-head among tied teams and fair-play points before lots. Edge-case group orders (and survivor/best-third points) can diverge from reality. Same caveat for the best-8-thirds ranking.
7. **R32 bracket pairings don't follow FIFA's real bracket.** The app seeds winners(A–L) + runners + thirds 1–32 and pairs 1v32, 2v31… The real bracket is a fixed mapping (e.g. runner-up A vs runner-up B; winner F vs runner-up C; thirds slotted by FIFA's allocation table). Scoring is set-membership so points stay sane, but the displayed matchups will not be the real ones.

---

## 3. App logic / other findings

- **Demo mode boots into the admin dashboard:** `seedDemo` creates the "me" profile with `is_admin:true`, and `render()` sends admins straight to the admin-only view; `isPlayer` also hides admins from every leaderboard. Demo players never see the player UI. (Live mode is unaffected — your league runs live.)
- **Buy-in of 0 silently becomes 50:** `parseInt(buyin,10) || DEFAULTS.buy_in` — a free league is impossible.
- **Blind-reveal vs DB rule mismatch:** the UI reveals the crowd's picks at round lock (30 min before kickoff), but the database only permits reading others' picks after kickoff or if you picked the same match. Between lock and kickoff, players who skipped a match see an incomplete/empty crowd list.
- **Stale labels in `schema.sql` p-champ options:** the trophy-prop option list still has the pre-fix B/F/I/K labels (e.g. `F3 = Tunisia`, `B2 = Switzerland`). Harmless — the UI labels teams via the `teams` table — but the stored JSON is wrong.
- **Live sync can finalize in-play matches:** TheSportsDB returns scores for live games; any non-empty score marks the match `finished`, awarding points and killing the re-pick window mid-match. Consider only finalizing when the event is flagged finished.
- **League code collisions unguarded client-side:** `genCode()` doesn't check uniqueness; a (rare) collision errors on insert but still updates local state.
- **Kicked members leave orphaned rows server-side:** `kickMember` deletes the player's own likes/cards but not cards/likes other people put on their posts (local state does remove them). Harmless to scoring, but DB and clients diverge until reload.
- **Payout rounding:** each split is rounded independently, so 1st+2nd+3rd can differ from the pot by a unit.

### Rules-text mismatches (copy bugs)
- Rules modal says champion prop is worth **+30**; it's actually **20** everywhere else.
- Rules modal promises **scoreline picks + a Banker for every knockout round** — not implemented (see §2.2).
- Rules say your nation is "locked in when you sign up"; the profile actually allows changing it until the first match is finalized (that's intentional post-fix behavior — update the rules text).
- Code comment still describes the old banter podium bonus (+15/+10/+5); actual rule is +1/like capped at 6.

### Skipped
Per your instruction, security topics (hardcoded admin credentials, client-side-only deadline/banker enforcement, key exposure, etc.) were noted but not audited in depth.

---

## 4. Priority fix list

1. **Now (before tonight):** correct the 62 kickoff times + move B-2 and D-2 to June 13 (table above) in both `index.html` and `schema.sql`, and re-run the schema so the live DB updates (the upsert only touches kickoff/pairings, not scores).
2. **Before June 24:** MD3 lock time fixes itself once times are corrected.
3. **Before June 27 (groups end):** fix the zero-pick survivor freebie; wire up the bracket tab (or add real R32–Final fixtures + picks).
4. Whenever: banter "+N pts" capped display, +30→20 rules text, chart `ADV` inconsistency, demo admin flag, buy-in 0.

---

*Fixtures verified against the official draw and the published match schedule (FIFA schedule as carried by Al Jazeera, Sky Sports, ESPN, socceroos.com.au, June 2026). Fixture generation and schema seed cross-checked programmatically (0 internal mismatches; 62/72 differ from the real schedule).*
