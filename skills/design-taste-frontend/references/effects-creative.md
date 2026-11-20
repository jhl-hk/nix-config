# Effects as parts of the page

An effect can be a part of the page, not only its ground: the picture in a feature card, a real object drawn in dither, the letters of a headline, a button's fill, a border, an icon chip, a chart's area, a map. The parts are in `assets/components/` (a folder each: `component.html`, `.css`, `.js`, `meta.json`); `index.html` there shows them live with a palette switcher, starting each part only while it is near the screen.

**Tech pages only** (site-kind software, gaming or tech: hardware), except `fx-photo` (every kind, as a plain photograph) and `fx-map` (every kind with a door, a place included, baked still, only for a street the brief gives). The gate, the one-effect budget, the four-context limit and the shared motion and cost numbers: `effects-usage.md`. `fx-band` is out: a drawn band between sections is not a section. `fx-logos` is out: real logos show in their full colours and never move (rule 7, MO-57; `sections-library.md` logo-row).

## Under the one-effect rule

- **Every part that holds a WebGL context is the page's one effect:** the dither object, a filled headline or stat, the globe, the avatar ring, the progress light, the prompt glow, the edge-glow plan, `fx-spotlight`, and `fx-button`'s fill (on the one primary call to action, or one pair, fading in on hover or focus). It sits in the hero or the one `[data-visual]` frame, or serves a dealt moment in its own section; never beside a live hero ground. Painted panels in a 2x2 are card grounds drawn still, not the effect.
- The pointer effect counts against the page's one (`fx-button`, `fx-spotlight`, a turning object, or a hover or liquid moment). The street map and a photograph are content, not effects.
- Everything else stays **quiet**: a search glow only while focused, one ring on the recommended plan, chips with a still grain. **One lit border a page** (`fx-prompt` or `fx-pricing`).
- A glow only on a dark ground, once, behind the key object in the hero or `[data-visual]`, still, never spilling onto text or round a button.
- One-shot transitions (a tile flip, a melt, a crack) only once, on a click or as a hero reveal, inside the `[data-visual]`; scroll-driven only as a dealt section moment.
- Ray marching only in a dark hero, at half resolution; halftone and dither only as a still ground, never on a photograph.
- Nothing moves with scroll; a card never moves by itself. Motion lives inside a visual: a pointer clicking in a UI window, rotors that spin up under the pointer, a seat that swivels after it.

## Cost: light enough for a laptop's integrated GPU

A laptop's graphics chip shares about 2 GB with everything else; too many live canvases crash it. Only things that move hold a context (`perf.md`); everything still holds none at rest.

- **Stills render once.** An effect that does not move (speed and drift 0) goes through `still()` in `shared.js` (or `fill(el, id, { still: true })` for type): drawn once as it nears the screen, copied into a plain picture, its context freed. Stills draw one after another, so they never hold more than one context at a time. Never leave a still mounted with its frame loop running, and never give a still a pause button (Play would start its loop).
- **Screenshots wait for the stills.** On a CPU renderer each still takes about a second, so a screen captured a fixed time after a scroll catches some blank and a panel cut by two screens comes out half lit. While stills near the screen have no picture yet, `<html data-cx-baking="n">` says how many; a screenshot must wait until it is gone. `shoot.mjs` and `consistency.mjs` do not wait on it yet: shoot a page with stills (filled stats, type in an effect, painted panels) with `--wait 1500` and look for unfilled digits before judging.
- `fx-dither-object` runs once per dither cell (a ninth of the CSS pixels); `painterly-landscape` at 0.6.
- What holds a context: `fx-dither-object` (20 fps), `fx-prompt`, `fx-globe`, `fx-avatar` and `fx-progress`, each only while near the screen; `fx-button` only while pointed at (freed 4 s later); `fx-search` only while focused. A page carries one of these (the effect). Every other part is a still, and so is the dither object under reduced motion. `fx-map` (plain SVG) and `fx-photo` (the photograph itself) hold no context.

## Feature cards with inset panels (`fx-feature-card`)

A 2x2 of cards (as x.ai and Figma build it), each a title and two grey lines, then an inset panel with its own 8px margin (radius = card radius - margin). The panel holds a bright ground and one UI window that runs out through the panel's bottom edge.

- Ground: `painterly-landscape` (default) or `grain-gradient`, still, drawn once as pictures.
- A landscape takes a natural light near the page, never one hue over everything. Each panel names its light in `data-cx-scene` and its composition in `data-cx-params` (horizon, side, slope), so no two panels look alike:
  - `day`: a pale sky over hills that step down to a near slope; graphite hills under a warm accent, blue-grey under a cool one, the accent itself when it is green or neutral, deeper shades of the page colour on a colour page.
  - `dusk`: a deep blue sky lit gold only along the horizon, dark hills with a lit crest, whatever the accent (a blue glow under a blue accent reads as `day` again, only darker). The gold leans toward a warm accent but stays between amber and gold (red-orange turns the crests rust). On a colour page, a light shade of the page colour.
  - `meadow`: daylight as a photograph shows it, whatever the page: a clear blue sky paling to the horizon, a blue far ridge, a sunlit field of grass (on a blue colour page the sky is the page colour). One per grid.
  - A grid of four mixes them: for example `day`, a grain, `dusk`, `meadow`.
- A grain panel: a light warm ground under a warm accent, a deep one under a cool accent, the page colour's own shades on a colour page.
- The window shows the feature with real labels (an invoice, a checkout, a list of payouts, an invite); its content runs out through the panel's bottom edge, no empty space under the last row.
- Two panels at most run a short pointer demo (glide, click, the state changes, rest), one per row.
- Rejected: a small dialog centred on an empty ground; an orb or sphere ground; a landscape painted in the accent's hue only (it reads as a filter; an orange accent turns rust-red); a warm accent mixed into a dark ground or a complementary accent mixed into a colour page (mud).

## Objects in dither (`fx-dither-object`)

A real thing built in code as a lit 3D form and printed in ordered dither in the page tones: ground, shade, ink, accent and a deep accent. For a product with no photograph yet, as the hero picture or the visual of one split section.

- Objects: `headphones` (over-ear, on their cups), `chair` (an office chair on five castors), `camera` (a mirrorless camera with a zoom lens), `drone` (a camera drone with four rotors). Set `data-cx-object` on the figure.
- Idle: it sways slowly on its spot. Pointed at, it turns to the pointer, the light comes from the pointer, and it answers with its own working part: sound rings out of the cups, the seat swivels after the pointer (the base stays), the lens zooms out as the pointer rises and its focus ring turns, the rotors spin up into discs and the drone lifts off its legs and tips toward the pointer.
- The accent paints one part: the ear cups, the seat and back, the camera's body band and shutter, the drone's shell; their shaded side is a deep accent, never grey.
- Only an object the product really is or sells, on a tech page. One per page, no caption under the stage: the section heading or copy says what it is and gives one real fact from the client.
- A product none of the four fits gets its own photographs or a render from `assets/objects`, never the nearest of these four and never mood stock.
- The print is the render to use. `data-cx-render="studio"` (a smooth shaded render) is not for pages: at one sample per CSS pixel its edges stair-step, and next to a real product shot its forms read as toys.
- Under reduced motion it is one still picture with no context and no pause button; without WebGL a line drawing of the same object, its accent part filled.
- It is a drawing of the product, never a filter over a photograph.

## Street map of the place (`fx-map`)

A visit or contact section shows the real streets around the place, as a map app would, in the page's colours. A contour pattern standing in for a map reads as fake.

- **Bake once** at build time: `bun assets/components/fx-map/bake.mjs --lat <lat> --lon <lon> --out map.json` fetches streets, water, parks, rails and stations from OpenStreetMap (one Overpass request) and writes a small JSON (about 55 KB, 18 KB gzipped, for 3 x 2 km of a city): streets in four classes, water (the sea built from coastlines too), parks, rails and trams, up to 14 street names placed along the straightest part of each street.
- `--from none` (the default) leaves the walk out. Only on a tech page whose brief names a station: `--from auto` (the nearest station 150 m to 1.6 km away) or `--from lat,lon --from-name` adds the walk with its minutes at 80 m a minute.
- Paste the JSON inline (`<script type="application/json" class="cx-map__data">`) or name the file in `data-cx-map`.
- The part fits the pin, the walk and both names into the free part of the frame (right of the card from 900px of width; under 900px the card sits below and the map keeps the whole width), never closer than about 1 m a pixel; names go on the side the walk does not leave by (above or below on a phone). Street names show only where they fit their street and clear every other label.
- Light pages: white streets with a hairline casing on a land one step darker than the page. Dark pages: lighter streets on a land one step lighter. Water and parks keep a natural blue and green mixed into the land.
- Pointed at, or its directions link focused, the walk is drawn from the station to the door and the pin's halo answers once. Nothing moves at rest or on scroll.
- The pin sits on the street line, never on a building. The card says the walk in words ("5 minutes on foot from The Shore tram stop") and names street and district only (`copy.md`, Contacts). Get directions opens `https://www.openstreetmap.org/search?query=<street>+<district>`, never coordinates or a route link. The coordinates go only to the bake, never onto the page.
- On a place, and on any other page of kind other: baked with `--from none` (no walk, no minutes chip), nothing moves.
- The OpenStreetMap credit ("Map data © OpenStreetMap contributors") joins the footer's one credits line, never on or under the map.
- No network at build time, or a street the brief does not give: no map; the visit shows its photograph. Never ship a contour or dot fallback as a map.

## A photograph with copy (`fx-photo`)

- The client's photograph in its natural colour, the copy on its calm, dark corner (white type, no scrim); in a link it takes the photograph hover (`motion.md`, The hover layer). Words on a photograph only in the hero and one band a page, never on a place.
- No filter over it: no halftone, dither, dissolve, print, duotone or blur (`data-cx-grade` stays off).
- The photographer's credit goes in the page's one footer credit line.
- Its `effects` list is empty on purpose and `data-cx-effect` is ignored. No WebGL, nothing at rest; under reduced motion the zoom is off.

## The techniques (`components/shared.js`)

- `still(el, id)`: an effect that does not move, drawn once and kept as a picture (Cost).
- `fill(el, id)`: the glyphs of `el` (or its `[data-fill]` parts) show the effect. The overlay sits next to `el`, never inside it, so the text and HTML stay clean. `{ still: true }` for a still fill.
- `windows(host, targets)`: one canvas seen through many shapes (chips, bars, cards).
- `cx-ring`: a host shown only in its padding, a 1.5px border of the effect.
- `cx-glow`: a host blurred into a soft light behind one object.
- `pauser(host)`: a round pause button in one corner of a looping visual. **Every loop that runs on its own for more than about 5 s gets one** (WCAG 2.2.2): the panel demos, the dither object, the prompt glow, the globe, the call preview, the import preview. Under reduced motion the loops hold one state and the button is hidden. Stills (the map) need none.

## When to use each

| Part | Use it for | Not for |
|---|---|---|
| `fx-feature-card` | A 2x2 of product features | Features with nothing to show in a window |
| `fx-dither-object` | The product as an object, with no photograph (the print render) | Decoration that is not the product; a studio render |
| `fx-headline` | The hero line or closing line; fill 2-3 words | Body text, two filled lines on a page |
| `fx-stat` | 2-4 proof numbers from the brief, at the stat size (`--t-stat`, 38 at 1440) | Small numbers, count-ups, invented figures |
| `fx-button` | The one primary call to action | Every button |
| `fx-prompt` | The hero prompt box of an AI or dev product | Ordinary forms |
| `fx-search` | Docs or command search | A field that always glows |
| `fx-tabs` | A product tour or dashboard preview | Navigation |
| `fx-icon-tiles` | A feature grid with drawn glyphs | Brand logos |
| `fx-spotlight` | A row of plain feature cards (security, admin) | A page with another pointer effect |
| `fx-globe` | Products with global reach | Local businesses |
| `fx-map` | Visit or contact: the real streets around the door, baked still | A product without a place |
| `fx-chart` | One metric over time | Decoration without numbers |
| `fx-bars` | Monthly figures on a labelled scale | More than 16 bars |
| `fx-photo` | The client's own photograph of the subject, in colour | Mood stock, blank notebooks, filters |
| `fx-avatar` | Calls, presence, a team list | Static team grids |
| `fx-pricing` | The recommended plan | All plans |
| `fx-progress` | Only inside a product window, as its own import or setup step (a UI fragment) | A progress bar as a card or visual of its own (the judge marks it); page loaders |

## Picking the effect

- **Panels in feature cards:** `painterly-landscape` (with a scene), `grain-gradient`; `ruled-grounds` for a technical product's panel that holds no UI (never behind a window or fragment, `cards.md`).
- **Inside letters and digits:** `silk-folds`, `aurora-curtains` (dark and colour pages), still. On a light page, stat digits get a plain ink fade instead (an effect in digits on white reads as scratched metal). Never `fluted-glass` in type (on a colour ground it paints thick accent bars through the letters); never `caustics`, `halftone-screen` or `line-engraving` in type.
- **Inside small shapes** (chips, pills, bars): `grain-gradient` with still grain, low contrast. No silk, glass or metal sheen in a pill or a bar.
- **Inside data:** a plain accent fade under a line (the chart default) or a still `ruled-grounds`; bars take a still, low-contrast `grain-gradient`. Never an effect that draws its own grid or moving traces over a chart; never `halftone-screen` in a chart area (its tone runs across the frame, so half the area goes empty); never `grid-pulse` (its traces blink at random).
- **A map** (`fx-map`) is the baked streets, never an effect, and has no fallback ground.
- Each part keeps a table of params per effect it takes and passes only that effect's own: one effect's numbers mean something else to another (contour-lines' opacity 0.32 and calm 0.55 left dot-terrain almost blank).
- **A button's fill:** an even, low-contrast grain that moves only while pointed at; no blobs that settle at one end of the button.
- When the page's deal gives an effect listed in a part's `meta.json` `effects`, use it there (`data-cx-effect`, `data-cx-fill` for type); otherwise its `default`. A part with an empty list (`fx-photo`, `fx-dither-object`) takes no dealt effect.
- Retired effects (`marble-warp`, `truchet-arcs`, `pixel-mosaic` and the others listed in `assets/effects/README.md`) are in no part's list.

## Colour

Every part reads the page tokens. `inkPalette` draws an effect as ink (pale on dark pages, deep on light ones); `accentPalette` keeps it near the accent with the label at 4.5:1; `tone(p, k)` matches the CSS card steps. No fixed hues, with three exceptions, all natural colour: the `meadow` landscape (a blue sky over grass), the gold horizon of `dusk`, and the map's water and parks. Never violet or lavender.

## Use

Link `system.css`, `components/base.css` and the part's `component.css`, paste its markup, then `const part = init(root)` from its `component.js` (`part.destroy()` to remove). Text, controls and data stay real HTML; the effect is the picture or the light on them. Replace every number, name and the stand-in photograph with the client's own; a figure the brief does not give is left out, never invented and never tagged "sample" (`copy.md`).
