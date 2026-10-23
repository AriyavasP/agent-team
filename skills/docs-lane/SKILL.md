---
name: docs-lane
description: Route for documents people outside the pipeline read - SDDs and design docs, technical specs, user manuals and how-to guides, API reference, proposals, statements of work, RFP responses, SOPs, FAQs, reports, release notes, runbooks. Use when the request is to write or rewrite such a document. Runs the writer agent through outline, draft and a fresh-eyes edit, with the human approving the outline and reading the result.
---

# Docs Lane

A document is finished work for a reader, not a pipeline artifact. It is written in that reader's language and the team's voice, and every claim in it comes from a source. This lane gets there in three `writer` calls and two human stops.

## 1. Scope it with the human — one batch, each question with a default

- **Reader** and what they will do with it (default: the person who asked)
- **Purpose and type** — tutorial, how-to, reference, explanation / design doc, proposal, report, release notes
- **Sources** — which features, files, reports or notes it draws on (default: the current feature's `docs/features/<slug>/`)
- **Language and register** (default: `.agent/project.md` → "Voice and style")
- **Format** — Markdown, Word or PDF (default: Markdown; Word / PDF rendered at the end)

Pick a kebab-case `<slug>`. Record `doc: <slug>` and `phase: DOC-OUTLINE` in `.agent/state.md`.

If "Voice and style" or "Reference work" is empty, say so: the writer will model the document on a named public standard, and the result will sound less like the team than it could. Offer `/agent-team:init` to fill them first.

## 2. Outline → the human approves

```
writer — OUTLINE mode:
  OUTLINE mode — document <slug>: <the human's request, in full>
  Reader: <who> — Purpose: <what they will do with it> — Type: <type>
  Sources: <paths>
  Language: <language and register>
  Write docs/deliverables/<slug>/outline.md
```

Stop and set `gate: awaiting-pm`. The outline is the cheap moment to change scope, order or depth.

## 3. Draft, then a fresh-eyes edit — two separate calls

```
writer — DRAFT mode:
  DRAFT mode — document <slug>, approved outline docs/deliverables/<slug>/outline.md
  Sources: <paths>   Write docs/deliverables/<slug>/<name>.md and sources.md

writer — EDIT mode (a new call, so the editor has not seen the drafting):
  EDIT mode — document <slug>: docs/deliverables/<slug>/<name>.md
  You did not write this. Read it as <reader>. One pass.
```

Run them back to back. Never run EDIT twice on your own; a second pass happens only if the human asks.

## 4. Document gate — the human reads it

Show the path, the reference model the writer followed, and the edit log's open items (unsupported claims, gaps). Set `gate: awaiting-pm`. The question for the human is the one no agent can answer: *does this read like our team wrote it?*

On approval: render Word or PDF if asked (use the `docx` / `pdf` skill if this session has one; otherwise say so), commit the document under the project's commit rules, and clear `doc:` from `state.md`.

## Never

- Let the writer draft before the outline is approved
- Ask the writer to translate an English draft into the deliverable's language
- Edit the document yourself between calls — send changes back through EDIT mode, or let the human edit
