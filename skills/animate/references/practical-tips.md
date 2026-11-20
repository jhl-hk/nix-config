# Practical Tips

Fixes for specific symptoms. Rules already in SKILL.md (no `scale(0)`, trigger origin, hover gating, under 300ms, no keyboard animation) are not repeated here.

## Shaky 1px shift at start/end of a transform

GPU/CPU rendering handoff moves the element by 1px.

```css
.element {
  will-change: transform; /* keeps the element on the GPU for the whole animation */
}
```

## Sequential tooltips feel slow

First tooltip: delay + animation. Subsequent tooltips while one is open: instant, via `data-instant`. Code: RECIPES.md › Tooltip.

## Transform-origin variables

| Library | Variable |
|---|---|
| Base UI | `var(--transform-origin)` |
| Radix UI | `var(--radix-dropdown-menu-content-transform-origin)` |

## Hover flicker

A hover that moves the element moves it out from under the cursor. Move a child; the parent's hit area stays still.

```html
<div class="box">
  <div class="box-inner"></div>
</div>
```

```css
.box-inner {
  transition: transform 200ms ease;
}

.box:hover .box-inner {
  transform: translateY(-20%);
}
```

Tailwind v4's `hover:` variant applies only on devices that support hover.

## Small tap targets

Minimum sizes: 44×44pt (Apple HIG); 24×24 CSS px (WCAG 2.5.8, AA); 44×44 CSS px (WCAG 2.5.5, AAA). Enlarge the hit area with a pseudo-element, without changing layout:

```css
@utility touch-hitbox {
  position: relative;

  &::before {
    content: "";
    position: absolute;
    display: block;
    top: 50%;
    left: 50%;
    transform: translate(-50%, -50%);
    width: 100%;
    height: 100%;
    min-height: 44px;
    min-width: 44px;
    z-index: 9999;
  }
}
```

```jsx
<button className="touch-hitbox">
  <BellIcon />
</button>
```

## Still feels off after easing and timing: add blur

Subtle blur blends the two states so the eye reads one object in motion. Code (crossfade and press variants, the 20px limit): RECIPES.md › Masking a crossfade that won't settle.

## Perceived speed

A faster spinner makes an app feel faster at identical load times.
