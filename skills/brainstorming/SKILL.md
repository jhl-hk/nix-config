---
name: brainstorming
description: Use before building or changing anything — a new feature, component, endpoint, project, or a change to existing behavior — to agree on intent and design with the user before implementation.
---

# Brainstorming Ideas Into Designs

## Overview

Turn an idea into an approved design through dialogue: classify how much process the request needs, understand the context, refine the idea, present a design, get approval.

**Hard gate:** no implementation skill, code, scaffolding or other implementation action until the user has approved what you intend. This holds on every path, however simple the task: a todo list, a one-function utility or a config change still gets a design (maybe two sentences) and approval. What scales with the task is the artifact, never the approval. Present, then stop until you hear an explicit yes; presenting and starting in the same breath skips the gate.

## Three paths

Before your first question, classify the request and say so ("this looks bounded, so I'll present a short design here rather than write a spec"), so the user can override it.

- **Spike** — a feasibility question ("can we...", "is it possible...", "quick and dirty is fine") whose output is an answer, not code you keep. State the question and what you'll try in 2–3 sentences, get a nod, find out as cheaply as correctness allows. No design doc, no spec. Report a recommendation; anything built stays labelled throwaway.
- **Bounded** — a well-scoped change to code that already exists in this repo: a new flag, a small endpoint, a one-file fix. Bounded means the flow you are changing is already here to read; if there is no existing flow, it is not bounded. Ask the questions that matter, present a short design in chat, and stop. Implementation starts only after the user says yes. No spec file, no plan document.
- **Architectural** — new projects, new subsystems, changes to how components fit together or to interfaces others depend on. Full process: questions, approaches, sectioned design, written spec, then the writing-plans skill.

In doubt, take the heavier path; reaching for a lighter label to skip work is itself the doubt. The ratchet is one-way: hidden complexity found mid-task upgrades the path (stop, say so, step up, even when almost done); nothing downgrades.

## Checklist

Classify, announce the path, then put each item of that path on the todo list and work through them in order.

**Spike**
1. Explore project context — enough to frame the probe.
2. Present question and probe plan — 2–3 sentences.
3. Get approval — a nod is enough.
4. Investigate — as cheaply as correctness allows.
5. Report findings — a recommendation; label anything built as throwaway.

**Bounded**
1. Explore project context — files, docs, recent commits.
2. Ask clarifying questions — one at a time, only the ones that matter.
3. Present a short design in chat — approach, files touched, testing.
4. Get approval — stop and wait for an explicit yes.
5. Implement — normal development workflow (test-driven-development applies); no plan document.

**Architectural**
1. Explore project context — files, docs, recent commits.
2. Offer the visual companion just in time (see below) — never upfront.
3. Ask clarifying questions — one at a time: purpose, constraints, success criteria.
4. Propose 2–3 approaches — trade-offs and your recommendation.
5. Present the design — in sections scaled to their complexity; get approval after each.
6. Write the design doc — `docs/specs/YYYY-MM-DD-<topic>-design.md` (a user-specified location wins), then commit.
7. Spec self-review — fix inline (see below).
8. User reviews the written spec.
9. **REQUIRED SUB-SKILL:** Use writing-plans. It is the only skill you load after an architectural brainstorm — no implementation skill.

Bounded ends in implementation through the normal workflow; spike ends in a reported recommendation.

## The process

Bounded work needs only context, a few questions and a short in-chat design. The rest of this section is architectural depth.

**Understanding the idea**
- Check the current project state first: files, docs, recent commits.
- Assess scope before detailed questions. If the request spans several independent subsystems ("a platform with chat, file storage, billing and analytics"), say so immediately and help decompose it: the pieces, how they relate, build order. Brainstorm the first sub-project; each gets its own spec → plan → implementation cycle.
- One question per message. Prefer multiple choice; open-ended is fine.

**Exploring approaches**
- 2–3 approaches with trade-offs; lead with your recommendation and why.
- YAGNI ruthlessly: remove unnecessary features from every approach.

**Presenting the design**
- Sections scaled to complexity: a few sentences if straightforward, up to 200–300 words if nuanced. Ask after each whether it looks right.
- Cover architecture, components, data flow, error handling, testing.

**Design for isolation**
- Units with one clear purpose, well-defined interfaces, understandable and testable on their own. For each: what does it do, how is it used, what does it depend on?
- If a unit cannot be understood without reading its internals, or its internals cannot change without breaking consumers, the boundaries need work.
- Small, focused files are also easier for you to reason about and edit reliably; a large file is often doing too much.

**Existing codebases**
- Explore the current structure first and follow existing patterns.
- Where existing problems affect the work (an oversized file, tangled responsibilities), include targeted improvements in the design. No unrelated refactoring.

## After the design (architectural)

**Spec self-review** — reread the spec with fresh eyes:
1. Placeholders: any "TBD", "TODO", incomplete sections, vague requirements?
2. Consistency: do sections contradict each other; does the architecture match the features?
3. Scope: focused enough for one implementation plan?
4. Ambiguity: could a requirement be read two ways? Pick one and make it explicit.

Fix issues inline; no second review pass.

**User review gate** — then ask:

> "Spec written and committed to `<path>`. Please review it and let me know if you want any changes before we write the implementation plan."

Wait. If changes are requested, make them and rerun the self-review. Proceed to writing-plans only on approval.

## Visual companion

A browser tab for mockups, diagrams and visual options — a tool, not a mode. Accepting it means it is available for visual questions; it does not route every question through the browser.

**Offer it just in time:** only when a question would genuinely be clearer shown than told — a real mockup, layout or diagram question, not merely a UI topic. Offer it then, in a message containing nothing else:

> "This next part might be easier if I show you — I can put together mockups, diagrams, and comparisons in a browser tab as we go. It's still new and can be token-intensive. Want me to? I'll open it for you."

Wait for the answer. If accepted, read `visual-companion.md` in this skill's directory first, then start the server as it describes (`scripts/start-server.sh --project-dir <project root> --open`). If declined, continue in text and do not offer again unless the user raises it.

**Decide per question:** would the user understand this better by seeing it than reading it? Browser for visual content: mockups and wireframes, navigation and component designs, architecture and data-flow diagrams, side-by-side comparisons (layouts, colour schemes, design directions), look-and-feel polish (spacing, visual hierarchy), state machines, flowcharts and entity relationships. Terminal for answers in words: requirements and scope, conceptual A/B/C choices, trade-off lists and comparison tables, technical decisions (API design, data modelling, approach selection), clarifying questions. A question about a UI topic is not automatically visual: "What does personality mean here?" and "What kind of wizard do you want?" are conceptual; "Which wizard layout works better?" is visual.

## Common Mistakes

| Thought | Reality |
|---|---|
| "I understand this kind of app, so it's bounded" | Bounded measures the repo, not your familiarity. A new project has no existing flow. |
| "The spike works, so I'll keep the code" | A spike's output is an answer. Keeping the code is a new request — classify it. |
| "They approved the spike, so the follow-up is approved too" | Each task gets its own classification and approval. |
