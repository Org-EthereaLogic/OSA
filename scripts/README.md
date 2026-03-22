# scripts

Repository helper scripts for project generation, validation, maintenance, and future content tooling.

## Intended Uses

- project generation and structure verification
- local build or test wrappers when the command set stabilizes
- seed-content validation and linting once the content format is implemented
- maintenance tasks that should not live ad hoc at the repository root

## Notes

- Keep scripts small, explicit, and safe to run locally.
- Prefer wrappers around canonical commands rather than inventing alternate behavior.
