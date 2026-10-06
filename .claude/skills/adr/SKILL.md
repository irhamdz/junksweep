---
name: adr
description: Write an Architecture Decision Record (ADR) for JunkSweep from a discussion or brainstorm in the current conversation, and save it to docs/adr/. Use this whenever the user says "write an ADR", "make an ADR from this", "record this decision", "document what we decided", "capture this brainstorm", or "/adr", or when a design discussion in this repo ends with a choice (for example, which detection method, how to store scan results, which UI flow) and the user wants it written down, even if they do not say "ADR". Prefer this over generic architecture skills when the decision came from this conversation.
---

# ADR from a discussion

Turn the decision that the user and Claude discussed in this conversation into one ADR file in `docs/adr/`.

The conversation is the source. The ADR is a record of what was actually said and decided. It is not a new design. A reader in six months must trust that every option, reason, and trade-off in the file came from the discussion or from the code. So do not add options, numbers, or reasons that nobody raised. If something important is missing, ask, or mark it clearly as an open question.

## Steps

### 1. Extract the decision from the conversation

Read back through the discussion and collect:

- **The problem**: what forced a decision. Include constraints that were named (iOS version, on-device only, Photos API limits, performance, design handoff).
- **Options considered**: every option that was discussed, with the pros and cons that were said for each one.
- **The decision**: the option chosen, and the main reason for it.
- **Consequences**: what gets easier, what gets harder, follow-up work, risks.
- **Code touched or affected**: files, types, or thresholds that were named (for example `JunkScanner.swift`, `LibraryStore`). Check that they exist in the repo before you cite them.

If the conversation has more than one decision, ask the user which one to record, or offer one ADR per decision.

### 2. Check the status, and ask only about real gaps

- If the user clearly chose an option, the status is `Accepted`.
- If the discussion ended without a clear choice, do not pick one for the user. Ask which option they choose. If they want to record it before they choose, use status `Proposed` and list the open question.
- Ask at most one short round of questions, only for gaps that change the ADR (no clear decision, unclear which of two decisions). Do not ask about things you can read from the conversation or the code.

### 3. Number and name the file

- List `docs/adr/`. Create the folder if it does not exist.
- The next number is the highest existing `NNNN` plus one. Start at `0001`.
- File name: `docs/adr/NNNN-short-kebab-title.md`. The title says the decision, not the problem. Good: `0003-use-vision-feature-prints-for-similar-photos.md`. Bad: `0003-similar-photos.md`.
- If the new decision replaces an older ADR, set the old ADR's status to `Superseded by [NNNN](NNNN-....md)`, and link back from the new one.

### 4. Write the ADR

Use this template. Write short, simple sentences in active voice, one idea per sentence (the user prefers ASD-STE100 Simplified Technical English). Keep it to about one page. Cut filler.

```markdown
# NNNN. <Decision as a short title>

- Status: Accepted | Proposed | Superseded by [NNNN](NNNN-....md)
- Date: YYYY-MM-DD
- Deciders: <the people who took part in the discussion, for example "Irham, Claude">

## Context

<The problem and the constraints. Why a decision was necessary now.>

## Options considered

### Option 1: <name>

- Pro: ...
- Con: ...

### Option 2: <name>

- Pro: ...
- Con: ...

## Decision

We chose **<option>**, because <main reason>.

## Consequences

- Good: ...
- Bad: ...
- Follow-up: <work items, thresholds to tune, tests to add>

## Open questions

<Only if there are any. Remove the section if there are none.>

## References

<Code paths, design files in design/, links or docs that were used in the discussion. Remove if none.>
```

Rules for content:

- Use today's date.
- Mark where each claim comes from. The user's org requires a clear line between verified facts, assumptions, and recommendations. Use these labels:
  - No label: the user said it, or both agreed on it in the discussion.
  - "(from the code)": you checked it in the repo. Add facts from the code only when they change how the decision works or how much it helps. Do not add them to fill space.
  - "(not measured)": a number or claim that someone stated but nobody checked, for example a scan time the user reported.
  - "(assumption)": Claude's guess that nobody confirmed.
- Use "Open questions" only for gaps that could change the decision. Do not repeat every label there.
- If the user deferred an option ("try X later"), keep it in Options considered, and add a Follow-up line that says when to look at it again.
- If a file, type, or threshold named in the discussion does not exist in the repo, do not cite it as code. Say so in Open questions.
- Keep each option fair. Write the real pros of the options that lost, so a future reader can see why they were close.
- Do not put customer or personal data in the ADR.

### 5. Update the index

Keep `docs/adr/README.md` as a simple table. Create it if it does not exist:

```markdown
# Architecture Decision Records

| # | Title | Status | Date |
|---|-------|--------|------|
| [0001](0001-....md) | ... | Accepted | YYYY-MM-DD |
```

Add the new row. Update the status of a superseded ADR.

### 6. Report

Tell the user the file path, the status, and a one-line summary of the decision. List any open questions or assumptions you marked. Do not commit or push unless the user asks. If they ask for GitHub work, use the `irhamdz` account (see the GitHub section of the repo-root `CLAUDE.md`).
