# PVNetwork Agent Continuation Protocol

This repository is the source of truth for continuation. Before changing code or CI, every agent MUST read:

1. `docs/PROJECT_STATE.md`
2. `docs/KNOWN_ISSUES.md`
3. the latest GitHub Actions run for `.github/workflows/android-ci.yml`

## Non-negotiable workflow

- Never ask the user to write or debug code that can be handled in this repository.
- Do not repeat a failed build strategy without new evidence.
- For every failed CI run, record: run ID, job ID, commit SHA, failed step, observed error (or explicitly state when GitHub did not expose the detailed log), root-cause hypothesis, patch, and next check in `docs/KNOWN_ISSUES.md` and update `docs/PROJECT_STATE.md`.
- Continue the loop: inspect -> patch -> push -> CI -> inspect until a real installable APK artifact succeeds.
- A UI-only/shell APK is NOT a final VPN client.
- Final Android gate requires a real VPN tunnel engine and configuration import/connect path. Never relabel a shell/preview APK as final.
- Never embed OV-Panel/3x-ui administrator credentials or private backend secrets in the app.
- Keep signing secrets out of Git. Debug signing may be used for CI installable APKs; release keys belong in GitHub Secrets.
- Preserve third-party license notices and source obligations for reused GPL/open-source components.

## Product direction

PVNetwork is a public + commercial VPN client. Public users can import their own supported configurations; PVNetwork users can later authenticate and receive products/profiles through the PVNetwork gateway API. Commercial catalog names must be decoupled from tunnel protocols. Tunnel engines are registered through a protocol/engine abstraction rather than hard-coded product categories.
