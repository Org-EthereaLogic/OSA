# App

App shell and composition-root code.

## Boundaries

- `Bootstrap/` owns app startup and container/bootstrap wiring.
- `Navigation/` owns root tab and navigation-shell types.
- Keep this area thin: it should compose dependencies and routes, not absorb feature logic.
