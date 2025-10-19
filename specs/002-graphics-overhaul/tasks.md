# Tasks: Graphics Architecture Overhaul

**Input**: Design documents from `/specs/002-graphics-overhaul/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/

**Tests**: Per constitution Principle I (Test-First Development), this feature follows TDD approach with comprehensive test coverage (85% minimum).

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`
- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3, US4)
- Include exact file paths in descriptions

## Path Conventions
- Single Flutter application: `lib/` for source, `test/` for tests at repository root
- Graphics subsystem: `lib/services/graphics/` for new graphics components
- Effects widgets: `lib/widgets/effects/` for reusable effect components

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and basic structure for graphics subsystem

- [ ] T001 Create graphics service directory at lib/services/graphics/
- [ ] T002 Create effects widget directory at lib/widgets/effects/
- [ ] T003 Create graphics test directories at test/unit/, test/widget/effects/, test/integration/
- [ ] T004 [P] Create graphics configuration file at lib/utils/graphics_config.dart with constants for particle limits, FPS targets, and quality thresholds
- [ ] T005 [P] Add golden test baseline directory at test/golden/ for visual regression reference images

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before ANY user story can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [ ] T006 Create Particle model at lib/models/particle.dart with position, velocity, color, lifetime, age, size, opacity, isActive properties
- [ ] T007 [P] Create ParticlePool class at lib/services/graphics/particle_system.dart (pool management only, no spawning logic yet)
- [ ] T008 [P] Create RenderingLayer utility at lib/services/graphics/rendering_layer.dart with anti-aliasing Paint configuration
- [ ] T009 [P] Create AnimationState model at lib/services/graphics/animation_controller.dart (state tracking only)
- [ ] T010 [P] Create PerformanceMetrics model at lib/services/graphics/performance_monitor.dart (metrics tracking only)
- [ ] T011 Integrate ParticleSystem stub into GameManager at lib/services/game_manager.dart (dependency injection setup)
- [ ] T012 Update constants.dart with graphics-specific constants (maxTrailParticles=100, maxCollisionParticles=50, targetFPS=60)

**Checkpoint**: Foundation ready - user story implementation can now begin in parallel

---

## Phase 3: User Story 1 - Smooth Visual Feedback During Gameplay (Priority: P1) 🎯 MVP

**Goal**: Deliver smooth 60 FPS animations with particle trails and collision effects

**Independent Test**: Launch balls and observe visual quality - 60 FPS, anti-aliased graphics, particle trails, collision bursts

### Tests for User Story 1 (TDD - Write FIRST, ensure FAIL before implementation)

- [ ] T013 [P] [US1] Unit test for Particle lifecycle at test/unit/particle_test.dart - verify activation, aging, deactivation
- [ ] T014 [P] [US1] Unit test for ParticlePool at test/unit/particle_pool_test.dart - verify pool capacity, reuse, performance
- [ ] T015 [P] [US1] Unit test for RenderingLayer at test/unit/rendering_layer_test.dart - verify anti-aliasing configuration
- [ ] T016 [P] [US1] Integration test for frame rate at test/integration/frame_rate_test.dart - verify 60 FPS with particle effects
- [ ] T017 [P] [US1] Integration test for particle trail rendering at test/integration/visual_regression_test.dart - golden file comparison

### Implementation for User Story 1

- [ ] T018 [US1] Implement Particle.update() method in lib/models/particle.dart - age particle, update position, handle lifetime expiration
- [ ] T019 [US1] Implement ParticlePool.spawn() in lib/services/graphics/particle_system.dart - activate particles with position/velocity/color
- [ ] T020 [US1] Implement ParticlePool.update() in lib/services/graphics/particle_system.dart - age all active particles, deactivate expired
- [ ] T021 [US1] Implement ParticleSystem.spawnTrailParticle() in lib/services/graphics/particle_system.dart - spawn trail from ball data
- [ ] T022 [US1] Implement ParticleSystem.spawnCollisionBurst() in lib/services/graphics/particle_system.dart - spawn radial burst at collision point
- [ ] T023 [US1] Implement RenderingLayer.renderParticles() in lib/services/graphics/rendering_layer.dart - batch draw particles with opacity
- [ ] T024 [US1] Integrate particle spawning into GameManager at lib/services/game_manager.dart - call spawnTrailParticle on ball movement
- [ ] T025 [US1] Integrate collision detection at lib/services/physics_engine.dart - trigger spawnCollisionBurst on peg collisions
- [ ] T026 [US1] Update PachinkoBoard painter in lib/widgets/pachinko_board.dart - call renderParticles in CustomPainter.paint()
- [ ] T027 [US1] Add particle system update to game loop in lib/services/game_manager.dart - call particleSystem.update(deltaTime) at 60 FPS
- [ ] T028 [US1] Verify anti-aliasing applied to all game elements in lib/widgets/pachinko_board.dart - ensure Paint.isAntiAlias = true
- [ ] T029 [US1] Run frame rate integration tests and verify 60 FPS target met with full particle load

**Checkpoint**: At this point, User Story 1 should be fully functional and testable independently

---

## Phase 4: User Story 4 - Comprehensive Visual Testing Framework (Priority: P1)

**Goal**: Automated visual regression testing and performance validation

**Independent Test**: Run test suite and verify it catches visual regressions, performance issues, animation glitches

### Tests for User Story 4 (Test infrastructure itself - meta-testing)

- [ ] T030 [P] [US4] Create visual regression baseline at test/integration/visual_regression_test.dart - capture golden files for particle trails, collisions, UI
- [ ] T031 [P] [US4] Create frame rate validation test at test/integration/frame_rate_test.dart - use binding.renderDuration to verify <16.67ms frames
- [ ] T032 [P] [US4] Create animation timing test at test/integration/animation_timing_test.dart - verify smooth animation curves without stuttering

### Implementation for User Story 4

- [ ] T033 [US4] Implement PerformanceMonitor.recordFrame() in lib/services/graphics/performance_monitor.dart - track frame times in circular buffer
- [ ] T034 [US4] Implement PerformanceMonitor.getCurrentFPS() in lib/services/graphics/performance_monitor.dart - calculate FPS from moving average
- [ ] T035 [US4] Implement PerformanceMonitor.getRecommendedQuality() in lib/services/graphics/performance_monitor.dart - recommend quality based on FPS thresholds
- [ ] T036 [US4] Integrate PerformanceMonitor into GameManager at lib/services/game_manager.dart - record frame time after each render
- [ ] T037 [US4] Create widget test for PachinkoBoard at test/widget/pachinko_board_test.dart - verify rendering without errors
- [ ] T038 [US4] Add golden file update script at scripts/update_goldens.sh - script to regenerate visual regression baselines
- [ ] T039 [US4] Create test coverage report generation at scripts/generate_coverage.sh - flutter test --coverage with HTML output
- [ ] T040 [US4] Verify all visual regression tests pass with current implementation
- [ ] T041 [US4] Run full test suite and confirm 85% coverage target met

**Checkpoint**: All user stories should now be independently functional with comprehensive test coverage

---

## Phase 5: User Story 2 - Enhanced Peg Interaction Visuals (Priority: P2)

**Goal**: Smooth glow animations for special pegs with enhanced collision effects

**Independent Test**: View level with special pegs - see smooth pulsing glow without needing to trigger bonuses

### Tests for User Story 2 (TDD - Write FIRST, ensure FAIL before implementation)

- [ ] T042 [P] [US2] Unit test for AnimationState at test/unit/animation_state_test.dart - verify progress calculation, looping, state transitions
- [ ] T043 [P] [US2] Unit test for AnimationController at test/unit/animation_controller_test.dart - verify multi-animation coordination
- [ ] T044 [P] [US2] Widget test for GlowEffect at test/widget/effects/glow_effect_test.dart - verify glow rendering with correct opacity
- [ ] T045 [P] [US2] Integration test for special peg animations at test/integration/visual_regression_test.dart - golden file for pulsing glow

### Implementation for User Story 2

- [ ] T046 [US2] Implement AnimationState.update() in lib/services/graphics/animation_controller.dart - advance progress with easing curves
- [ ] T047 [US2] Implement AnimationController.createAnimation() in lib/services/graphics/animation_controller.dart - register new animation with ID
- [ ] T048 [US2] Implement AnimationController.start() in lib/services/graphics/animation_controller.dart - begin animation progression
- [ ] T049 [US2] Implement AnimationController.getValue() in lib/services/graphics/animation_controller.dart - return current progress for rendering
- [ ] T050 [US2] Implement AnimationController.update() in lib/services/graphics/animation_controller.dart - update all running animations
- [ ] T051 [US2] Create GlowEffect widget at lib/widgets/effects/glow_effect.dart - reusable glow effect component with blur
- [ ] T052 [US2] Implement RenderingLayer.renderGlowEffect() in lib/services/graphics/rendering_layer.dart - draw glow with intensity modulation
- [ ] T053 [US2] Integrate AnimationController into GameManager at lib/services/game_manager.dart - create glow animations for special pegs on level load
- [ ] T054 [US2] Update PachinkoBoard painter in lib/widgets/pachinko_board.dart - render glow effects for special pegs using animation values
- [ ] T055 [US2] Enhance collision particle effects for special pegs in lib/services/graphics/particle_system.dart - different color/count for special pegs
- [ ] T056 [US2] Add screen-wide bonus effect trigger in lib/services/game_manager.dart - flash/glow when all special pegs hit
- [ ] T057 [US2] Verify glow animations are smooth and consistent across levels

**Checkpoint**: At this point, User Stories 1, 2, and 4 should both work independently

---

## Phase 6: User Story 3 - Polished UI Elements and Overlays (Priority: P3)

**Goal**: Smooth transitions and animations for UI elements (score, level, power meter)

**Independent Test**: View game interface and interact with UI - see smooth transitions without needing gameplay

### Tests for User Story 3 (TDD - Write FIRST, ensure FAIL before implementation)

- [ ] T058 [P] [US3] Widget test for FadeTransition at test/widget/effects/fade_transition_test.dart - verify fade animation timing
- [ ] T059 [P] [US3] Widget test for score animation at test/widget/game_screen_test.dart - verify score updates animate smoothly
- [ ] T060 [P] [US3] Integration test for UI transitions at test/integration/visual_regression_test.dart - golden file for level transitions

### Implementation for User Story 3

- [ ] T061 [US3] Create FadeTransition widget at lib/widgets/effects/fade_transition.dart - reusable fade effect with configurable duration
- [ ] T062 [US3] Implement score animation in GameState at lib/models/game_state.dart - create animation for score value changes
- [ ] T063 [US3] Update score display in GameScreen at lib/screens/game_screen.dart - use AnimationController for smooth number transitions
- [ ] T064 [US3] Enhance power meter rendering in PachinkoBoard at lib/widgets/pachinko_board.dart - smooth color gradient without banding
- [ ] T065 [US3] Add level transition animations to MenuScreen at lib/screens/menu_screen.dart - fade in/out when changing levels
- [ ] T066 [US3] Apply anti-aliasing to all UI text rendering in lib/screens/ - ensure TextPainter uses anti-aliased paint
- [ ] T067 [US3] Verify all UI animations meet 2ms timing variance requirement

**Checkpoint**: All user stories should now be independently functional

---

## Phase 7: Performance Optimization & Adaptive Quality

**Purpose**: Implement graceful degradation and performance monitoring

- [ ] T068 [P] Implement ParticleSystem.adjustQuality() in lib/services/graphics/particle_system.dart - reduce pool capacities based on quality level
- [ ] T069 [P] Add performance monitoring hooks to GameManager at lib/services/game_manager.dart - check FPS and adjust quality dynamically
- [ ] T070 Test performance degradation scenarios - verify particle count reduces when FPS < 55
- [ ] T071 Test performance recovery - verify particle count increases when FPS stabilizes at 60
- [ ] T072 Verify memory stability during 30-minute continuous play session

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that affect multiple user stories

- [ ] T073 [P] Add particle count debug display at lib/widgets/pachinko_board.dart (if GameConstants.showDebugParticleCount enabled)
- [ ] T074 [P] Optimize batch rendering in RenderingLayer at lib/services/graphics/rendering_layer.dart - group particles by paint properties
- [ ] T075 [P] Add performance overlay toggle in main.dart for FPS monitoring during development
- [ ] T076 Code cleanup - remove unused particle properties, consolidate constants
- [ ] T077 [P] Update CLAUDE.md documentation with graphics system architecture and usage patterns
- [ ] T078 [P] Run flutter analyze and fix any linting issues in lib/services/graphics/, lib/widgets/effects/
- [ ] T079 [P] Run flutter format on all new files and verify style compliance
- [ ] T080 Generate final coverage report and verify ≥85% coverage for graphics subsystem
- [ ] T081 Manual testing on Linux desktop - verify smooth gameplay with particle effects
- [ ] T082 Manual testing on Android emulator - verify performance on mobile platform

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Story 1 (Phase 3)**: Depends on Foundational phase completion - No dependencies on other stories
- **User Story 4 (Phase 4)**: Depends on Foundational phase completion - Can run parallel with US1 or after
- **User Story 2 (Phase 5)**: Depends on Foundational phase completion - Can integrate with US1 components
- **User Story 3 (Phase 6)**: Depends on Foundational phase completion - Can run parallel with other stories
- **Performance (Phase 7)**: Depends on US1 and US4 completion
- **Polish (Phase 8)**: Depends on all desired user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational (Phase 2) - No dependencies on other stories (MVP ready after this)
- **User Story 4 (P1)**: Can start after Foundational (Phase 2) - Independent from US1 but tests US1 functionality
- **User Story 2 (P2)**: Can start after Foundational (Phase 2) - Uses ParticleSystem from US1 but independently testable
- **User Story 3 (P3)**: Can start after Foundational (Phase 2) - Uses AnimationController from US2 but independently testable

### Within Each User Story

- Tests (TDD) MUST be written and FAIL before implementation
- Models before services
- Services before widgets
- Core implementation before integration
- Story complete before moving to next priority

### Parallel Opportunities

- All Setup tasks (T001-T005) marked [P] can run in parallel
- All Foundational tasks (T007-T010, T012) marked [P] can run in parallel within Phase 2
- All test creation tasks within a user story marked [P] can run in parallel
- Once Foundational phase completes, US1 and US4 can start in parallel
- US2 and US3 can run in parallel with each other (after US1 provides ParticleSystem)
- Different user stories can be worked on in parallel by different team members

---

## Parallel Example: User Story 1

```bash
# Launch all tests for User Story 1 together (TDD - write first):
Task T013: "Unit test for Particle lifecycle at test/unit/particle_test.dart"
Task T014: "Unit test for ParticlePool at test/unit/particle_pool_test.dart"
Task T015: "Unit test for RenderingLayer at test/unit/rendering_layer_test.dart"
Task T016: "Integration test for frame rate at test/integration/frame_rate_test.dart"
Task T017: "Integration test for particle trail rendering"

# Verify tests FAIL, then implement models in parallel:
Task T018: "Implement Particle.update() method"
Task T019: "Implement ParticlePool.spawn()"
Task T020: "Implement ParticlePool.update()"

# Then services sequentially as they depend on models
```

---

## Implementation Strategy

### MVP First (User Story 1 + User Story 4 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (CRITICAL - blocks all stories)
3. Complete Phase 3: User Story 1 (Smooth Visual Feedback)
4. Complete Phase 4: User Story 4 (Visual Testing Framework)
5. **STOP and VALIDATE**: Run full test suite, verify 60 FPS, test on target platforms
6. Deploy/demo if ready

**MVP Deliverable**: Fully functional particle effects, smooth animations, automated visual testing (core P1 features)

### Incremental Delivery

1. Complete Setup + Foundational → Foundation ready
2. Add User Story 1 → Test independently → Deploy/Demo (MVP!)
3. Add User Story 4 → Test independently → Deploy/Demo (Automated testing in place)
4. Add User Story 2 → Test independently → Deploy/Demo (Enhanced visuals)
5. Add User Story 3 → Test independently → Deploy/Demo (UI polish)
6. Each story adds value without breaking previous stories

### Parallel Team Strategy

With multiple developers:

1. Team completes Setup + Foundational together
2. Once Foundational is done:
   - Developer A: User Story 1 (P1) - Particle effects
   - Developer B: User Story 4 (P1) - Testing framework
   - (Wait for US1 complete before US2/US3)
3. After US1 complete:
   - Developer C: User Story 2 (P2) - Glow effects
   - Developer D: User Story 3 (P3) - UI polish
4. Stories complete and integrate independently

---

## Task Summary

**Total Tasks**: 82
**By Phase**:
- Phase 1 (Setup): 5 tasks
- Phase 2 (Foundational): 7 tasks
- Phase 3 (US1 - P1): 17 tasks (5 tests + 12 implementation)
- Phase 4 (US4 - P1): 12 tasks (3 tests + 9 implementation)
- Phase 5 (US2 - P2): 16 tasks (4 tests + 12 implementation)
- Phase 6 (US3 - P3): 10 tasks (3 tests + 7 implementation)
- Phase 7 (Performance): 5 tasks
- Phase 8 (Polish): 10 tasks

**By User Story**:
- US1 (Smooth Visual Feedback): 17 tasks
- US4 (Testing Framework): 12 tasks
- US2 (Peg Visuals): 16 tasks
- US3 (UI Polish): 10 tasks

**Parallel Opportunities**: 27 tasks marked [P] can run concurrently when conditions met

**MVP Scope**: Phases 1-4 (41 tasks) deliver both P1 user stories

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- Each user story should be independently completable and testable
- TDD approach: Verify tests fail before implementing
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
- Avoid: vague tasks, same file conflicts, cross-story dependencies that break independence
