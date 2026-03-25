# docs/prompt/enhanced

Curated prompts and prompt-derived documents.

## Current Contents

- `sdlc_doc_suite_prompt.md` preserves the source prompt used to generate the SDLC suite.
- `13-task-03-swiftdata-schema-and-repository-protocols-enhanced-prompt.md`, `14-milestone-1-phase-2-persistence-seed-import-and-tests-enhanced-prompt.md`, `15-milestone-1-exit-criteria-handbook-and-quick-card-browsing-ui-enhanced-prompt.md`, `16-milestone-3-grounded-ask-retrieval-pipeline-enhanced-prompt.md`, `17-milestone-3-capability-detection-and-model-adapter-enhanced-prompt.md`, and `18-milestone-3-assistant-policy-prompt-shaping-and-safety-guardrails-enhanced-prompt.md` are implementation-facing enhanced prompts.
- `19-mvp-handbook-and-quick-card-corpus-expansion-enhanced-prompt.md` expands the seeded handbook and quick-card corpus for the broader MVP library.
- `20-m3-polish-sprint-home-settings-ask-navigation-seed-manifest-enhanced-prompt.md` captures the M3 polish sprint focused on live Home data, Settings capability status, Ask scope/navigation, and seed-manifest integrity.
- `21-checklist-swiftdata-runtime-investigation-and-test-recovery-enhanced-prompt.md` captures the investigation and recovery plan for the checklist SwiftData runtime crash plus the remaining safety and UI test regressions.
- `22-checklist-swiftdata-container-lifetime-final-report-enhanced-prompt.md` preserves the verified final report showing that the checklist crash was caused by test-only `ModelContainer` lifetime loss, not a production SwiftData relationship-graph defect.
- `23-app-bundle-seed-content-packaging-and-full-launch-validation-enhanced-prompt.md` captures the immediate packaging fix for bundled seed content, the required cold-launch validation pass, and the preserved M4 dependency sequence that follows once the offline app baseline is stable.

## Rules

- Keep reusable prompt artifacts here after they are cleaned up from draft form.
- Do not assume numbered filenames in this folder are canonical; the directory location controls the role.
- If a document graduates into the living SDLC suite, move it to `../../sdlc/` and update links accordingly.

## Notes

- `sdlc_doc_suite_prompt.md` is preserved input material and may reference the original flat `docs/` layout.
- Keep new prompt files aligned with the current `docs/sdlc/` and `docs/adr/` structure.
