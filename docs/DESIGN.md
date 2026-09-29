# DESIGN.md — Chalkline

> Read this before writing any UI for the app. It is the single source of truth for how Chalkline looks, sounds and behaves.
> Visual reference: the **Chalkline Design System** artifact (tokens, components, previews). Strategy: **Chalkline — Brand DNA + Lite Design Guide**.
> "Chalkline" is a working name. Never hard-code it outside one `APP_NAME` constant.

---

## 1. What we are building

A training platform where fitness **creators/influencers** publish their workouts and programs and bring their Instagram/TikTok audience into the app. **Followers** subscribe to a creator, use the creator's program as their own plan, execute workouts, and track progress.

- Users arrive from Instagram/TikTok. They expect a polished, media-first UI, not a spreadsheet.
- Brand feeling: **inspiration + discipline**. The creator's photo/video provides the inspiration, and the numbers show the discipline.
- Style reference: Nike Training Club (editorial type and photography) × Strava/Whoop (data up front).
- The concept name is **Type + Data**: black and white, one signal color, huge condensed type, wide numerals, full-bleed photography.

Domain model and scope come from `training_planner_mvp_plan.md` (Exercise → Workout → Program → User Plan → Workout Session). This file only covers design.

---

## 2. Non-negotiable rules

1. **Black and white make up 95% of every screen.** The only brand color is `signal` (Cobalt `#2F4BFF`).
2. **Signal color appears in at most 3 places per screen**, and only for these 3 purposes:
   - the one primary action,
   - progress (bars/segments),
   - personal records (PR tag, record number).
3. **One primary (signal) button per screen.**
4. **No rounded "pill" UI, no cards with shadows, no gradients** (the only exception is the photo scrim), no illustrations, no emoji in UI.
5. **Sharp shapes.** Photos and sections have radius 0, buttons and inputs have 4px, tags have 2px. The only circle is the avatar.
6. **Structure comes from lines, not boxes.** Use a 2px `rule` above data blocks and 1px `border` between rows.
7. **The creator's photo is the hero.** Media goes full-bleed with the title overlaid on the bottom. Without media, show a dark `photo-empty` frame and never substitute a color block.
8. **Every screen shows at least one number that proves progress** (streak in weeks, weekly goal, volume, PR).
9. **The creator is always named and visible** next to their content (avatar + name).
10. **Never use hex values in components.** Use tokens only.

---

## 3. Tokens

The dark theme is the default (Today, Workout, Discover). The light theme is used for Summary, History and Profile, where it reads like a magazine page.

### 3.1 Color

| Token | Dark | Light | Use |
|---|---|---|---|
| `bg` | `#000000` | `#FFFFFF` | Screen background |
| `surface` | `#111111` | `#F5F5F5` | Current row, subtle section fill |
| `surface-raised` | `#1C1C1C` | `#EDEDED` | Pressed state |
| `border` | `#262626` | `#E3E3E3` | 1px row dividers |
| `rule` | `#FFFFFF` | `#000000` | 2px editorial rule above data blocks and tables |
| `border-strong` | `#666666` | `#8A8A8A` | Input and secondary button borders (≥3:1) |
| `ink` | `#FFFFFF` | `#000000` | Primary text, titles, numbers |
| `ink-muted` | `#8A8A8A` | `#6B6B6B` | Labels, metadata (≥4.5:1) |
| `signal` | `#2F4BFF` | `#2F4BFF` | Primary action fill, progress bars, PR tag fill |
| `on-signal` | `#FFFFFF` | `#FFFFFF` | Text and icons on `signal` |
| `signal-text` | `#6E82FF` | `#2F4BFF` | Signal used **as text or thin line**. The dark value is lighter for contrast |
| `signal-soft` | `#0F1740` | `#E6EAFF` | Rare tinted background. Never put body text on it |
| `danger` | `#FF6B5E` | `#D92D20` | Delete, warnings, rest time over |
| `focus` | `#6E82FF` | `#2F4BFF` | 2px focus ring |
| `photo-empty` | `#1C1C1C` | `#1C1C1C` | Empty or loading media frame, dark in both themes |
| `photo-scrim` | `rgba(0,0,0,.55)` | same | Bottom gradient under white text on photos |

Plain `signal` `#2F4BFF` as text on black is only 3.6:1. On dark backgrounds, always use `signal-text` for text.

### 3.2 Typography: Archivo only (Google Fonts, variable `wdth` 62–125, `wght` 400–900)

One family is used at three widths:

| Style | Width | Weight | Size / line | Case | Use |
|---|---|---|---|---|---|
| `display-xl` | 62% | 900 | 96 / 82 | UPPER | Web hero, social |
| `display-l` | 62% | 900 | 72 / 62 | UPPER | Workout title over photo ("PUSH DAY") |
| `display-m` | 62% | 900 | 48 / 42 | UPPER | Screen titles, summary ("POJAVIO SI SE.") |
| `button` | 62% | 900 | 20–26 / 1 | UPPER | Buttons |
| `metric-l` | 125% | 800 | 40 / 44, −2% | — | Hero number (volume) |
| `metric` | 125% | 800 | 24 / 28, −2% | — | Stat bar numbers |
| `data` | 125% | 800 | 15 / 20 | — | Weights × reps in tables |
| `body` | 100% | 400 | 15 / 22 | Sentence | Text, creator messages |
| `body-strong` | 100% | 700 | 15 / 20 | Sentence | Exercise names, people names |
| `label` | 100% | 600 | 11 / 14, +8% | UPPER | Labels above numbers and titles |

- Condensed display text uses line-height `0.86` and letter-spacing `-0.01em`.
- **All numbers** use the 125% width and `tabular-nums`.
- Titles are 1–3 words, at most 2 lines.
- If the platform can't do variable width (e.g. some React Native setups), load static instances: `Archivo ExtraCondensed Black` (display), `Archivo Expanded ExtraBold` (numbers), `Archivo Regular/Bold` (text).

### 3.3 Spacing, radius, size

```
space-1 4 · space-2 8 · space-3 12 · space-4 16 (screen gutter) · space-6 24 · space-8 32 · space-12 48
radius-xs 2 (tags) · radius-sm 4 (buttons, inputs) · radius-device 0 (photos, sections) · radius-full (avatar only)
target 48 (min touch) · target-workout 56 (primary button + workout rows) · rule-w 2 · bar-h 4
```

No shadows anywhere, except system sheets and modals if the platform requires them.

### 3.4 CSS variables (web)

```css
@import url("https://fonts.googleapis.com/css2?family=Archivo:wdth,wght@62..125,400..900&display=swap");

:root, [data-theme="dark"] {
  --bg:#000000; --surface:#111111; --surface-raised:#1C1C1C; --border:#262626; --rule:#FFFFFF;
  --border-strong:#666666; --ink:#FFFFFF; --ink-muted:#8A8A8A;
  --signal:#2F4BFF; --on-signal:#FFFFFF; --signal-text:#6E82FF; --signal-soft:#0F1740;
  --danger:#FF6B5E; --focus:#6E82FF; --photo-empty:#1C1C1C; --photo-scrim:rgba(0,0,0,.55);
}
[data-theme="light"] {
  --bg:#FFFFFF; --surface:#F5F5F5; --surface-raised:#EDEDED; --border:#E3E3E3; --rule:#000000;
  --border-strong:#8A8A8A; --ink:#000000; --ink-muted:#6B6B6B;
  --signal:#2F4BFF; --on-signal:#FFFFFF; --signal-text:#2F4BFF; --signal-soft:#E6EAFF;
  --danger:#D92D20; --focus:#2F4BFF;
}
:root {
  --font: Archivo, "Helvetica Neue", Arial, sans-serif;
  --space-1:4px; --space-2:8px; --space-3:12px; --space-4:16px; --space-6:24px; --space-8:32px; --space-12:48px;
  --radius-xs:2px; --radius-sm:4px; --target:48px; --target-workout:56px; --rule-w:2px; --bar-h:4px;
}
.cl-cond  { font-stretch:62%;  font-weight:900; text-transform:uppercase; line-height:.86; letter-spacing:-.01em; }
.cl-wide  { font-stretch:125%; font-weight:800; letter-spacing:-.02em; font-variant-numeric:tabular-nums; }
.cl-label { font-size:11px; line-height:14px; font-weight:600; letter-spacing:.08em; text-transform:uppercase; color:var(--ink-muted); }
```

### 3.5 Theme object (React Native / TS)

```ts
export const colors = {
  dark:  { bg:'#000000', surface:'#111111', surfaceRaised:'#1C1C1C', border:'#262626', rule:'#FFFFFF',
           borderStrong:'#666666', ink:'#FFFFFF', inkMuted:'#8A8A8A', signal:'#2F4BFF', onSignal:'#FFFFFF',
           signalText:'#6E82FF', signalSoft:'#0F1740', danger:'#FF6B5E', focus:'#6E82FF',
           photoEmpty:'#1C1C1C', photoScrim:'rgba(0,0,0,0.55)' },
  light: { bg:'#FFFFFF', surface:'#F5F5F5', surfaceRaised:'#EDEDED', border:'#E3E3E3', rule:'#000000',
           borderStrong:'#8A8A8A', ink:'#000000', inkMuted:'#6B6B6B', signal:'#2F4BFF', onSignal:'#FFFFFF',
           signalText:'#2F4BFF', signalSoft:'#E6EAFF', danger:'#D92D20', focus:'#2F4BFF',
           photoEmpty:'#1C1C1C', photoScrim:'rgba(0,0,0,0.55)' },
} as const;
export const space  = { 1:4, 2:8, 3:12, 4:16, 6:24, 8:32, 12:48 } as const;
export const radius = { xs:2, sm:4, none:0, full:999 } as const;
export const size   = { target:48, targetWorkout:56, rule:2, bar:4 } as const;
```

The signal color is a **single variable**. Changing brand color must be a one-line change (`signal`, `signal-text`, `signal-soft`).

---

## 4. Components

Build these first and compose every screen from them. Names match the Design System artifact.

### Button
- A rectangle with radius 4, height 48, and condensed UPPERCASE label (1–2 words, verb first).
- Variants:
  - `primary` (signal fill, one per screen),
  - `ink` (ink fill on bg, used for "Pretplati se" on the creator profile),
  - `secondary` (1px `border-strong`, transparent),
  - `text` (underlined, sentence case, 15/700),
  - `block` (full width, 56px, 26px label, pinned to the bottom of the screen).
- No pills and no icon-only buttons without an accessibility label.

### WorkoutHero
- Full-bleed creator photo or video with radius 0.
- Bottom 60% gets a `photo-scrim` gradient. White `label` (creator · week X / Y) sits above a white `display-l` title, both anchored `space-4` from the bottom and left.
- Without media, show a `photo-empty` frame.

### StatBar
- 2–3 equal columns under a 2px `rule`, with 1px `border` dividers between columns.
- Each cell has a `label` on top and a `metric` number below, with the unit smaller (12/600).
- Only the progress or record number uses `signal-text`.
- Optional segment bar below: `bar-h` 4px, 3px gaps, done segments = `signal`, remaining = `border`.

### SetTable (SetRow)
- Columns: `#` · previous · kg · reps · RIR · check. Rows are 56px with 1px `border` below and a 2px `rule` on top of the table.
- Numbers use the `data` style. Inputs are radius 4 with a 1px `border-strong` and a 2px `focus` outline.
- States:
  - current row has `surface` background,
  - done row gets a check filled with `signal` and its row number in `signal-text`,
  - a new record adds the `PR` tag next to the value.
- Confirming a set starts the rest timer.

### ProgramCard
- Magazine-cover style: photo (radius 0, around 220px tall) with condensed title over the scrim.
- Below the photo: avatar (circle, 28px) + creator name (`body-strong`) + follower count (`label`, right-aligned), then outline tags.
- No card border and no shadow.

### Summary (Streak)
- `label` ("Trening završen · 1h 12m"), then a `display-m` headline that praises showing up ("POJAVIO SI SE.").
- Then a 2-column stat grid (volume, records in `signal-text`), the exercise list and the creator's message in `body`.

### Tag / Filter
- `Tag`: 18px high, radius 2, 10/700 UPPERCASE.
  - `PR` = signal fill.
  - `outline` = inset 1px `border-strong`.
  - `danger` = outline in `danger`.
- `Filter`: 32px high, radius 4, 12/600 UPPERCASE, 1px `border-strong`. When selected it is filled with `ink` and uses `bg` text.

### Avatar
- Circle, the only round element. 28px in lists, 56px on the profile.
- No story rings and no colored outlines.

### Icons
- Thin outline, 1.5px stroke, square caps, 24px grid, `currentColor` (Lucide or Phosphor Light).
- Use sparingly: prefer a text label over an icon.

---

## 5. Screens (map to MVP navigation)

| Screen | Theme | Composition |
|---|---|---|
| **Today** | dark | WorkoutHero (next workout, creator photo) → StatBar (Niz · Ova nedelja · Trajanje) + segment bar → exercise list preview → Button `block` "POČNI TRENING" |
| **Workout session** | dark | Exercise title (`display-m`) + prescription `label` → SetTable → rest timer (big `metric-l` countdown, thin progress line) → Button `block` "ZAVRŠI SET" |
| **Workout summary** | light | Summary: label → "POJAVIO SI SE." → volume / PR grid → exercise list with PR tags → creator message |
| **Discover** | dark | Filters row → ProgramCards / creator rows (avatar, name, followers) |
| **Creator profile** | light | Full-bleed photo header with name in `display-l` → StatBar (Pratioci · Programi · Vežbe) → Button `ink` "PRETPLATI SE" (+ `secondary` "ZAPRATI") → programs as ProgramCards |
| **Library** | dark | Tabs as `label` text with 2px underline for active → list rows (name, meta, tags) separated by `border` |
| **Progress** | light | StatBar → charts: 2px `ink` lines, `signal` only for the current or best value, no fills or gradients |
| **Creator mode** | light | Same system, denser tables. Numbers first, no decoration |

Bottom navigation: 5 items (Today, Library, Discover, Progress, Profile) with `label` text and thin icons. The active item uses `ink` and inactive items use `ink-muted`. Never use signal color in navigation.

---

## 6. Voice & copy (UI language: Serbian, Latin script)

- **Titles** are short and UPPERCASE, like a magazine cover: `PUSH DAY`, `POJAVIO SI SE.`, `NOVA NEDELJA.`
- **Numbers are the proof**: `Prošli put 80 kg × 8`, `3/4 ove nedelje`, `2 PR`.
- **Praise showing up, not the result.** Missing a day is a fresh start, never a failure.
- **Creator messages are plain sentences** in the creator's voice: `Sledeće je Pull B. Isti ritam.`
- **Never** write exclamation marks in system copy, emoji, "BEAST MODE", shaming ("Niste trenirali 3 dana"), or result promises ("−5 kg za 30 dana").
- Buttons are 1–2 words, verb first: `POČNI TRENING`, `ZAVRŠI SET`, `PRETPLATI SE`, `ZAMENI VEŽBU`.
- Decimal comma in numbers: `82,5 kg`. Thousands use a dot: `8.240 kg`. Multiplication uses `×`, not `x`.

| Don't | Do |
|---|---|
| Great job!!! 💪 | POJAVIO SI SE. |
| Niste trenirali 3 dana. | NOVA NEDELJA. Push A te čeka. |
| Workout completed successfully | Trening završen · 1h 12m · 2 PR |
| Error occurred | Set nije sačuvan. Pokušaj ponovo. |

---

## 7. Imagery

- **Content:** creator photos and video are the main visual material. They should be real training moments: the creator in motion, effort details, and followers training.
- **Lighting:** one strong light source and high contrast. Use black-and-white or natural color, with no color filters.
- **Framing:** full-bleed, vertical-first (9:16 for video), with space at the bottom for the overlaid title.
- **Never:** before/after photos, shirtless posing, stock smiles, pastel filters, AI-generated people.
- **Placeholders:** in dev, use the `photo-empty` frame with a small `label` "FOTO TRENERA". Never use colored blocks or illustrations as placeholders.

---

## 8. Motion

- Motion should be quick and functional: 150–200 ms ease-out for state changes, and 250 ms for sheets.
- Completing a set gets a short check fill plus a light haptic. A new PR gets the tag scaling in once plus a medium haptic. No confetti.
- Respect reduced-motion settings.

---

## 9. Accessibility

- All text/background pairs meet WCAG AA in both themes. This was measured:
  - `ink` on `bg` is 21:1.
  - `ink-muted` is ≥4.9:1 on all surfaces.
  - `on-signal` on `signal` is 5.9:1.
  - `signal-text` is 6.3:1 on black and 5.9:1 on white.
  - Control borders are ≥3.3:1.
- White text over photos **always** sits on `photo-scrim`.
- Never rely on color alone: PR always has the text tag, and done sets always have a check.
- Touch targets are ≥48px, and ≥56px during a workout. Text scales with system font size, and condensed titles may wrap to 2 lines.

---

## 10. Review checklist (run before every PR)

- [ ] Signal color is used in ≤3 places on the screen and only for action, progress or PR
- [ ] Exactly one primary button
- [ ] No hex values in components, no shadows, no gradients except the scrim, no pills
- [ ] Radius is 0 for media and sections, 4 for controls, 2 for tags, and only the avatar is round
- [ ] Titles use condensed UPPERCASE, numbers use wide + tabular, labels use 11px UPPERCASE
- [ ] Creator is named and visible next to their content
- [ ] At least one progress number is on screen
- [ ] Copy follows section 6 (no exclamation marks, emoji or shaming)
- [ ] Works in both themes, with contrast checked on new pairs
