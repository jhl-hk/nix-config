Harden the interface against the inputs, errors, languages and network conditions real users bring. Worst-case data generation (long text, emoji, empty, huge counts) lives in the `break-ui` skill; use it to produce the stress cases, then fix with the rules below. States (hover, disabled, loading, error, empty) follow [craft-floor.md](craft-floor.md); empty-state content follows [clarify.md](clarify.md).

## Assess

1. **Extreme inputs:** run `break-ui` cases against the target.
2. **Errors:** offline, slow, timeout; 400/401/403/404/429/500; validation; permissions; concurrent operations.
3. **Internationalization:** expansion (German is often ~30% longer), RTL, CJK, emoji, date, number and currency formats.

## Text overflow

```css
.truncate { overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.line-clamp { display: -webkit-box; -webkit-line-clamp: 3; -webkit-box-orient: vertical; overflow: hidden; }
.wrap { overflow-wrap: anywhere; hyphens: auto; } /* anywhere, not break-word: also fixes flex/min-content overflow (break-ui) */
.flex-item { min-width: 0; }               /* let flex items shrink below content size */
.grid-item { min-width: 0; min-height: 0; }
```

- Body floor 16px (14px only for genuinely secondary text). iOS Safari zooms focused inputs under 16px.
- Test at 200% zoom; containers grow with text.

## Internationalization

- Budget 30–40% extra space; no fixed widths on text containers; test the longest language.
- Size buttons by padding, not width: `px-4 py-2`, not `w-24` (same Tailwind classes in Astro, Vue or JSX).
- Logical properties for RTL: `margin-inline-start`, `padding-inline`, `border-inline-end`; mirror directional icons with `[dir="rtl"] .arrow { transform: scaleX(-1); }`.
- UTF-8 everywhere; emoji can be 2–4 bytes.

**Arabic-script specifics** (Arabic, Persian, Urdu, Pashto, Kurdish):
- Preserve Zero-Width Non-Joiner (U+200C). Persian and Kurdish use it inside compound words; stripping it changes meaning.
- Yeh and Kaf variants: Persian ی (U+06CC) / ک (U+06A9), Arabic ي (U+064A) / ك (U+0643). Store the original; treat them as equivalent for search and validation so either keyboard matches.
- Locale digits and calendars via `Intl`:

```javascript
new Intl.NumberFormat('fa-IR').format(1234);                 // ۱٬۲۳۴
new Intl.NumberFormat('ar-SA').format(1234);                 // ١٬٢٣٤
new Intl.DateTimeFormat('fa-IR').format(new Date());         // Solar Hijri
new Intl.DateTimeFormat('ar-SA-u-ca-islamic').format(new Date());
new Intl.DateTimeFormat('de-DE').format(date);               // 15.1.2024
new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD' }).format(1234.56); // $1,234.56
```

**Pluralization** with `Intl.PluralRules`, not `count !== 1 ? 's' : ''`:

```javascript
const rule = new Intl.PluralRules(locale).select(count); // 'zero' | 'one' | 'two' | 'few' | 'many' | 'other'
const label = messages.items[rule].replace('{count}', count);
```

## Errors

- Network: say what happened, offer retry, handle timeouts, offline mode where it applies. Error copy follows [clarify.md](clarify.md).

Astro (React uses the same expression; Vue: `<div v-if="error" role="alert">`):

```astro
{error && (
  <div role="alert">
    <p>Couldn't load projects. {error.message}</p>
    <button type="button" data-retry>Try again</button>
  </div>
)}
```

- Forms: inline errors near the field, specific fixes, keep user input, don't block submission needlessly.
- API status: 400 validation errors; 401 redirect to login; 403 permission message; 404 not-found state; 429 rate-limit message; 500 generic error with a support path.
- One failing component never blocks the whole interface.
- Graceful degradation: core paths work without JavaScript; feature detection, not browser detection.

## Boundaries

- **Large datasets:** paginate or virtualize; never load 10,000 items at once.
- **Concurrency:** disable submit while pending, handle races, optimistic updates with rollback, conflict resolution.
- **Permissions:** no-view, no-edit and read-only states that say why.
- **Interrupted gestures** (custom sliders, drag surfaces, scrollable control strips):
  - A second pointer mid-drag: the first drag keeps its pointer or ends cleanly, never jumps.
  - On `pointercancel`, `lostpointercapture`, release outside the control, or window `blur`: clear the dragging state and release capture.
  - The next tap or drag works without a reload.

## Input validation

- Client: required, format, length, pattern. Server: always validate and sanitize; rate-limit.

```html
<input type="text" maxlength="100" pattern="[A-Za-z0-9]+" required aria-describedby="username-hint" />
<small id="username-hint">Letters and numbers only, up to 100 characters</small>
```

## Accessibility and performance resilience

- Keyboard reaches everything; logical tab order; focus managed in overlays; skip links.
- Live regions announce dynamic changes; semantic HTML; colour is never the only cue; test Windows high-contrast mode.
- Slow connections: progressive images, skeletons, optimistic UI, service-worker offline where useful.
- Clean up listeners, subscriptions, timers and pending requests (`AbortController`) on unmount.
- Debounce search and throttle scroll handlers. Inline or import a named helper (e.g. `import { useDebounceFn } from '@vueuse/core'`); never assume a global:

```javascript
const debounce = (fn, ms) => { let t; return (...a) => { clearTimeout(t); t = setTimeout(() => fn(...a), ms); }; };
const debouncedSearch = debounce(handleSearch, 300);
```

## Testing

- Manual: extreme data, other languages, offline, throttled network, screen reader, keyboard only, target browsers.
- Automated: unit tests for edge cases, integration tests for error paths, E2E on critical paths, visual regression, axe; a behavioral regression for each confirmed gesture fix when the runner can drive input.

## Verify

- 100+ character names, emoji in every field, RTL, CJK.
- Offline and throttled network; 1000+ items.
- Submit clicked 10 times rapidly.
- Interrupted gestures: second finger mid-drag, scroll across the control, release outside, switch windows; then drag again.
- Forced API errors and emptied data.

For gestures, say what produced the evidence (emulated viewport, synthesized touch, engine, physical device) and what stayed untested.
