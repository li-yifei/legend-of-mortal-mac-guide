# Repository instructions for agents

Use `skills/run-legend-of-mortal-on-mac/SKILL.md` for Legend of Mortal runtime work.

## Repository scope

- Maintain the human guides in Simplified Chinese, Traditional Chinese, Japanese, and Korean.
- Maintain the installable Agent Skill and its read-only diagnostics.
- Keep technical claims versioned and evidence-backed.

## Safety

- Keep game binaries, Steam files, Wine engines, DXMT binaries, fonts, Unity corlibs, Mod archives, credentials, save files, screenshots, logs with personal paths, and account identifiers out of the repository.
- Treat real wrappers, prefixes, game directories, and saves as external user data.
- Diagnose with read-only inspection first.
- Require explicit authorization before changing external runtime data or stopping a running game session.
- Preserve exact targets, hashes, and timestamped backups for authorized runtime repairs.

## Documentation changes

When a shared compatibility fact changes, update every affected language guide and the Skill reference that carries the fact. Each compatibility claim should record game version, conditions, result, evidence, and confidence.

Translation-only improvements may update one language file.

## Script changes

Diagnostic scripts remain read-only by default. Validate zsh scripts with `zsh -n` and run them against an explicitly supplied wrapper when a safe local fixture or authorized wrapper is available.

Validate the Skill with the current `quick_validate.py` from Codex skill-creator.
