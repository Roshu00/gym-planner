# DESIGN.md — Chalkline

> Read this before writing any UI for the app. It is the single source of truth for how Chalkline looks, sounds and behaves.
> Visual reference: the component gallery (`lib/main_gallery.dart`), which shows every token and component with all variants.
> "Chalkline" is a working name. Never hard-code it outside one `appName` constant.

---

## 1. What we are building

A training platform where fitness **creators/influencers** publish their workouts and programs and bring their Instagram/TikTok audience into the app. **Followers** subscribe to a creator, use the creator's program as their own plan, execute workouts, and track progress.

- Users arrive from Instagram/TikTok. The app should feel like the feed they came from: light, colorful, friendly, and made to be shared.
- Brand feeling: **energy + consistency**. Color blocks carry the energy, and the numbers show the consistency.
- The concept name is **Color Pop**: a warm off-white base, black text, and three bright colors (lime, lilac, peach) used as big rounded blocks, with sticker-like details. The post-workout summary doubles as an Instagram story card.

Domain model and scope come from `training_planner_mvp_plan.md` (Exercise → Workout → Program → User Plan → Workout Session). This file only covers design.

---

## 2. Non-negotiable rules

1. **Warm light base, black ink, three pop colors.** The base is `bg` (off-white) with white `surface` cards. The pop colors are lime, lilac and peach. There are no other brand colors.
2. **Color comes in big blocks, not thin details.** A pop color fills a rounded block (`ClPopBlock`), a tile, a set row or a pill. At most two pop blocks per screen, next to each other in different colors.
3. **Text on a pop color is always `on-pop` (black)**, in both themes.
4. **Lime means done, current and record**: finished sets, the selected filter, the progress tile, the PR sticker. Lilac and peach carry content (today's workout, the week, rest).
5. **One primary button per screen**: a black pill. The lime `pop` button is for the one action that must stand out ("Pretplati se").
6. **Everything is rounded.** Fields 12, rows and cards 20, color blocks and big photos 28. Buttons, tags, filters, checks and avatars are pills or circles.
7. **Sentence case everywhere.** No uppercase titles, labels or buttons.
8. **Soft shadows on white cards only.** Rows, tiles, menus, the calendar and action chips sit on the warm base with one soft warm shadow (`ClElevation.card`). Pop blocks and controls stay flat.
9. **Secondary things live one tap away.** Settings, equipment, filters and rarely used actions go into menu groups and sheets, not onto the main screen.
10. **The creator is always named and visible** next to their content (avatar + name or handle).
11. **Every screen shows at least one number that proves progress** (streak in weeks, weekly goal, volume, PR).
12. **Never use hex values in components.** Use tokens only (`lib/ui/tokens/colors.dart` is the only file with hex values).

---

## 3. Tokens

The light theme is used on every screen. The dark theme exists for the gallery and a future night mode; pop colors and `on-pop` are the same in both.

### 3.1 Color

| Token | Light | Dark | Use |
|---|---|---|---|
| `bg` | `#FAF8F4` | `#111111` | Screen background |
| `surface` | `#FFFFFF` | `#1C1C1B` | Cards, list rows, stat tiles, sheets |
| `surface-raised` | `#EFECE5` | `#2A2927` | Fields, unselected chips, pressed state |
| `border` | `#E6E2D8` | `#2E2D2A` | Rare 1px lines, pending set rows, empty segments |
| `border-strong` | `#111111` | `#FAF8F4` | Outlines of controls: secondary button, current set, check |
| `ink` | `#111111` | `#FAF8F4` | Text, titles, numbers, primary button fill |
| `ink-muted` | `#5A5750` | `#A9A59C` | Labels and metadata |
| `lime` (`signal`) | `#D4F54A` | same | Done, current, record, selected, progress tile |
| `lilac` | `#C9B6FF` | same | Content blocks, planned days, story card |
| `peach` | `#FFC6A3` | same | Content blocks, rest timer |
| `on-pop` | `#111111` | same | Text and icons on any pop color |
| `signal-text` | `#3F6B00` | `#D4F54A` | Lime meaning as text on `bg` (rare) |
| `signal-soft` | `#F0FBC4` | `#2C3310` | Quiet lime tint |
| `danger` | `#D92D20` | `#FF6B5E` | Delete, errors |
| `photo-empty` | `#1F1E1B` | `#2A2927` | Empty media frame where a photo is expected (video) |
| `photo-scrim` | `rgba(0,0,0,.55)` | same | Gradient under white text on photos |
| `shadow` | `rgba(59,52,38,.12)` | `rgba(0,0,0,.45)` | Soft card shadow: 0 6 18 −6, plus 0 1 3 at half strength |

A workout, program or creator always gets the same pop color: `popFor(id)` picks it from the id.

### 3.2 Typography: Bricolage Grotesque

Two optical sizes of one family, bundled as static fonts in `assets/fonts`:

| Style | Cut | Weight | Size / line | Use |
|---|---|---|---|---|
| `display-xl` | Display (opsz 96) | 800 | 60 / 56, −3.5% | Story card headline ("Pojavio si se.") |
| `display-l` | Display | 800 | 44 / 42, −3.5% | Tab titles, today's workout |
| `display-m` | Display | 800 | 32 / 32, −3.5% | Screen titles |
| `metric-l` | Display | 800 | 40 / 42, −3% | Hero number (volume, rest clock) |
| `metric` | Display | 800 | 26 / 28, −3% | Stat tiles |
| `button` | Text (opsz 14) | 700 | 16–17 / 20 | Buttons |
| `data` | Text | 700 | 16 / 20 | Weights × reps in tables |
| `body` | Text | 400 | 15 / 22 | Text, creator messages |
| `body-strong` | Text | 700 | 15 / 20 | Exercise names, people names; 18px for section headers |
| `label` | Text | 700 | 12 / 16 | Small caption above a value or title |

- **All numbers** use `tabular-nums`.
- Everything is sentence case. Titles are 1–3 words, at most 2 lines.

### 3.3 Spacing, radius, size

```
space-1 4 · space-2 8 · space-3 12 · space-4 16 (screen gutter) · space-6 24 · space-8 32 · space-12 48
radius-xs 12 (fields) · radius-sm 20 (rows, cards, tiles) · radius-lg 28 (color blocks, big photos, sheets) · radius-full (pills, avatars, checks)
target 48 (min touch) · target-workout 56 (primary button + workout rows) · bar 10 (segments, 6 gap)
```

One elevation: `ClElevation.card` on white cards. No other shadows.

### 3.4 CSS variables (web)

```css
@import url("https://fonts.googleapis.com/css2?family=Bricolage+Grotesque:opsz,wght@12..96,400..800&display=swap");

:root {
  --bg:#FAF8F4; --surface:#FFFFFF; --surface-raised:#EFECE5; --border:#E6E2D8; --border-strong:#111111;
  --ink:#111111; --ink-muted:#5A5750;
  --lime:#D4F54A; --lilac:#C9B6FF; --peach:#FFC6A3; --on-pop:#111111;
  --signal-text:#3F6B00; --signal-soft:#F0FBC4; --danger:#D92D20;
  --font:"Bricolage Grotesque", "Helvetica Neue", Arial, sans-serif;
  --space-1:4px; --space-2:8px; --space-3:12px; --space-4:16px; --space-6:24px; --space-8:32px; --space-12:48px;
  --radius-xs:12px; --radius-sm:20px; --radius-lg:28px; --target:48px; --target-workout:56px;
}
.cl-display { font-variation-settings:"opsz" 96; font-weight:800; letter-spacing:-.035em; }
.cl-num     { font-variant-numeric:tabular-nums; }
.cl-label   { font-size:12px; line-height:16px; font-weight:700; color:var(--ink-muted); }
```

---

## 4. Components

Build these first and compose every screen from them. Every component is in the gallery.

### PopBlock and Sticker
- `ClPopBlock`: a full-width block in lime, lilac or peach, radius 28, padding 16. Its content always renders in the light theme so text is `on-pop`.
- `ClSticker`: a tilted black pill with lime text ("Nedelja 3/8", "Novi PR"), pinned over the block's top-right corner. One per block.

### Button
- A pill, height 48, sentence-case label (1–2 words, verb first).
- Variants:
  - `primary` (black pill, one per screen),
  - `pop` (lime pill with a black outline, e.g. "Pretplati se"),
  - `secondary` (1.5px ink outline, transparent),
  - `text` (a plain ink link, 15/700, no underline, optional trailing icon),
  - `block` (full width, 56px, black, pinned to the bottom of the screen),
  - `danger` (danger outline and label).

### WorkoutHero
- Full-width header with rounded bottom corners (28).
- With a photo: `photo-scrim` on the bottom 60% and white text.
- Without a photo: a pop color block (`color:`) with black text. This is what the app shows until creators upload photos.

### StatBar
- 2–3 equal white tiles (radius 20) with a `label` on top and a `metric` number below.
- The progress or record tile is lime.
- Optional segment bar below: rounded 10px segments, done = `ink`, remaining = `border` (or translucent ink on a pop block).

### SetTable (SetRow)
- Columns: `#` · previous · kg · reps · RIR · check. Each set is a rounded 60px row with an 8px gap.
- Inputs are filled `surface-raised` pills.
- States:
  - pending: white row, `border` outline,
  - current: 1.5px ink outline,
  - done: lime row with a black outline and a round lime check,
  - a new record adds the black `PR` sticker tag next to the value.
- Confirming a set starts the rest timer.

### RestTimer
- A peach block with the `Odmor` label, a big clock, −/+ buttons and a progress line.
- When time is over, the block turns lilac and counts up.

### ProgramCard
- A rounded photo (or pop color block) about 220px tall with the title, then avatar + creator + follower count, then tags.

### Summary and ShareCard
- `ClShareCard`: a lilac block made to be screenshotted for a story. It has a small label (workout · duration), a `display-xl` headline praising showing up ("Pojavio si se."), stat tiles (volume in lime, records in peach, streak in black), and the creator's avatar + handle with the app name.
- `ClSummary`: the share card, then the creator's message on a white card, then the exercise list.

### Tag / Filter
- `Tag`: a 20px pill, 11/800.
  - `PR` = black with lime text.
  - `outline` = 1.5px ink.
  - `danger` = outline in `danger`.
- `Filter`: a 36px pill, 13/700 on `surface-raised`. When selected it is lime with a black outline.

### Lists and Tabs
- `ListRow`: a white rounded card (radius 20) with a soft shadow and an 8px gap below.
- `CreatorRow`: avatar, name, handle, followers. A creator the user follows gets an ink ring around the avatar and a lime `Pratiš` tag; a subscription shows a black `Pretplata` tag. Followed creators are listed first.
- `MenuGroup` + `MenuRow`: settings-style group in one white card. Each row has an icon, a title, the current value on the right and a chevron, and opens a sheet or a screen. Used for Profile and for plan settings.
- `ActionChip`: a white pill with an icon and a short label, for one-tap actions on an item (a calendar day).
- `Tabs`: a segmented pill; the selected tab is a black pill.

### Avatar
- A circle with initials on a pop color picked from the name, or a photo. 28px in lists, 56px on the profile.

### Calendar
- Compact, on a white card (radius 28). The month title is 17/700, with previous/next buttons. Cells are 42px.
- Day cells are rounded squares: done = lime with a check, planned = lilac with a barbell, rest = a muted moon, selected = black, today = 2px ink outline (selected on open). A missed planned day is shown as rest, never as a failure.
- A day the user changed has a small dot in the corner.
- A legend under the grid shows the same swatches. No stats above the calendar.

### The plan suggests, the user decides
- Each day can be changed in one tap from the Plan tab (and today's from Today), and every change can be undone (`Poništi`):
  - **Odmor**: the day becomes rest; the following workouts move one training day forward.
  - **Pomeri za dan**: the day becomes rest and the next rest day becomes a training day, so the workouts in between slide by a day and the week after stays the same.
  - **Pauza**: a break of 1–28 days (travel, illness, a busy week). The plan continues where it stopped.
  - **Drugi trening**: another workout from the plan or the library; the plan's next workout waits.
  - **Kraća verzija**: about 60% of the exercises with one set less, for a low-energy day.
  - **Izmeni vežbe**: swap, remove, add exercises and change sets for that day only.
  - **Treniraj ovaj dan** on a rest day, **Zabeleži naknadno** on a past day without a logged workout, **Vrati na plan** to drop the change.
- A changed day shows why on a sticker (`Kraća verzija`, `Prilagođeno`, `Drugi trening`, `Pauza`).

### Chart
- On a white card: a rounded 2.5px ink line, with a lime dot and a lime value pill for the current or best value.

### Bottom navigation
- A quiet bar on `bg` with a hairline on top and 5 items: Danas, Plan, Otkrij, Napredak, Profil.
- The active item uses the solid (Fill) icon and an ink label; inactive items use the outline icon in `ink-muted`. No color, so the screen keeps the attention.

### Icons
- Phosphor Regular, 24px grid, `currentColor`; Phosphor Fill only for the active navigation item. Use sparingly: prefer a text label over an icon.

---

## 5. Screens (map to MVP navigation)

All screens use the light theme.

| Screen | Composition |
|---|---|
| **Today** (new user) | "Dobro došao/la" → lime welcome block with "Pronađi plan za sebe" → programs ranked for the profile (pop cards with `NN% za tebe`) → creators → "Kako radi" in three steps |
| **Today** (between plans) | "Nova nedelja." on lilac with what was done so far → "Pronađi plan" → programs → creators |
| **Today** (with a plan) | Date label + "Zdravo, Ime" → today's workout (with the day's changes) on a pop block with a sticker → one-tap chips (Kraća verzija, Pomeri za sutra, Odmor danas, Vrati na plan) → the week on a second pop block → exercise rows → Button `block` "Počni trening" |
| **Workout session** | Exercise title (`display-m`) + prescription label → creator note → SetTable → peach RestTimer → Button `block` "Završi set" |
| **Workout summary** | ShareCard (lilac story card) → creator message → exercise list → Button `block` "Gotovo" |
| **Plan** | Title "Plan" (label: plan · x of y this week) → compact Calendar → selected day: done workouts; a planned workout on a pop block with action chips and its exercises (today: Button `block` "Počni trening"); a rest day with "Treniraj ovaj dan" and "Pauza"; a past day with "Zabeleži naknadno" → menu: Dani treninga, Program i zamene vežbi |
| **Discover** | Title "Otkrij" → Tabs Otkrij / Biblioteka → Button "Pronađi plan za sebe" + `secondary` "Filteri" (sheet) → active filters → creator rows (followed first) → ProgramCards in pop colors |
| **Creator profile** | Pop color header with the name → stat tiles (Pratioci · Programi · Vežbe) → Button `pop` "Pretplati se" (+ `secondary` "Zaprati") → programs |
| **Library** | Tab inside Discover: filters Programi / Treninzi / Vežbe → list rows |
| **Progress** | Title "Napredak" → stat tiles → chart cards → history rows |
| **Profile** | Avatar + name → stat tiles (Treninzi · Niz · Rekordi) → menu groups: Treniranje (Moj plan, Pretplate, Oprema), Podešavanja (Pol, Nalog/Podaci), Za trenere (Režim kreatora); each opens a sheet or a screen |
| **Onboarding** | Name → gender (Žensko, Muško, Ne želim da kažem; used to address the user) → goal → experience → place → equipment |
| **Creator mode** | Same system, denser lists. Numbers first |

---

## 6. Voice & copy (UI language: Serbian, Latin script)

- **Titles** are short, in sentence case: `Push day`, `Pojavio si se.`, `Nova nedelja.`
- **Numbers are the proof**: `Prošli put 80 kg × 8`, `2 od 4 ove nedelje`, `2 PR`.
- **Address the user in their gender** (`Pojavio/Pojavila si se.`, `gde si stao/stala`); masculine when not given.
- **Praise showing up, not the result.** Missing a day is a fresh start, never a failure.
- **Creator messages are plain sentences** in the creator's voice: `Sledeće je Pull B. Isti ritam.`
- **Never** write exclamation marks in system copy, emoji, "BEAST MODE", shaming ("Niste trenirali 3 dana"), or result promises ("−5 kg za 30 dana").
- Buttons are 1–2 words, verb first: `Počni trening`, `Završi set`, `Pretplati se`, `Zameni vežbu`.
- Decimal comma in numbers: `82,5 kg`. Thousands use a dot: `8.240 kg`. Multiplication uses `×`, not `x`.

| Don't | Do |
|---|---|
| Great job!!! 💪 | Pojavio si se. |
| Niste trenirali 3 dana. | Nova nedelja. Push A te čeka. |
| Workout completed successfully | Push day · 1h 12m · 2 PR |
| Error occurred | Set nije sačuvan. Pokušaj ponovo. |

---

## 7. Imagery

- **Content:** creator photos and video are the best visual material. They should be real training moments: the creator in motion, effort details, and followers training.
- **Framing:** vertical-first (9:16 for video), with space at the bottom for the title. Photos are rounded like every other block.
- **Never:** before/after photos, shirtless posing, stock smiles, AI-generated people.
- **Without photos:** headers and program cards use their pop color (`popFor(id)`) with black text. A dark `photo-empty` frame is only for places that are clearly media, such as an exercise video.

---

## 8. Motion

- Motion should be quick and functional: 150–200 ms ease-out for state changes, and 250 ms for sheets. Pressed blocks scale to 98%.
- Completing a set fills the row with lime and gives a light haptic. A new PR gets the tag scaling in once plus a medium haptic. No confetti.
- Respect reduced-motion settings.

---

## 9. Accessibility

- All text/background pairs meet WCAG AA. This was measured:
  - `ink` on `bg` is 17.8:1, on white 18.9:1.
  - `ink-muted` is 6.8:1 on `bg`, 7.2:1 on `surface` and 6.1:1 on `surface-raised`.
  - `on-pop` is 15.2:1 on lime, 10.4:1 on lilac and 12.5:1 on peach.
  - Lime on black (PR tag, sticker) is 15.2:1. `signal-text` on `bg` is 6.0:1. `danger` on `bg` is 4.6:1.
- White text over photos **always** sits on `photo-scrim`.
- Never rely on color alone: PR always has the text tag, done sets always have a check, and calendar days always have an icon.
- Touch targets are ≥48px, and ≥56px during a workout. Text scales with system font size, and titles may wrap to 2 lines.

---

## 10. Review checklist (run before every PR)

- [ ] At most two pop blocks on the screen, in different colors, with black text
- [ ] Lime only for done, current, record or selected
- [ ] Exactly one primary button; secondary things in a menu or a sheet
- [ ] No hex values in components; shadows only on white cards (`ClElevation.card`)
- [ ] Rounded: fields 12, rows and cards 20, blocks 28, controls are pills
- [ ] Sentence case everywhere, numbers tabular
- [ ] Creator is named and visible next to their content
- [ ] At least one progress number is on screen
- [ ] Copy follows section 6 (no exclamation marks, emoji or shaming)
