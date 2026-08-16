# ArmKey — App Store Optimization plan

Recommendations for listing ArmKey on the iOS App Store. Everything below is written
against what the app currently ships (see "What we're actually selling"), because App
Review rejects metadata that promises features the binary doesn't have, and keyboard
apps get punished in ratings faster than most categories when the listing oversells.

---

## 1. What we're actually selling

Read from the source, not from ambition:

| Ships today | Where |
| --- | --- |
| Armenian phonetic (Eastern) layout, QWERTY-mapped — `q→ք`, `a→ա`, `s→ս`, `d→դ` | `KeyboardExtension/KeyboardLayout.swift` |
| Shift, double-tap caps lock (300 ms) | `KeyboardViewController.swift:444` |
| Numbers, Latin punctuation, and Armenian punctuation `՜ ՞ ՝ « »` | `KeyboardLayout.swift:107-153` |
| Emoji picker | `KeyboardViewController.swift:463` |
| Quick-insert bar: `:` `-` `/` `.com` | `AccessoryBarView.swift` |
| Haptic feedback per key type | `HapticEngine.swift` |
| Light/dark, glass key styling | `AppearanceTokens.swift` |
| iPhone + iPad (`TARGETED_DEVICE_FAMILY = "1,2"`) | `project.pbxproj` |

**Not shipping — do not put these in metadata:**

- No autocorrect, no predictive text, no spell check. (Competitors have this. See §3.)
- No Western Armenian layout or orthography. Only Eastern/phonetic.
- No transliteration ("translit") input mode.
- No themes, no swipe typing, no multi-language switching within the keyboard.
- The function row (brightness, media, volume icons) and the mic/camera pills in the
  accessory bar are **decorative no-ops** — they only fire a haptic
  (`KeyboardViewController.swift:438`, `AccessoryBarView.swift:53`). See §9; this is a
  submission blocker before ASO matters at all.

---

## 2. Positioning

Three honest differentiators, in order of strength:

1. **Design.** The glass/Mac-style key treatment is genuinely better looking than every
   competitor listed below, most of which look like 2015. Lead the creative with this.
2. **Privacy.** No network code in the extension, nothing collected. In the keyboard
   category this is a top-two purchase driver — users are actively afraid of keyloggers.
3. **Feel.** Per-key-type haptics and the enlarged hit slots (recent commits) are a real
   typing-accuracy story, and accuracy is the #1 complaint in Armenian keyboard reviews.

Do **not** position on features (word suggestions, layouts, translit) — that's where the
competition wins today.

---

## 3. Competitive landscape

Live App Store pages were not reachable from this environment (egress blocked), so this
is from search results — re-verify current names/subtitles/ratings in App Store Connect
or on device before finalizing.

| App | What it claims | Implication for us |
| --- | --- | --- |
| Hayatar: Armenian Keyboard | Open source, no data collection, real-time Armenian spell check | Strongest rival. Owns both "privacy" and "suggestions". We can't beat it on features — beat it on visual design. |
| Armenian Keyboard for iPhone and iPad — phonetic layout | Phonetic layout, system-wide | Owns the exact keyword "phonetic layout" in its **name**. We must carry "phonetic" in the keyword field. |
| KitKeys Armenian | Multi-language layout, translit mode, word suggestions, emoji, swipe space to switch language | Feature leader. Our roadmap gap list. |
| Armenian Keyboard (original) | Western, Eastern, Phonetic and Typewriter layouts + translate | Owns Western Armenian — the diaspora markets. |
| Armenian Keyboard Extension | Dark/light, portrait/landscape | Weak; easy to out-rank on design. |

**Category note:** total search volume for "armenian keyboard" is small. That cuts both
ways — ranking #1 is achievable with good metadata alone, but the ceiling is modest.
Growth comes from covering *every* locale and script variant of the query, which is what
§5 is built around.

---

## 4. The Armenian localization problem (read this first)

**App Store Connect has no Armenian (hy) metadata localization.** Apple's supported list
covers 50 languages and Armenian is not one of them, even though Armenia is a storefront.

Consequences:

- You cannot create an Armenian-language listing. There's no field to put it in.
- Armenian-script keywords must ride inside a *supported* locale's fields. The name,
  subtitle, and keyword fields accept Unicode, so `Հայերեն ստեղնաշար` indexes fine when
  placed in the English (U.K.) or English (U.S.) fields.
- The Armenia storefront serves **English (U.K.)** metadata, with **Russian** as an
  additional localization many users in Armenia will see. Verify the exact mapping in
  App Store Connect when you add localizations — this is the single highest-leverage
  setting in this whole document.

So the plan is: **use en-GB as the de facto Armenian listing** (Armenian script in the
name), keep en-US as the diaspora/English listing, and add Russian for Armenia + the
Russian-speaking diaspora.

---

## 5. Metadata (copy-paste ready)

Apple indexes **app name**, **subtitle**, **keyword field**, developer name, and in-app
event metadata. It does **not** index the description. Character counts below are exact.

### 5.1 English (U.S.) — diaspora, default worldwide

| Field | Value | Chars |
| --- | --- | --- |
| Name | `Armenian Keyboard – ArmKey` | 26 / 30 |
| Subtitle | `Հայերեն ստեղնաշար · Emoji` | 25 / 30 |
| Keywords | `hayeren,stexnashar,haykakan,translit,alphabet,letter,font,typing,language,armenia,write,phonetic` | 96 / 100 |

Keyword-first name, not brand-first: "ArmKey" has zero search volume and zero brand
equity, and search-result rows truncate around 22–25 characters — if it truncates, you
want the head term to survive, not the brand.

`translit` is included because people search for it; the description must not claim we
have a translit mode. Ranking for a query you don't perfectly serve is fine; *claiming*
the feature is not.

### 5.2 English (U.K.) — this is the Armenia storefront listing

| Field | Value | Chars |
| --- | --- | --- |
| Name | `Հայերեն ստեղնաշար – ArmKey` | 26 / 30 |
| Subtitle | `Armenian Keyboard & Emoji` | 25 / 30 |
| Keywords | `հայկական,տառեր,գրել,հայ,hayeren,stexnashar,translit,alphabet,font,typing,language,armenia,phonetic` | 98 / 100 |

Native-script name for the native-script market; the English head term moves down to the
subtitle so it's still indexed.

### 5.3 Russian

| Field | Value | Chars |
| --- | --- | --- |
| Name | `Армянская клавиатура — ArmKey` | 29 / 30 |
| Subtitle | `Հայերեն ստեղնաշար · эмодзи` | 26 / 30 |
| Keywords | `хайерен,армения,транслит,алфавит,шрифт,печатать,язык,ереван,набор,текст,стехнашар,клава` | 87 / 100 |

### 5.4 Also worth adding later

French (large Armenian community in France) and Arabic (Lebanon/Syria storefronts) are
the next two, but both are **Western Armenian** communities — adding those localizations
before shipping a Western layout buys installs that churn and one-star. Do the layout
first, then the locale.

### 5.5 Keyword field rules being applied above

- Comma-separated, **no spaces** — a space costs you a character.
- Never repeat a word already in the name or subtitle; it's already indexed and the
  repeat is wasted budget. (That's why `keyboard`, `armenian`, and `emoji` are absent
  from the en-US keyword string.)
- Singular only. Apple generates plurals; `letter` covers `letters`.
- No `app`, no category names, no your-own-brand — all already indexed.
- No competitor names. `hayatar` was deliberately excluded: it doubles as a common
  Armenian word, but it's also a live app name, and trademark-adjacent keywords draw
  rejections. Not worth the review round-trip.
- Apple builds phrases from single words automatically — `armenian` + `keyboard` in the
  name already covers the phrase query. Don't spend characters on multi-word phrases.

---

## 6. Description and promotional text

Not indexed by Apple search — this is pure conversion copy. Only the first ~3 lines show
before "more", so those lines carry the whole job.

**Promotional text (170 max, editable without a new build — use it for launches):**

```
New: bigger key targets and smoother switching. ArmKey is the Armenian keyboard that
looks like it belongs on your iPhone — and never sees what you type.
```

**Description (en-US draft):**

```
Type Armenian anywhere on iPhone and iPad, with a keyboard that finally looks like it
belongs there.

ArmKey is a full Armenian phonetic keyboard: every letter where your fingers expect it,
Armenian punctuation built in, and a glass key design that fits right into iOS.

PRIVACY FIRST
ArmKey has no network access, no analytics, and no logging. What you type stays on your
device — always. We can't see it, and we don't want to.

DESIGNED FOR IOS
• Armenian phonetic layout — the standard QWERTY mapping you already know
• Armenian punctuation on the keyboard: ՞ ՜ ՝ « »
• Full emoji picker
• Quick keys for : - / and .com
• Precise haptic feedback on every key
• Light and dark mode, iPhone and iPad

BUILT FOR ACCURACY
Larger touch targets on every key mean fewer missed taps and less backspacing — the
single biggest complaint about typing Armenian on a phone.

GETTING STARTED
Open ArmKey and follow the two setup steps, or go to Settings → General → Keyboard →
Keyboards → Add New Keyboard → ArmKey. Then tap 🌐 on any keyboard to switch.
```

Notes on the draft:

- Every claim maps to shipped code. Nothing about suggestions, autocorrect, translit,
  Western Armenian, or themes.
- The privacy block is placed above the feature list on purpose. For keyboard extensions
  it converts better than any feature bullet.
- If Full Access stays enabled (§9), add one line explaining *why* in plain language.
  Unexplained Full Access is the top reason people delete keyboard apps.

---

## 7. Creative

Ranked by conversion impact:

1. **Icon.** Must be legible at 60 pt and read as *Armenian* in a scroll. A single
   Armenian glyph — `Ա` — on a glass key, on a saturated background. Do not use a
   full miniature keyboard (unreadable at icon size) and do not use a flag as the whole
   icon (Apple discourages it, and it reads as a translation app).
2. **Screenshot 1** — the keyboard in a real Messages thread with Armenian text, big
   caption: "Հայերեն ստեղնաշար · Armenian Keyboard". First screenshot is the only one
   most people see.
3. **Screenshot 2** — privacy: "No network. No logging. Nothing leaves your phone."
4. **Screenshot 3** — Armenian punctuation and emoji.
5. **Screenshot 4** — dark mode.
6. **Screenshot 5** — iPad.
7. **App preview video (15–30 s).** Autoplays muted in results. Show *typing*: fingers,
   Armenian text appearing, key highlights. This is the highest-lift item that most
   competitors in this category skip entirely.

Localize screenshot captions per locale (Armenian text for en-GB, Russian for ru). The
image itself can be the same render — only the caption layer changes.

---

## 8. Store configuration

- **Primary category:** Utilities. **Secondary:** Productivity.
- **Price:** Free. Every credible competitor is free; a paid Armenian keyboard will not
  acquire.
- **Privacy nutrition label:** "Data Not Collected". This is a visible badge on the
  product page and matters here more than in almost any other category. Keep it true.
- **In-App Events:** event name and short description *are* indexed by search. Ship one
  when the Western Armenian layout lands — it buys keyword coverage plus a card on the
  product page.
- **Custom Product Pages:** up to 35 variants with their own screenshots — use one for a
  design-led page and one for a privacy-led page, and let the data pick the default.
- **Ratings prompt:** `SKStoreReviewController` in the container app after the keyboard
  has actually been used, never on first launch. Rating count is a ranking factor and
  this category's incumbents have small counts — a few hundred reviews would outrank
  most of them.
- **Apple Search Ads:** in a niche this size, bidding on `armenian keyboard` and
  competitor brand terms is cheap. Worth a small budget once the page converts.

---

## 9. Blockers to fix before submitting

ASO is worthless if the app gets rejected or one-starred. Two real risks:

1. **Dead keys.** The entire function row (brightness, Launchpad, search, media
   transport, volume) and the mic/camera pills do nothing but vibrate
   (`KeyboardViewController.swift:438`, `AccessoryBarView.swift:53`). A keyboard
   extension cannot control system volume, brightness, or media playback at all, so
   these can't be made to work — they should be removed or replaced with keys that do
   something (arrow keys, cursor control, a settings key). Non-functional UI draws
   Guideline 2.2 rejections and reliably produces "half the buttons don't work"
   one-star reviews.
2. **Full Access.** `RequestsOpenAccess` is `true` and the setup screen tells users to
   enable it to fix a visual flash. Apple requires keyboards to be fully functional
   *without* Full Access, and asking for it costs installs and invites suspicion in a
   category defined by keylogger fear. If the flash can be fixed another way, turn this
   off — "ArmKey never asks for Full Access" is a stronger marketing line than any
   feature we could add.

Also worth fixing before launch: the keyboard extension's display name is `Armenian`
(`INFOPLIST_KEY_CFBundleDisplayName`), which is what users see in the Settings keyboard
list. Make it `ArmKey` so the name they installed matches the name they enable.

---

## 10. Measuring and iterating

1. Ship the metadata in §5, all three locales, at launch.
2. Wait 3–4 weeks for App Store search to index and stabilize. Do not change metadata
   inside that window — you'll lose the read.
3. In App Analytics, watch **impressions → product page views → conversion**, split by
   source (Search vs Browse) and by storefront (US vs AM vs RU).
4. Then change **one** field per release, not three. The keyword field is the cheapest
   to test; the name is the highest-impact and the riskiest.
5. Use promotional text for anything that needs to change fast — it doesn't require
   review.

Highest-expected-value product work, ranked by what it unlocks in the store:

1. Fix the two blockers in §9.
2. Word suggestions / autocorrect — the feature gap against every ranked competitor.
3. Western Armenian layout — unlocks the US, French, Lebanese, and Argentine diaspora,
   which is a larger addressable market than Armenia itself.
4. Transliteration mode — high-intent search term we currently rank for but don't serve.
