# Features

User-facing SwiftUI surfaces organized by first-class product area.

## Conventions

- Each top-level feature folder owns its route-level screen type.
- Add feature-local components or state helpers inside the feature folder before promoting them to `Shared/`.
- Route-level screens use `*Screen` naming to distinguish them from smaller reusable views.
