<!--
  Sync Impact Report:
  Version: 1.0.0 (Initial ratification)
  Changes: Initial constitution creation based on CLAUDE.md quality standards
  Modified Principles: N/A (initial version)
  Added Sections: All core sections
  Removed Sections: N/A
  Templates Requiring Updates:
    ✅ spec-template.md - Aligned with user story testing requirements
    ✅ plan-template.md - Aligned with constitution check gates
    ✅ tasks-template.md - Aligned with testing and dependency principles
  Follow-up TODOs: None
-->

# Pachinko Game Constitution

## Core Principles

### I. Test-First Development (NON-NEGOTIABLE)

All features MUST achieve 85% minimum code coverage with 100% test pass rate before being considered complete. Tests MUST be written before implementation (Red-Green-Refactor). Test types required:

- **Unit tests**: All business logic and services
- **Widget tests**: All UI components
- **Integration tests**: Complete game flows and user journeys

**Rationale**: High test coverage prevents regressions and ensures code quality. Writing tests first ensures they validate actual behavior rather than retrofitting to achieve coverage metrics.

### II. Complete Implementation (NON-NEGOTIABLE)

Features MUST be implemented to working state with NO partial implementations. Specifically:

- MUST NOT use TODO comments for core functionality
- MUST NOT create mock/stub/placeholder implementations
- MUST NOT leave incomplete functions that throw "not implemented" errors
- MUST implement real, production-ready code for all generated functions

**Rationale**: Partial implementations create technical debt and make it unclear what is actually functional. "Start it = Finish it" ensures deliverable quality.

### III. Scope Discipline

Build ONLY what is explicitly requested. MUST NOT add features beyond requirements. Follow MVP-first approach:

- Start with minimum viable solution
- No speculative features (YAGNI principle)
- No enterprise patterns unless explicitly needed
- Single responsibility per component

**Rationale**: Feature creep degrades quality and delays delivery. Simple, focused solutions are easier to maintain and evolve based on real feedback.

### IV. Code Quality & Standards

Code MUST meet quality standards before marking tasks complete:

- Follow framework conventions (Flutter/Dart standards)
- Consistent naming (camelCase for Dart, descriptive names)
- Pass linting: `flutter analyze` with zero errors
- Pass formatting: `flutter format` compliance
- Code review for complex changes
- Professional language in docs (no marketing superlatives)

**Rationale**: Consistent quality standards ensure maintainability and reduce cognitive load when navigating the codebase.

### V. Git Workflow Discipline (NON-NEGOTIABLE)

ALL development MUST follow feature branch workflow with complete documentation:

- **Feature branches**: Work on branches named `###-feature-name`, NEVER on main/master
- **Conventional commits**: Format `feat(scope):`, `fix(scope):`, `test(scope):` etc.
- **Commit frequency**: Incremental commits with descriptive messages
- **Push regularly**: Maintain backup and enable collaboration
- **Documentation sync**: Update implementation docs (CLAUDE.md) when features change

**Rationale**: Feature branches enable safe experimentation and easy rollback. Conventional commits create clear history. Documentation sync prevents knowledge decay.

### VI. Graphics & Performance Standards

Graphics implementations MUST meet performance and quality requirements:

- **Frame rate**: Maintain 60 FPS during gameplay
- **Resolution independence**: Support multiple screen sizes and densities
- **Memory efficiency**: Monitor and optimize Canvas memory usage
- **Visual quality**: Anti-aliased rendering, smooth animations
- **Accessibility**: Minimum touch target sizes (48x48dp), color contrast ratios

**Rationale**: Mobile games require consistent performance across devices. Poor graphics performance degrades user experience and limits device compatibility.

### VII. User-Centric Testing

Features MUST be validated from user perspective with acceptance scenarios:

- **User stories**: Prioritized (P1, P2, P3) independent slices
- **Acceptance criteria**: Given-When-Then scenarios for each story
- **Independent testability**: Each story deliverable and testable on its own
- **Manual validation**: Test on target platforms (Linux desktop, Android)
- **Browser testing**: Use Playwright for automated user flow validation

**Rationale**: User-centric testing ensures features deliver actual value. Independent stories enable incremental delivery and easier troubleshooting.

## Development Workflow

### Quality Gates

Before marking ANY feature complete, MUST verify:

- [ ] All tests pass (`flutter test`)
- [ ] Code coverage ≥85% (`flutter test --coverage`)
- [ ] Coverage report reviewed for test quality
- [ ] Code formatted (`flutter format .`)
- [ ] Code analyzed (`flutter analyze`)
- [ ] Changes committed with conventional commit messages
- [ ] Commits pushed to remote repository
- [ ] Implementation documentation updated (CLAUDE.md)
- [ ] Inline code comments current
- [ ] Breaking changes documented
- [ ] Manual testing on target platforms

### Session Lifecycle

- **Initialize**: `git checkout -b ###-feature-name` on feature start
- **Checkpoint**: Commit and push after each task or 30-minute intervals
- **Complete**: Run full quality gate checklist before merge

### Failure Investigation

When failures occur:

- **Root cause analysis**: Investigate WHY, not just THAT it failed
- **Never skip tests**: Never disable, comment out, or bypass tests
- **Never skip validation**: Never bypass quality checks to force success
- **Fix properly**: Address underlying issues, not symptoms
- **Systematic debugging**: Understand → Diagnose → Fix → Verify

## Platform & Technology Standards

### Technology Stack

- **Framework**: Flutter 3.24.5+
- **Language**: Dart 3.5.4+
- **Physics**: Custom engine (60 FPS target)
- **State Management**: Provider pattern
- **Storage**: Shared Preferences
- **Testing**: Flutter test framework, Playwright for E2E

### Performance Targets

- **Frame rate**: 60 FPS minimum during active gameplay
- **Ball physics**: Real-time collision detection with 35px minimum peg spacing
- **Launch responsiveness**: <50ms from touch to visual feedback
- **Memory**: Efficient Canvas rendering without memory leaks

### Platform Support

Primary: Linux desktop (development), Android (production)
Secondary: Web, Windows, macOS, iOS (supported but not primary focus)

## Governance

### Constitution Authority

This constitution is **non-negotiable** and supersedes all other practices. Violations detected during `/speckit.analyze` are automatically CRITICAL and require:

1. Adjustment of spec, plan, or tasks to comply
2. OR explicit constitution amendment via `/speckit.constitution`
3. NOT silent ignoring or rationalization of principle violations

### Amendment Process

Constitution changes require:

1. Explicit `/speckit.constitution` invocation
2. Documentation of rationale for change
3. Version increment per semantic versioning:
   - **MAJOR**: Backward incompatible principle removal/redefinition
   - **MINOR**: New principle or materially expanded guidance
   - **PATCH**: Clarifications, wording, typo fixes
4. Propagation of changes to all dependent templates

### Compliance Review

- All PRs/reviews MUST verify constitution compliance
- Complexity introduced MUST be justified with simpler alternatives documented
- Quality gates are enforced via pre-commit hooks and CI/CD pipelines
- CLAUDE.md serves as runtime development guidance reference

**Version**: 1.0.0 | **Ratified**: 2025-10-18 | **Last Amended**: 2025-10-18
