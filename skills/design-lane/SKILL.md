---
name: design-lane
description: Route for setting or changing how a product looks - a visual direction, a design system, a redesign, or the first UI of a project that has none. Runs the ui-designer agent to propose distinct directions with rendered samples, lets the human choose, then writes docs/design/DESIGN.md that every later screen follows.
---

# Design Lane

Screens look template-made when nothing was chosen. This lane makes the choice explicit, once, and writes it down where every later agent reads it: `docs/design/DESIGN.md`.

## When to use it

- The human asks for a visual direction, a design system, a restyle or a redesign
- A UI feature is about to start in a project with no screens yet and no `docs/design/DESIGN.md` — suggest this lane first; the human may skip it
- A UX audit finds the "made-by-a-template look" across many screens — the fix is a direction, not screen-by-screen patches

## 1. Scope — one batch, each question with a default

- Which screens are in scope (default: the most-used two)
- Who uses them, how often, on what device (default: `.agent/project.md` → "UI / UX")
- Constraints: existing brand colours or fonts, an existing token file, accessibility level (default: WCAG 2.2 AA)
- Products or sites the human admires — and ones they dislike (default: none; the designer proposes references)

Record `design: <slug>` and `phase: DESIGN-DIRECTION` in `.agent/state.md`.

## 2. Directions → the human chooses

```
ui-designer — DIRECTION mode:
  DIRECTION mode — <slug>: <the human's request, in full>
  Screens: <which>   Users: <who, how often, device>
  Constraints: <brand, token file, accessibility>   Admired / disliked: <names or none>
  Write docs/design/directions.md, with a rendered sample per direction if the project can render pages
```

Show the directions with their sample screenshots and the designer's recommendation. Set `gate: awaiting-pm`. The human picks one, mixes ("A's density with B's colour"), or sends it back.

## 3. System → DESIGN.md

```
ui-designer — SYSTEM mode:
  SYSTEM mode — <slug>: the human chose <direction, and any mix in their words>
  Write docs/design/DESIGN.md
```

Then stop and report. Applying the system to the code is **a normal feature** in the full pipe ("apply DESIGN.md to the shared components and the two most-used screens") — so it gets a plan, a checkpoint per task, and a UX audit against DESIGN.md like any other build.

## After this lane

`ux` (DESIGN and AUDIT), `tech-lead-plan` and `developer` all treat `docs/design/DESIGN.md` as binding. A change to it goes back through this lane, not into a feature task.
