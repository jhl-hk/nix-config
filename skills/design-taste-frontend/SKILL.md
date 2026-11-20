---
name: design-taste-frontend
description: >-
  Use when building, designing, redesigning, restyling or polishing a landing page or a company,
  product, shop, cafe, bakery, restaurant, hotel, guesthouse, clinic, agency, studio, SaaS, AI,
  fintech, developer-tool, hardware or game website, as static HTML/CSS or inside an existing
  Astro, React, Next.js, Vue, Svelte or Tailwind project, or when the user says a page looks
  generic, templated, "AI-made" or like AI slop. Not for existing product UI (apps, dashboards,
  settings) or critique, audit or refinement of it; use impeccable. Not for animation craft on its
  own; use animate, choreograph, micro-interaction, gsap-web, svg-animation,
  page-transition-animation, glassmorphism, accessible-animation or animation-performance. Not for
  worst-case data stress tests (break-ui), mobile web feel (mobile-native) or @jianyuelab tokens and
  components (jianyuelab-ui).
hooks:
  Stop:
    - hooks:
        - type: command
          command: 'for f in ${CLAUDE_SKILL_DIR:+"$CLAUDE_SKILL_DIR/scripts/gate.mjs"} ${CLAUDE_PLUGIN_ROOT:+"$CLAUDE_PLUGIN_ROOT/scripts/gate.mjs" "$CLAUDE_PLUGIN_ROOT/skills/taste-skill/scripts/gate.mjs"} ${CLAUDE_PROJECT_DIR:+"$CLAUDE_PROJECT_DIR/.claude/skills/design-taste-frontend/scripts/gate.mjs" "$CLAUDE_PROJECT_DIR/.agents/skills/design-taste-frontend/scripts/gate.mjs"} ${HOME:+"$HOME/.claude/skills/design-taste-frontend/scripts/gate.mjs" "$HOME/.agents/skills/design-taste-frontend/scripts/gate.mjs"}; do if [ -f "$f" ]; then if command -v bun >/dev/null 2>&1; then exec bun "$f" --hook claude; fi; exec node "$f" --hook claude; fi; done; if [ -d .taste-skill ]; then printf "%s gate.mjs not found; CLAUDE_PLUGIN_ROOT=%s CLAUDE_PROJECT_DIR=%s HOME=%s\n" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "${CLAUDE_PLUGIN_ROOT-}" "${CLAUDE_PROJECT_DIR-}" "${HOME-}" > .taste-skill/gate-hook-missing.txt 2>/dev/null; fi; for d in .taste-skill */.taste-skill; do if [ -f "$d/build.json" ]; then echo "tasteskill gate: gate.mjs not found (CLAUDE_PLUGIN_ROOT=${CLAUDE_PLUGIN_ROOT-}); the build in $d is not checked" >&2; break; fi; done; exit 0'
          timeout: 600
---

# Design taste: frontend

## Overview

Build the website a good company would ship: it says plainly what is sold, shows the real thing on
every screen, and looks made for this client, not from a template and not like an art piece.
figma.com and x.ai are the bar (in words: `references/layout-v4.md` section 1).

`<skill>` is this folder. Requirements: bun (or Node 22+), Chrome, Edge or Chromium; ffmpeg optional.

### House rules

These nine win over everything else in this skill.

1. **No caption or description under any image, render or visual.** Licence credits go in one
   footer line.
2. **Every visual renders, never an empty ground,** at 1440, 1024, 768 and 390.
3. **One section per screen:** the hero alone on the first screen, every section exactly one or
   two screens tall at 1440x900, no second section heading peeking in. The one exception is a
   live `photo-chapters` section, three or four screens, set by the moment.
4. **Equal left and right content edges.**
5. **Hover micro-animations:** a linked card lifts 2px, a photo zooms 1.02-1.03 inside its frame,
   buttons step on hover and press on click, underlines draw, card loops cycle in 2.5-4 s, repeat
   and restart on hover. The motion layer does it; never strip or override it. No tilt, carousels
   or timed tabs. Every hero enters once on load (`data-enter`), and every page carries one dealt
   moment, two on a long page (the gate holds both).
6. **More and better real photographs where they fit;** nicer backgrounds; better heroes, layouts
   and fonts.
7. **Real full-colour icons** (a known product's real icon, never a drawn one); small diagram
   visuals in cards (a hub with branches; one input, a main processor, three parallel lanes;
   pulses running along the lines).
8. **Award-site scenes and creative moments are part of the skill:** every page deals its
   moments (photo- and type-led off tech), but shader effects and scenes only where the trade has a
   technical subject (tech, AI, developer tools, gaming, fintech, hardware), never on a local cafe,
   bakery, guesthouse or shop: those get photographs.
9. **Addresses:** street and district only (no street given: the district), no house number,
   postcode or coordinates; no register or VAT numbers; no phone in a real format; contacts on
   `.example`.

## When to Use

- A new or redesigned marketing, company, landing, shop or place site, in any stack.
- A page the user calls generic, templated or "AI-made".
- Not for the cases the description names; motion beyond the kit's motion layer goes to the
  animation skills listed there.

## Core Pattern

### The kind of business decides everything

Write the kind on the plan's first line and declare it on the page: the page type on
`<html data-type>` and `<meta name="page-type">` (the same value), and `<meta name="site-kind">`;
a place adds `<meta name="page-kind" content="place">`. The dealers take the last column
(`start.mjs --page`, `moments.mjs --page`), the hero dealer the page type; `consistency.mjs` reads
the metas.

| Brief | page type | site-kind | kind |
|---|---|---|---|
| App, SaaS, AI, developer tool, fintech or banking app, a studio selling its own software | software | software | software |
| A game, a studio launching its game | software | gaming | gaming |
| Hardware or a tech device (a drone, a robot arm, a keyboard) | product | tech | tech |
| Any other physical product or brand (a chair, a bike, coffee beans sold online) | product | other | product |
| People are hired: clinic, law firm, agency, creative studio, trade | service | other | service |
| People come to it: cafe, bar, bakery, restaurant, guesthouse, small hotel, shop, florist, bike shop, gym, local studio | place | other | place |

A maker that also opens its door or teaches (a ceramics studio, a bakery with a web shop) is a
**place**; its web shop becomes the goods section. It is a product only when nothing happens at the door.

"Tech" means site-kind software, gaming or tech; "other" is everything else. Effects, scenes,
loops, counts, CSS grounds, dark pages and dark heroes are tech only. An other page is
photographs, flat colour, type, real icons, the hero's entrance, its dealt moment (photo- or
type-led, `moments.md`) and the hover layer.

### The page plan by kind

Full plans, deal lists and section order: `references/sections.md`.

- **Place** (a cafe, bakery, guesthouse, shop). Photographs lead: 12 to 20 on the full page, 8 to
  12 compact, under 8 frames the 3-screen short page, whatever the trade; no client photographs:
  the draft path and a live search (`photos.md`), then count; the palette dealt by trade. The hero
  a photograph whenever a frame fits (a remote place: its region's landscape), the visit block on
  screen two, the offer, the place, orders or booking.
  **Variety without effects** (`sections.md` section 4): the offer and the place deal different
  compositions, never two sections round one picture; one type moment (the address or name set
  large); one main action a screen; list text 16px. Flat grounds, square photographs, one button
  style, the phone bar, the dealt moments; no effect, ground, loop, fragment, diagram or tab.
- **Product and service** (site-kind other). Photographs lead: the product, the people, the rooms,
  the work, two or more a screen on a product page. Real icons for the tools a studio uses; one
  still diagram at most; flat grounds and one brand band. No shader effect, print, grain, gradient,
  scene or loop (the dealt moments only); WebGL only for a product render the brief asks for. **A
  physical product with no photographs is shown in photographs:** stand-ins of the same kind of
  thing from `photos.mjs search`, each listed in the report, on the full product page; a render
  (`assets/objects/product-render`, stills) only when the brief asks for 3D or a render; never a
  drawing, mood stock or a set of props (`sections.md`, Product).
- **Every product page** (photographed, in stand-ins or rendered on a 3D ask, hardware too; the bar
  is Figure and 1X; `sections.md`, Product): the product **big** where it stands whole (most of its
  frame, or on the ground at anchor scale), never mid-size in a grey rounded panel on a grey
  ground; **a different picture each section**, never one view twice; **every headline promise
  pictured** (a family bike shows the child bench); dealt compositions, no structure twice, one
  contrasting ground; the **swatch changes the picture**, every colour shown once; **no fact
  twice**; buttons step and press (rule 5).
- **Tech** (software, gaming, hardware). The client's own subject leads at true size. Software: its
  own UI as live HTML showing what it works on (a code-review tool: a red and green diff with its
  Accept action) in one `app-frame`, never a generic dashboard or only fragments on panels; cards:
  fragments on lit panels, pulsing diagrams, real icons. Hardware: its photographs, else stand-in
  photographs of its kind (a render only when the brief asks for 3D), never a split hero of only
  an order form or a drawn SVG. A game: its name in the h1, a launch line, its world as full-bleed
  key art (else its name set large over stand-in photographs of its setting), an effect never in
  its place (`sections.md`, Gaming). **60 to 80 words a screen** outside UI mocks (`copy.md`). By
  deal: **one effect** (a shader ground in the hero or the one `[data-visual]` frame, a WebGL
  part, an object or one big scene) and **one or two moments** in their own sections; four live
  WebGL contexts at most; no card moves with the scroll (`effects-usage.md`).
- **One object never carries the page.** The product or hero object whole leads the hero and **two
  more sections at most**; another kind of visual the brief supports carries the rest
  (`sections.md` section 1, its table): a game's world and crew; hardware's use at the bench, its
  parts close up; a still diagram card, a type moment, a context photograph where the trade allows.
- **The client's own assets get slots.** A trailer, key art, screenshots, CAD renders or a motion
  video the brief names each get a frame that reads finished now (a real `<video>` with a stand-in
  poster, a play control only when there is a page or file to play, three to five stand-in
  photographs of the world, a CAD frame), named in a comment for the client's file, never empty
  (`sections-library.md`, client-slots).

## Quick Reference: the run

Run every command from the project folder, one at a time in the foreground. Each step's detail is
in the reference after its arrow.

0. **Stack.** Empty folder: copy `<skill>/assets` into `assets`, start from `assets/starter.html`.
   Existing project: its own stack, the kit in `public/assets`. Next.js: a static export. →
   `system.md`, Stack.
1. **Read the brief and arm the gate**, before any page exists. Write down the kind, what is sold,
   who buys it, the one main action (the transaction: Book a room, Order a cake, Start a free trial;
   a place with neither: Get directions) and the real material: logo, screens, photographs, prices,
   address, hours.

   ```bash
   bun <skill>/scripts/gate.mjs --start index.html --kind <kind> --category "<what is sold>" --primary "<main action>"
   ```

   A framework build arms its dev server's URL or its built page and rebuilds before every gate
   run. → `gate.md`, Arm it.
2. **Write all the copy first.** Nothing is invented but a coined brand name (searched first) and,
   on a place, plausible hours and prices marked `data-assumed`. → `copy-voice.md` (start here),
   `copy-registers.md`, `copy-moves.md`, within the rules of `copy.md`.
3. **Plan the page as screens:** line 1 the kind, line 2 the deal, one line per section; pick the
   photographs now; then read `cards.md` and every recipe you use in `sections-library.md`. →
   `sections.md` section 1, `photos.md`.
4. **Deal, never choose by taste.** Each command keeps a history, so pages differ:

   ```bash
   bun <skill>/assets/layout/deal.mjs --type <page type> --has <photo,ui,film,object,setting> --history .taste-skill/layout-history.json   # the hero; a game adds --kind gaming, hardware --kind tech
   bun <skill>/scripts/start.mjs deal --page <kind> --trade <trade> --history .taste-skill/history.json    # three palettes made for the trade, three pairings: take the first; add --axis after a word or editorial hero
   bun <skill>/scripts/start.mjs css --page <kind> --palette <id> --type <id> --radius soft --history .taste-skill/history.json
   bun <skill>/scripts/start.mjs brand --page place --bg "#.." --ink "#.." --accent "#.." [--surface "#.."] [--muted "#.."] --type <id> --radius soft   # the client's own colours (a logo, a painted shopfront), in place of css
   bun <skill>/scripts/moments.mjs pick --page <kind> --count 1|2 --fits section,statement --photo --history .taste-skill/history.json   # every kind
   bun -e "for(const l of process.argv.slice(1)){const o=l.split('|');console.log(o[Math.floor(Math.random()*o.length)])}" <the kind's lists>
   ```

   The kind's lists, in order nav, footer, close, rhythm, buttons, then the mark
   `"wordmark|initial|arc|ring|stack|dots"`: the line under each plan in `sections.md` section 3; a
   place reads its whole line from section 4, Place (The deal). Take the first palette and pairing;
   never violet; radius by kind (`system.md`, Radius and buttons); write every result on plan line 2
   and in the comment at the top of `<body>`, and build exactly that. → `sections.md` section 2,
   `layout-v4.md` (heroes, type).
5. **Build** in `starter.html`, each section to its recipe, the kit's classes and tokens only. Last:
   `photos.mjs credits` for the footer line, then `icons.mjs scan index.html --out assets/icons --colour`.
   → `system.md`, Build.
6. **Check, look, then gate**, only with the skill's scripts, never a browser tool (how they run:
   `gate.md`, Running the checks):

   ```bash
   bun <skill>/scripts/copy-lint.mjs index.html --kind <kind>
   bun <skill>/scripts/consistency.mjs index.html --widths 1440,1024,820,768,390 --rhythm-widths 1440,820,768,390 --profile <dir> --page <kind> --category "<what is sold>" --primary "<main action>"
   bun <skill>/assets/layout/check.mjs --url index.html --profile <dir> --sizes 1440x900,1024x768,820x1180,768x1024,390x844 --shots shots/layout
   bun <skill>/scripts/shoot.mjs --url index.html --w 1440 --out shots/1440.png --profile <dir>
   bun <skill>/scripts/perf.mjs index.html --profile <dir>
   bun <skill>/scripts/gate.mjs index.html
   ```

   Fix every FAIL and read every screenshot against the checklist (Common Mistakes). Run the gate
   in every harness until its last line is `GATE: PASS` or `GATE: OPEN`, three rounds at most; when
   the user tells you to stop or to ship as is, `gate.mjs --done "<what they said>"`. →
   `gate.md`, Running the checks (profiles, `--root`, widths, fix rounds), then the rest of
   `gate.md`.
7. **Report:** the `GATE:` line first, then every waiver with its reason and every open FAIL; the
   kind, the deal (palette and why it fits, pairing, hero, grounds, effect, moments, scene); the
   voice card in one line and every copy-lint WARN kept, with why; the checker, layout and perf
   results; what you could not check; every assumed fact (the checker's `assumed` list) and the
   coined name's search; the form's `.example` stand-in and the canonical domain still to come; the
   photographs and art the client must supply, every stand-in frame among them (library and live
   search); every client slot, its file and its stand-in.

## Implementation

Open the reference of every asset family the page uses first. Read `copy.md`, `copy-voice.md`,
`system.md`, `layout-v4.md` and `sections.md` in full before the first page. All references are in
`references/`. A dash means never.

| Need | Asset | Software, gaming | Hardware | Product, service | Place | Reference |
|---|---|---|---|---|---|---|
| Heights, edges, heroes, type | `system.css`, `assets/layout` | dealt hero | dealt hero | dealt hero | place hero | `layout-v4.md` |
| Sections and recipes | `starter.html` | its plan | product plan | its plan | place plan | `sections.md`, `sections-library.md` |
| Tokens, grid, buttons, nav, footer, colour | `system.css`, `system.js` | yes | yes | yes | place tokens | `system.md` |
| Forms, keyboard, head and share tags | `starter.html`, `system.css`, `system.js` | yes | yes | yes | yes | `system.md` |
| Copy, contacts, credits | `scripts/copy-lint.mjs` | yes | yes | yes | yes | `copy.md`, `copy-voice.md` |
| Hero entrance, hover, press, focus, nav, tabs | `assets/motion` | yes | yes | yes | yes | `motion.md` |
| Card loops, a count | `assets/motion`, `assets/ui` | yes | yes | - | - | `motion.md`, `cards.md` |
| Photographs | `scripts/photos.mjs` | people, customers; a game's art, else stand-ins of its setting | lead | lead | lead, 12-20 | `photos.md` |
| Real tool, app and file icons | `scripts/icons.mjs` | yes | yes | tools really used | - | `icons.md` |
| Feature cards, UI fragments | `assets/ui` | lead (gaming: none) | its app | an app the client runs | - | `cards.md` |
| Diagram cards (hub, lanes, pulses) | `assets/diagrams` | 0-2, pulsing | 0-2, pulsing | 0-1, still | - | `diagrams.md` |
| CSS grounds | `assets/backgrounds` | 0-2 dealt | 0-2 dealt | flat tokens | flat tokens | `backgrounds.md` |
| Shader grounds | `assets/effects` | the one effect | the one effect | - | - | `effects-usage.md` |
| Creative parts (`fx-*`) | `assets/components` | yes | yes | `fx-photo` plain, `fx-map` still | `fx-map` still | `effects-creative.md` |
| Objects and prints | `assets/objects` | one, as the effect; a render when the brief asks for 3D | its render when the brief asks for 3D | its render when the brief asks for 3D | - | `effects-objects.md` |
| Award-site moments | `assets/moments` | 1-2 | 1-2 | 1-2 (photo, type) | 1-2 (photo, type) | `moments.md` |
| Big scenes | `assets/scenes` | 0-1 | 0-1 | - | - | `scenes.md` |
| Speed and weight | `scripts/perf.mjs` | yes | yes | yes | yes | `perf.md` |
| The finish gate, waivers, hooks | `scripts/gate.mjs` | yes | yes | yes | yes | `gate.md` |

## Common Mistakes

### Never

- A card, row or tile that fades in on scroll; a fade-in on every section; parallax on text;
  scroll-jacking; random blinking.
- Stock photographs passed off as the client's product, people or place (a stand-in is listed in
  the report as one, never shown with another maker's name or logo); a product page that never
  shows the product.
- A drawn look-alike of a real logo; invented reviews, quotes, customers or figures.
- Violet or lavender in the page's own design: accent, ground, gradient, effect colour or tint (a
  real third-party logo keeps its own colours, `icons.md`).
- Copying a reference site's code, copy, pictures or signature effect.
- Deleting or editing the kit's own files (`assets/`, `scripts/`) to clear a check: a check that
  flags a kit file is reported, and the page is checked again after any change.
- Hiding anything from the checker; a FAIL you judge false is waived (`gate.md`, Waivers).

### Checklist failures

Each line names its checks: `consistency.mjs` ids in brackets, `check.mjs` findings in braces,
`perf.mjs` rows. The last line is for your eyes.

- **First screen:** says what is sold, for whom or where, with one hard fact [copy-headline,
  copy-fact]; the hero fills it alone at every width, its main button inside it [hero-screen,
  hero-fill, fold-action, fold-cut] {hero-fold}.
- **One section per screen:** every section 1 or 2 screens, its h2 first and top-aligned, no
  neighbour's heading or picture in its tile, nothing sparse, no section half empty
  [section-height, one-section, one-heading, section-air, one-screen, section-gaps, empty-area]
  {screen-short, screen-height, sparse, neighbour, neighbour-ground}.
- **Equal edges:** every block on the `.wrap` lines or the grid's columns, nothing out to one side,
  no sideways scroll [container-edges, row-lines, split-pair, off-grid, right-edge, col-edge,
  spill, off-viewport, stagger, top-stagger] {edge-left, edge-right, spill, bleed-one-side,
  one-sided, lines}.
- **Every visual draws** at 1440, 1024, 768 and 390; a refused effect shows its still fallback
  [visual-empty, empty-visual, gl-fallback, shader-lint, no-visual, photo-weight].
- **No caption** explains, apologises for or labels a picture; credits in one footer line
  [visual-caption, caption, credit-wall, photo-credit]; no placeholder, sample note or printed
  `.example` address [placeholder, sample-label].
- **The right things for the kind:** outside tech no effect ground, print or scene, only the
  dealt photo- or type-led moments (WebGL only for a product render the brief asked for)
  [effect-kind, effects-fit, photo-print]; the subject itself shows: the product big, whole in
  three sections at most, a new picture each [product-shown, same-object, photo-repeat]; each asset
  the brief names in its slot; a game's name and its world as key art, the diff of a code-review
  tool, software's `app-frame`; real photographs where they fit, none twice [photo-set,
  photo-repeat, photo-upscale]; real icons in their own colours; flat grounds on other [grounds]; a
  place deals two different compositions and one type moment.
- **Motion:** house rule 5 holds [motion-layer, hover, hover-move, tilt, hero-enter, moment-none,
  loop-cycle]; nothing moves because the page scrolled except a dealt moment inside its own section
  (every kind) or the big scene (tech) [scroll-linked, scroll-reveal, pinned: expected only there];
  anything moving past 5 s has a pause button [loop-pause]; under reduced motion everything rests
  and nothing stays hidden [reduced-motion, hidden-content]; at most four live contexts [webgl].
- **Contacts** as house rule 9 [street-number, postcode, coordinates, company-number,
  phone-number]; Get directions only with a street, "See the area" with a district, no map link
  with a town only [map-link].
- **Keyboard and head:** every control named, alt on pictures, labels you can see, headings one
  level at a time, no tabindex above 0; Tab reaches the skip link first, its ring shows at once and
  never under the header; the menu button says its state; lang, title, description and share tags
  [a11y-name, img-alt, field-label, heading-order, tabindex, skip-link, focus-ring, focus-visible,
  focus-hidden, menu-toggle, lang, page-meta, share-meta].
- **One system:** one button pair, one card style, one radius scale, one link look [button-styles,
  button-shape, card-family, card-layout, link-styles]; two boxes deep at most [nesting]; one
  heading scale, its faces loaded [heading-scale, font-load]; text contrast [text-contrast,
  contrast].
- **Copy and links:** headings name things, buttons a verb and an object, at most two hero actions
  [copy-headings, copy-buttons, copy-actions, action-count]; one action twice a screen at most
  [action-repeat]; a heading's grey half is its own sentence [run-on]; one fact, one wording
  [fact-agree]; assumed facts marked, never an open-now line from them [assumed, open-now]; every
  link lands, forms send, a confirmation only after a real send, each error under its own field
  [links, forms, form-send, form-fields]; no slop word, stock line, leftover or device used as a
  tic, a voice of its own (copy-lint's ids: copy-residue, copy-slop-word, copy-stock-phrase,
  copy-two-fragment, copy-virtue, ...; `copy-voice.md`).
- **Fast:** no FAIL row in `perf.mjs` (image weight, contexts, layout shift).
- **820, 768, 390 and 320:** sections on their screens [section-height]; on a phone a section is at
  least its screens and grows with what it holds, so nothing lies on anything else or under a fixed
  bar [collide]; every link and control outside running text 44px tall [tap-size] (a FAIL when
  another target is under 8px away); nothing past the screen at 320 [off-viewport], and nothing
  lies on anything else there either [collide]; the first screen ending whole or on a clear bleed
  [fold-card] (`layout-v4.md`); splits stack text first, no row half empty; one column at 390,
  buttons full width, a full-screen menu; the place action bar.
- **Your eyes:** beside the figma.com and x.ai frames it reads as a professional company site;
  nothing tilted, staggered, cut or overlapping; the hero is the work, not a mood.
