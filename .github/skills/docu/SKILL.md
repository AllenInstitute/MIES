---
name: docu
description: Documentation-consistency guidance for MIES. Use for any task involving behavior, UI text, workflows, analysis, or user-facing output; read and align with the repository's .rst documentation (especially Packages/doc/ and SweepFormula docs) before answering, and flag mismatches between code and docs instead of silently picking one.
---

# Copilot Instructions for MIES

## Documentation Source of Truth

For any task involving behavior, UI text, workflows, analysis, or user-facing output in MIES:

1. Read and use all reStructuredText documentation files (`*.rst`) in this repository as authoritative documentation.
2. Prefer documentation under `Packages/doc/` when conflicts arise.
3. If code behavior appears to conflict with `.rst` docs, do not silently choose one:
   - Call out the mismatch clearly.
   - Propose a fix consistent with existing MIES conventions.
4. When generating explanations, comments, commit messages, PR summaries, or user help text:
   - Align terminology with the `.rst` documentation.
   - Reuse established names for features, parameters, and workflows.
5. For SweepFormula work specifically, prioritize the SweepFormula `.rst` documentation and keep parser/function wording consistent.

## File Discovery Guidance

When starting a task, discover and consider all:
- `**/*.rst`

Especially include:
- `Packages/doc/**/*.rst`
- Top-level documentation files (for example `README.rst`, if present)
- Any `.rst` near the code being modified

## Implementation Guidance

- Do not invent behavior that contradicts `.rst` docs.
- If docs are ambiguous, state assumptions explicitly in the response.
- Keep examples and suggested API usage consistent with documented patterns.
- For user-visible strings, prefer wording style used in docs.

## Response Requirements

In your response, briefly list which `.rst` files were used when the task is documentation-sensitive.
If none were found, say that explicitly and proceed with best-effort based on code context.
