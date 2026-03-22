# .claude/agents

Custom subagent definitions loaded by Claude Code. Each `.md` file defines a specialized agent with its own system prompt, tool access, and invocation conditions.

## Files

| File | Agent | Specialization | Model |
|------|-------|----------------|-------|
| `lead-software-engineer.md` | Lead Software Engineer | Production Swift/SwiftUI code, TDD, architecture, debugging, performance | opus |
| `swift-pro.md` | Swift Pro | Swift 6+, SwiftUI, SwiftData, async/await, modern Swift tooling | opus |
| `ai-ml-specialist.md` | AI/ML Specialist | Apple Foundation Models, on-device RAG, retrieval pipelines, grounded AI | opus |
| `test-automator.md` | Test Automator | XCTest, Swift Testing, UI testing, test strategy, coverage | sonnet |
| `technical-writer.md` | Technical Writer | API docs, READMEs, guides, architecture documentation | opus |
| `sdlc-technical-writer.md` | SDLC Technical Writer | SDLC documentation: SRS, architecture, SDDs, test plans, release notes | opus |
| `ux-design-architect.md` | UX Design Architect | SwiftUI layout, iOS HIG, accessibility, design systems, navigation | opus |
| `ux-delight-crafter.md` | UX Delight Crafter | iOS micro-interactions, animations, haptics, SwiftUI transitions | sonnet |
| `refactoring-specialist.md` | Refactoring Specialist | Swift refactoring, complexity reduction, protocol-oriented design | sonnet |
| `cleanup_workspace.md` | Workspace Cleaner | Xcode build artifacts, DerivedData, caches, workspace hygiene | haiku |

## Notes

- Agents are invoked automatically by Claude Code when task context matches their trigger conditions
- Each agent has a persistent memory directory under `.claude/agent-memory/<agent-name>/`
- Memory files persist across conversations
- To add a new agent: create a `.md` file here following the existing format
