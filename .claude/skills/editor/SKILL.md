---
name: editor
description: Orchestrates paper revision workflow with 3 circuits — reduce (size), review (fix reviewer comments), humanize (remove AI language). Coordinates reviewer, editor, and humanizer agents.
disable-model-invocation: true
argument-hint: "reduce|review|humanize|full|fix <issue>"
---

# Paper Revision Orchestrator

You are orchestrating a manuscript revision workflow for an IEEE conference paper on operating room scheduling. The paper is currently 7 pages and must be reduced to 5 pages, while also addressing reviewer comments from a previous CEC submission.

You coordinate three specialized agents/skills:
1. **reviewer** agent — Read-only. Reads the CEC review PDF, categorizes comments, produces structured report.
2. **editor** agent — Read-write. Makes targeted LaTeX edits ONE AT A TIME with user confirmation.
3. **humanizer** skill — Checks edits for AI-sounding language and proposes natural alternatives.

## FILE SCOPE — STRICTLY ENFORCED

All agents spawned by this skill may ONLY access:

- `cec_pap419 Reviews Details.pdf`
- `00_abstract.tex`
- `01_introduction.tex`
- `02_related_work.tex`
- `03_operating room scheduling problem with surgical patient flow.tex`
- `05_numerical results.tex`
- `06_conclusion.tex`
- `main.tex`
- `bibl.bib`
- `figures/*`

## IMPORTANT RULES

1. **All changes are incremental.** The editor proposes one change at a time. The user confirms or denies before the next.
2. **Scope comments are skipped.** The paper was submitted to CEC but is now going to a different conference. All CEC venue-fit/scope comments are irrelevant.
3. **Positive reviews matter.** Use them to identify what to preserve and emphasize.
4. **Minimize style changes.** Keep the author's existing writing voice.
5. **After each text edit, run humanizer check** to catch AI-sounding language.

## Mode Selection

Parse `$ARGUMENTS` to determine which mode to run:

---

### Mode: `reduce`
**Trigger:** `/editor reduce`

Runs Circuit A — Reduce paper from 7 to 5 pages.

**Action:**
1. Delegate to the **editor** agent with mode "reduce":

> Work through the Circuit A reduction steps (A1–A9) in order. For each step, propose the exact change, show before/after, and wait for user confirmation before applying. After each edit, report estimated cumulative space savings.

2. After each confirmed edit, run the **humanizer** skill on the changed text to check for AI patterns.
3. Track cumulative estimated savings. Stop when approximately 2 pages have been saved.

---

### Mode: `review`
**Trigger:** `/editor review`

Runs Circuit B — Address reviewer comments.

**Step 1 — Review Phase:**
1. Delegate to the **reviewer** agent:

> Read `cec_pap419 Reviews Details.pdf`. Cross-reference all comments against the manuscript. Categorize each as actionable, scope (skip), or positive. Produce your structured review report.

2. Present the categorized review report to the user.

**Step 2 — Edit Phase:**
3. Delegate to the **editor** agent with mode "review":

> Work through the Circuit B review steps (B1–B15) in order, informed by the reviewer's report. For each step, propose the exact change, show before/after, and wait for user confirmation before applying.

4. After each confirmed edit, run the **humanizer** skill on the changed text.

---

### Mode: `humanize`
**Trigger:** `/editor humanize` or `/editor humanize [section]`

Runs Circuit C — Check text for AI-sounding language.

**Action:**
1. If a section is specified, read that section file.
2. If no section specified, read all manuscript files.
3. Run the **humanizer** skill on the text:

> Check the following text for AI-sounding language patterns. The paper's style is direct, technical, and concise. Flag any patterns and propose minimal rewording that matches the author's voice. Do NOT change the overall style — only fix obvious AI tells.

4. Present findings to the user. For each flagged passage, show before/after.
5. Apply changes only after user confirmation.

---

### Mode: `full`
**Trigger:** `/editor full`

Runs all three circuits in sequence: A (reduce) → B (review) → C (humanize).

**Step 1 — Review Phase:**
1. Delegate to the **reviewer** agent to produce the structured report.
2. Present the report as an intermediate summary.

**Step 2 — Reduce Phase:**
3. Delegate to the **editor** agent with mode "reduce".
4. Work through A1–A9 with user confirmation for each.

**Step 3 — Review Fix Phase:**
5. Delegate to the **editor** agent with mode "review".
6. Work through B1–B15 with user confirmation for each.

**Step 4 — Humanize Phase:**
7. Run the **humanizer** on the full revised text.
8. Propose any remaining fixes for user confirmation.

**Step 5 — Final Report:**
Present a summary:
```
## REVISION SUMMARY

### Space Savings
- [list of applied reductions with estimated savings]
- Total estimated reduction: [X] pages

### Reviewer Issues Addressed
- [list of applied fixes]

### Humanize Changes
- [list of style fixes applied]

### Remaining Items (Requires Author Action)
- [anything that couldn't be fixed automatically]

### Next Steps
1. Compile LaTeX and verify page count
2. Check all figure/table references
3. Verify new citations compile
```

---

### Mode: `fix`
**Trigger:** `/editor fix <description>`

Fixes a specific issue.

**Action:**
1. Delegate to the **editor** agent:

> Fix the following issue: [description from user]. Read the relevant file, propose the exact change with before/after, and wait for user confirmation before applying.

2. After the edit, run the **humanizer** on the changed text.

---

### Mode: empty or unrecognized
**Trigger:** `/editor` with no arguments

Display this help:

```
/editor — Paper Revision Orchestrator

Usage:
  /editor reduce              Circuit A: reduce paper from 7 to 5 pages
  /editor review              Circuit B: address reviewer comments
  /editor humanize            Circuit C: check for AI-sounding language
  /editor humanize [section]  Humanize a specific section
  /editor full                Run all circuits: reduce → review → humanize
  /editor fix <issue>         Fix a specific issue

Circuits:
  A (reduce)   — 9 steps: remove redundancies, condense sections, compact tables
  B (review)   — 15 steps: fix errors, add citations, improve presentation
  C (humanize) — Check all text for AI patterns, propose natural alternatives

All changes are proposed one at a time. You confirm or deny each before it's applied.
```
