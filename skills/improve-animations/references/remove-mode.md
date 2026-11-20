# Remove mode

Read before any Remove-mode edit. The gate and severity table are in SKILL.md; the hunt list is AUDIT.md §1.

The burden of proof is reversed: an animation stays only if it passes the gate. "It's already there" and "it looks nice" are not defenses. Deleting everything is also wrong: motion that bridges a jarring change (a toast that would otherwise teleport in, a panel that shows where it came from) earns its place, and removing it trades a slow interface for a disorienting one.

## Rules

1. **Only subtract.** Every edit deletes an animation, reduces it, or removes code it orphaned. Never add motion, change a curve or retune a spring; list a badly built keeper in the report instead.
2. **Check the hazards** below before every Delete and Reduce. A removal that leaves an element invisible or breaks unmount timing is a regression.
3. **Ask before removing a dependency.** Uninstalling a motion library touches the lockfile and other people's work; propose it.

## Reducing

A smaller version of the same motion, never a different animation:

| Today | Reduced to |
| --- | --- |
| Hover with scale, lift or shadow growth | Color/opacity change only, ≤150ms, `ease` |
| Slide or scale entrance on a frequent surface | Opacity only, 150ms, `ease-out` |
| UI animation over 300ms | 200–250ms, same curve |
| Stagger over 80ms per item, or over 300ms total | Cap at 30ms per item, or drop the stagger and fade the group as one |
| Infinite loop (pulse, shimmer, glow) on a persistent element | Run once, or remove the loop and keep the static end state |

If reducing would leave motion too small to carry its purpose, delete it.

## Removal hazards

- **Hidden start states.** Keyframes with `animation-fill-mode: forwards` from `opacity: 0`, Motion's `initial={{ opacity: 0 }}`, or a reveal class that starts at `opacity: 0` until an observer fires. Remove the start state with the animation, or the element stays invisible forever.
- **Code that waits for the animation.** `onAnimationEnd`, `transitionend` listeners, `onExitComplete`, and `setTimeout` calls sized to a duration. Delete the wait too, or the UI keeps pausing for motion that no longer exists.
- **Exit animations that delay unmount.** `AnimatePresence` holds a component in the DOM until its exit finishes, and `onExitComplete` fires after. Without the exit the component unmounts immediately — move whatever ran in `onExitComplete` to where the component is closed.
- **Layout animations hiding a jump.** Motion's `layout` prop or a FLIP animation can mask a layout shift. If removing it reveals a jump, keep the animation and report the shift; fixing layout is out of scope.
- **Focus timed after motion.** Focus moved in an animation callback must move immediately once the animation is gone.
- **Tests and selectors.** Tests that wait for animation classes or durations need the same removal.

## Cleanup

Delete what the removals orphaned:

- `@keyframes` and animation utilities no longer referenced anywhere.
- `motion.div` → `div` (and other `motion.*` elements) where no motion props remain.
- Empty `AnimatePresence` wrappers and unused variants objects.
- Motion imports in files that no longer animate.
- Animation entries in the Tailwind config or token files with zero references.
- If the motion library is no longer imported anywhere, say so and propose removing the dependency.

## Workflow

1. **Recon** (SKILL.md).
2. **Sweep** the hunt list in AUDIT.md §1. Done when every class has yielded candidates with `file:line` evidence or been explicitly cleared.
3. **Gate** every candidate; record the deciding test.
4. **Check hazards** for each Delete and Reduce.
5. **Edit**: deletions and reductions, then cleanup.
6. **Verify**: type checker and tests if the project has them; grep every removed keyframe, class and variant name to confirm nothing references it.
7. **Report:**

**Part 1 — Removed and reduced**, ordered by how often the user hits it:

| # | Location | Was | Verdict | Deciding test |
| --- | --- | --- | --- | --- |
| 1 | `CommandMenu.tsx:24` | 200ms scale + fade on open/close | Deleted | Keyboard-triggered |
| 2 | `ProjectCard.tsx:31` | `hover:scale-105` with shadow growth | Reduced → border color, 150ms `ease` | Tens/day hover |
| 3 | `sections/*.tsx` | `whileInView` fade-up on 9 sections | Deleted, `initial` opacity removed | No purpose |

**Part 2 — Kept (required):** 2–5 animations considered and kept, each with the purpose that saved it, then keepers that are badly built, for a plan:

- `Toast.tsx:41` — enter from bottom edge. **Kept: prevents a jarring change; occasional frequency.**
- `Onboarding.tsx:88` — success confetti. **Kept: rare, first-time moment.**
- `Dropdown.tsx:12` — `ease-in` on enter. Kept; should be `ease-out`.

**Part 3 — Cleanup and verdict:** orphaned code removed and any dependency proposed for removal, then one paragraph: how over-animated the interface was, how it feels now, and what needs a human on a real device (hover feel, perceived speed).
