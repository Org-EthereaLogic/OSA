# CoreSimulator Restart Blocker And Launch Validation Enhanced Prompt

**Date:** 2026-03-25
**Prompt Level:** Level 2
**Prompt Type:** Blocker
**Complexity:** Low
**Complexity Justification:** The change does not expand implementation scope, but it does preserve an execution-critical environment blocker that must be resolved before any build, test, or cold-launch validation can confirm the seed-content packaging fix.

## Inputs Consulted

- Source prompt: `/Enhance-Prompt-workflow`
- User blocker note: `The CoreSimulator service needs a restart before any build or test can succeed.`
- User-provided remediation: `sudo launchctl kickstart -k system/com.apple.CoreSimulator.CoreSimulatorService` or reboot the machine
- Prior related enhanced prompt: `docs/prompt/enhanced/23-app-bundle-seed-content-packaging-and-full-launch-validation-enhanced-prompt.md`
- Prompt workflow conventions: `docs/prompt/README.md`, `docs/prompt/enhanced/README.md`

## Mission Statement

Preserve the immediate CoreSimulator environment blocker as a prompt artifact so the next execution attempt starts by restoring simulator service health, then resumes build, test, and cold-launch validation of the seed-content packaging fix with accurate expectations.

## Technical Context

The current workstream already identified the right product-level next step: fix app-bundle seed-content packaging and validate a cold launch with bundled content. That validation now has a known environment prerequisite. If CoreSimulator is unhealthy, build and test outcomes are not reliable signals about the packaging fix or about the app's actual launch behavior.

This blocker should be resolved before interpreting any simulator build, test, or launch failure as an app defect. Once the CoreSimulator service is restarted, the expected next action is to rerun the packaging-validation path and confirm whether the app cold-launches successfully with the bundled seed content available.

## Problem-State Table

| Current State | Target State |
| --- | --- |
| CoreSimulator service is unhealthy, preventing reliable build or test execution. | CoreSimulator service is restarted or the machine is rebooted so simulator-backed validation can run normally. |
| Build and test failures are currently environment-blocked rather than product-verifying. | Build, test, and launch results can be interpreted as real evidence about the app and packaging fix. |
| The seed-content packaging fix cannot yet be validated end-to-end. | Cold-launch validation resumes after the simulator service is healthy. |

## Pre-Flight Checks

1. Confirm that the blocker is the simulator service rather than an app-code compile failure.
   *Success signal: the next executor treats CoreSimulator health as the first gating issue before debugging app behavior.*

2. Restore simulator availability using one of the known remediations.
   *Success signal: CoreSimulator-backed commands can run again without the prior service failure.*

3. Resume the packaging-validation path only after the environment issue is cleared.
   *Success signal: post-restart build, test, and launch results can be trusted as app-level evidence.*

## Execution Instructions

### Phase 1: Restore CoreSimulator Health

1. Restart the CoreSimulator service using the known system command if permissions and environment allow it.
   *Success signal: simulator processes recover without requiring app-code changes.*

2. If service restart is not available or does not recover the environment, reboot the machine.
   *Success signal: the simulator subsystem starts from a clean system state.*

3. Do not misclassify this as an app-code regression until the simulator environment is healthy.
   *Success signal: build and test interpretation stays disciplined and factual.*

### Phase 2: Resume Packaging Validation

1. Return to the seed-content packaging workflow after the simulator service is restored.
   *Success signal: the `project.yml` packaging fix and generated project can be validated with a clean simulator environment.*

2. Re-run the intended build, test, and cold-launch path.
   *Success signal: the app is evaluated on its actual behavior instead of an environment-side simulator outage.*

3. Confirm whether bundled seed content is available at cold launch.
   *Success signal: the app launches with local content ready, or the remaining failure is captured precisely as an app-level issue.*

### Phase 3: Interpret Results Conservatively

1. Separate environment recovery facts from app-validation facts.
   *Success signal: reports clearly distinguish `simulator service restored` from `packaging fix validated`.*

2. Use the restored environment to re-check the top-level screens if launch succeeds.
   *Success signal: Home, Library, Ask, Inventory, Checklists, Quick Cards, Notes, and Settings can be assessed based on actual runtime behavior.*

3. Keep M4 sequencing downstream of successful offline validation.
   *Success signal: online-enrichment work does not jump ahead of the now-unblocked launch baseline check.*

## Guardrails

- Do not treat a simulator-service outage as proof of an app defect.
- Do not claim the seed-content packaging fix is validated until build or launch is rerun after the environment is restored.
- Do not start Milestone 4 implementation as a way to bypass this blocked validation step.
- Do not save the artifact under `docs/prompts/`; this repository uses `docs/prompt/enhanced/` as the canonical path.

## Verification Checklist

- [ ] CoreSimulator blocker is recorded as an environment issue, not an app-code conclusion.
- [ ] Service restart or reboot is identified as the prerequisite recovery step.
- [ ] Post-recovery build, test, and cold-launch validation are resumed.
- [ ] Seed-content packaging validation remains the next app-level check after environment recovery.
- [ ] Top-level screen validation is deferred until simulator health is restored.

## Error Handling Table

| Error | Resolution |
| --- | --- |
| CoreSimulator restart command cannot be run in the current session | Record the permission or environment limitation and use reboot as the fallback recovery path. |
| Simulator remains unhealthy after restart | Reboot the machine, then retry the validation flow before debugging the app. |
| Build still fails after simulator recovery | Reclassify the failure as a real build issue and investigate the concrete compiler or project error. |
| Launch still fails after simulator recovery | Investigate the app or packaging path directly and report the exact runtime failure. |

## Out Of Scope

- Editing app code unrelated to the seed-content packaging or launch-validation path.
- Reordering the M4 dependency board.
- Claiming successful validation before the simulator environment is restored and the app is rerun.

## Report Format

When this prompt is executed, report back in this structure:

1. Whether the CoreSimulator service was restarted or the machine was rebooted.
2. Whether simulator-backed build and test commands became available again.
3. Which packaging-validation commands were rerun after recovery.
4. Whether the app cold-launched successfully with bundled seed content.
5. Any remaining app-level blockers after the environment issue was removed.
