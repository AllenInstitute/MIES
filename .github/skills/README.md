# Mirror of .claude/skills

This directory is a byte-for-byte copy of `../../.claude/skills`.

`.claude/skills` is the authoritative source, read natively by Claude Code /
Claude in Cowork. This copy exists solely because GitHub Copilot's Agent
Skills feature (code review, coding agent, CLI) was observed to fail to find
a skill placed only under `.claude/skills` even though that location is
documented as supported, while a copy under `.github/skills` (GitHub's own
first-party skills location) resolved it.

**Maintenance**: whenever a file under `.claude/skills` is added, edited, or
removed, apply the same change here. There is currently no automation for
this -- keep the two directories in sync by hand (or script it, e.g.
`rsync -a --delete .claude/skills/ .github/skills/`, in a pre-commit hook or
CI check, if drift becomes a recurring problem).
