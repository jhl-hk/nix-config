# Copy voice

Decides what the words say and how they sound, so two pages for two clients never read like one
writer. Read at step 2, before the first sentence; the file map and the rules that win over this file
are in `copy.md`. The tells this file prevents, and why models write them, are in `copy-tells.md`.

Professional copy uses the same devices as model copy. What separates it: its details are **true**
(often a little inconvenient); each device is used **once**, where it lands hardest; every brand has
its **own voice**; it takes **risks** (names an enemy, admits a limit); its pages are **uneven**,
leaving out what has nothing true to say. **The fix is facts and decisions, never synonyms.** A word
swapped for its synonym is the next tell.

## 1. The fact sheet, from the brief

Before a sentence, write down what the brief, the client's files or an existing site give, word for
word where you can. Each field feeds a part of the page:

| Field | What it holds | Where it goes |
| --- | --- | --- |
| What it is | One plain sentence, no adjective | the h1 and the sub-line |
| For whom, and not for whom | The best-fit buyer; who should look elsewhere | the h1 or sub-line, one line in the FAQ |
| What they do today instead | A spreadsheet, the big rival, the bakery across town, nothing | the pain line, the comparison |
| The true difference | What is true here and not elsewhere, with its proof | the claims worth a heading |
| Customer words | Phrases from reviews, emails, the brief's own quotes | the pain line, headings |
| Numbers | Each with where it came from | sentences, the facts strip |
| People | Names and roles the brief gives | the about block, a quote |
| Odd true details | History, an object, a ritual, a house word, the awkward bit | the texture you would otherwise invent |
| A limit | What it does not do, who it is wrong for, what is closed | one admission a page |
| An enemy | A habit or a category ("re-typing invoices"), never the reader | the pain line, one section |
| The offer | Price, trial, booking terms, the one action | buttons, the close |

- **Nothing is invented** beyond what `copy.md` allows (a coined name; on a place, plausible hours and
  prices). An empty field stays empty: its section shrinks or goes, and the report lists what the client
  must supply. Never a `[NEED]`, a bracket or a "coming soon" on the page.
- **A thin brief is no reason to stop:** write the best page the facts allow. Only when a person is in
  the conversation and asks for copy (not a build) ask at most six questions in one message, most useful
  first: who switched to you from what, and why; the one number you would bet on; the objection you hear
  most; what you are bad at or not for; a strange true detail of how you work; three real customer
  messages.
- **A limit and an enemy come from the brief or from plain facts of the trade** ("closed Mondays",
  "Mac only", "no lift; rooms on three floors" when the brief says so). An invented flaw is still an
  invention.

## 2. The voice card

**The default voice is out** unless the client asks for it: warm, wry, modest, slightly literary,
mildly against big companies, ending paragraphs on a deadpan twist and saying honest, calm or quiet
about itself, with a strip of figures, three polished quotes and a pun in the footer. It is what every
model writes now, and readers know it. If the client asks for it, keep it within the device budget.

Pick one register from `copy-registers.md` by the buyer, the price and the client's real character.
When the brief does not settle it, take the one least like the last page this session wrote. Write the
card on the plan (step 3), never on the page:

```
Voice: technical-dry (copy-registers.md 2)
Pairs: exact, not cold; sure, not loud; dry only in the empty state
Person: "you" for what the buyer gets, "we" for the work; the product is the subject in feature lines
Sentences: mostly 8 to 16 words; one long one a section, where it explains
Humour: none in the hero, the prices or the FAQ
House words: the brief's own nouns (shifts, rota, cover), the same word every time
Never: virtue words about ourselves, a pun on the name, a strip of claims
```

- **Copy the client's own voice first.** A writing sample, an old site or the brief's wording overrides
  the menu (never the five rules or the integrity rules).
- **Nine other trades:** picture this voice on nine businesses in nine other trades. If it suits any of
  them, push it further toward this client.
- **Voice holds, tone moves.** The hero and the story carry the most voice. Prices, the FAQ, booking and
  forms go plain: readers there are anxious. Errors and confirmations are short and kind.
- **The register never bends copy.md's rules:** the h1 still names the category, every heading still has
  its noun, every button is still a verb and an object (`copy.md`). Voice lives in which facts you pick,
  the sentence shapes, the admission and the microcopy.

## 3. Shape from the reader's questions

A reader asks, roughly in this order: what is this, is it for me, why believe you, how does it work,
what does it cost, what if it goes wrong, what do I do now. How much they already know sets the start:

- **They do not know they have the problem:** open the sub-line on a moment they recognise.
- **They know the problem:** name it in the customer's words, then the product.
- **They are comparing:** lead with the mechanism, what this does differently.
- **They know the client:** the product, the offer, the price, the action.

- **A section exists only if the brief has true material for it.** Five full sections beat eight
  padded ones; on a place, the photographs set the count (`sections.md`).
- **Counts follow the content:** four real features are four cards, one quote is one quote, two plans
  are two plans. Zero testimonials is a normal page.
- **Find the organising idea** when the brief has one: the menu as the page, a timetable, a founder's
  letter, one object carried through every section. Let it break the template once.
- **Not the skeleton:** eyebrow, claim heading, two-line lede, three cards, figures, in every section.
  Vary what goes in the sections: a list, a table, a short letter, one longer paragraph (five lines
  at most, `copy.md`), a heading with one line under it.

## 4. Draft

Read `copy-moves.md` before drafting a whole page: it holds the move for each part (mechanism steps,
proof, buttons, risk reversal, microcopy). Across all parts:

- **Facts where adjectives want to go.** "Fast" is followed within the sentence by the figure or the
  mechanism; adjectives that stay are physical or measurable (wood-fired, 58 mm, ground-floor).
- **Proper nouns over categories:** the tools by name, the street, the river, the bus line.
- **The pain in the customer's words,** before the product, when the brief gives them.
- **One admission a page,** said plainly, from the brief.
- **Numbers in sentences, with their unit,** uneven where real.
- **Microcopy is written in the register,** including a cookie notice if the page needs one; this is
  where a dry line is welcome.
- **Sentence length follows meaning.** A short sentence lands a point; a long one carries an
  explanation. Not every line punchy; not variety by rule either.
- **Repeat the product's name** rather than cycling through "the platform, the tool, the solution".

## 5. The device budget, per page

None of these is banned; each works once. The problem is using them by default. `copy-lint.mjs`
counts them: over the budget is a WARN, twice the budget plus one or more is a FAIL (a tic).

| Device | Budget | Note |
| --- | --- | --- |
| Heading in two fragments "X. Y." | 1 | spend it where it lands hardest |
| Number-pair heading "Four X, one Y" | 0 to 1 | the most repeated model habit |
| Negation run "No X. No Y." | 1 | only when each item is a refusal a buyer can check |
| Contrast "X, not Y", isn't, rather than, instead of, without the | 2 in all | banning one form moves you to the next; count them together |
| Dry closing line on a paragraph | 2, never in a row | most paragraphs end on information |
| Pun on the name or its metaphor | 1, never the h1 | it is the page's one brand line (`copy.md` rule 3) |
| Sign-off line in the footer | 0 | the footer holds facts (`copy.md`) |
| Strip of figures | facts from the brief only | never invented KPIs |
| Virtue words about ourselves | 0 | the lint skips literal ones (a quiet room, calm water, genuine parts) and allows 2 |
| Lists of three | when there are three things | never in consecutive sentences |
| Step numbers on cards | only where the order is the content (a booking's steps) | none on features that read in any order |
| Eyebrow labels | 1 or 2 a page | a heading that names the thing needs none |
| Testimonials | the brief's only | name and role or town; none is fine |
| Response-time promise | 1, from the brief | the same words wherever it repeats |
| "Since [year]" | 1, from the brief | |

## 6. Check

At step 6, before the gate (which runs the lint again):

1. **Lint:** run copy-lint (`copy.md`). Fix every FAIL. Fix each WARN, or keep it on purpose and say
   why in the report.
2. **A rival's name:** put a rival's name, or the same trade in another town, into the h1, the sub-line
   and each heading. A line that still reads true says nothing about this client: rewrite it from the
   fact sheet.
3. **Sameness across pages:** when this session built other pages, pass them all to `copy-lint.mjs`
   at once and read the first headings side by side, and the heading phrases they share. A shared
   cadence or joke is a tic: break it.
4. **Read it aloud, as the client.** Cut every sentence they would not say about themselves.
5. **Over-correction:** after the fixes, look for the habit that replaced the one you removed: "rather
   than" multiplying, every sentence a fragment, everything in pairs, a joke deleted and nothing in its
   place. A rule that made a sentence worse is broken on purpose.
6. **A fresh reader,** when the run can spare a subagent: give it only the page's text and ask what
   this is, who it is for, why this over the alternative, what it costs, what would make it hesitate,
   and which three lines sound like any other website. Fix what it finds. Never iterate to beat an AI
   detector.

The report carries the voice card in one line, every assumed price or hour (`copy.md`), and what the
client must supply.
