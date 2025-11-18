---
phase_ref: "Phase 2.5 - Gameplay Polish & UX Refinement"
status: "active"
priority: "high"
created_date: "2025-11-17"
revised_date: "2025-11-17"
parent_phase: "Phase 2 - Feature Implementation"
blocks: ["Phase 3 - Android Optimization"]
classification: "POLISH PHASE (not corrective)"
---

# Phase 2.5 - Gameplay Polish & UX Refinement (REVISED)

## Phase Reclassification: POLISH PHASE

**Trigger Event:** Manual testing during Task 3.2 revealed 5 partial test results requiring polish (Tests 1, 3, 5, 7, 9).

**CRITICAL UPDATE:** Initial assessment was INCORRECT. Persistence and achievement systems (Tests 11-14) are **fully functional**. Issues are visual/audio polish, not broken implementation.

**Original Concern:** Phase 2 marked complete with non-functional game (DISPROVEN)
**Actual Status:** Phase 2 features functional, but UX needs refinement

---

## Test Results Summary

### ✅ PASSING (10/15 tests):
- **Test 2:** Physics simulation - PASS
- **Test 4:** Score updates - PASS
- **Test 6:** Peg hit sound - PASS
- **Test 7 (Core):** Special peg sound - PASS
- **Test 8:** Slot score sound - PASS
- **Test 10:** High score save (session) - PASS
- **Test 11:** High score persistence (restart) - ✅ PASS (verified)
- **Test 12:** Achievement progress tracking - ✅ PASS (verified)
- **Test 13:** Achievement persistence (restart) - ✅ PASS (verified)
- **Test 14:** Achievement unlock triggers - ✅ PASS (verified)
- **Test 15:** No visual glitches - PASS

### 🔧 PARTIAL (5/15 tests requiring polish):

**Test 1 (Partial) - Ball Launch Trajectory & Motion:**
- ❌ Ball stutters at top of launcher
- ❌ Purple trajectory line visible (debug artifact, should be hidden)
- ❌ Unnatural motion at section transitions (launch → top → field)
- 💡 Enhancement: Add curved boundary at top for natural ball flow

**Test 3 (Partial) - Peg Animations:**
- ❌ Pegs don't return to normal state after hit
- Result: Looks like goal is to hit all pegs (confusing)
- Expected: Pegs fade back to normal after short delay

**Test 5 (Partial) - Launch Sound Timing:**
- ❌ Sound delayed by few milliseconds after launch action
- Expected: Sound perfectly synchronized with visual launch

**Test 7 (Partial) - Bonus Screen Behavior:**
- ❌ Bonus screen stays visible for entire level
- Expected: Auto-dismiss after 2-3 seconds
- 💡 Enhancement: Less sterile bonus text ("BONUS!" instead of technical text)

**Test 9 (Partial) - Visual Bonus Feedback:**
- ❌ No visual indicator for points bonus (text only)
- ❌ No visual indicator for ball bonus (just count changes)
- ❌ Confetti visual effect missing (was present previously?)
- Expected: Eye-catching visual feedback for bonus events

### 💡 ENHANCEMENT REQUESTS (optional improvements):

**Test 2 Enhancement - Field Boundaries:**
- Use left line of ball launcher as right boundary (not launcher's right line)
- Add explicit left boundary aligned with left-most scoring bin
- Current: Uses full screen width (too easy to score on right edge)

**Test 10 Enhancement - High Score Naming:**
- Add player name/initials/game name to high score entries
- Current: Only shows score, level, timestamp

**Test 12 Enhancement - Achievement Notifications:**
- Show toast notification in-game when achievement unlocks
- Current: Achievement unlocks silently, must check screen manually

---

## Phase 2.5 Objectives (REVISED)

**Primary Goal:** Polish visual and audio UX to production quality

**Quality Gate:** All 15 manual tests achieve FULL PASS (no partials)

**Scope Change:** This is a **polish phase**, not a **corrective phase**. Core systems work correctly.

---

## Phase 2.5 Task Breakdown

### Task 2.5.1 - Ball Launch Visual & Physics Polish
**Objective:** Smooth ball launch trajectory and eliminate visual artifacts

**Issues to Fix:**
1. Ball stuttering at top of launcher
2. Purple trajectory line visible (remove or hide in production)
3. Unnatural motion at section transitions

**Enhancements:**
4. Add curved boundary at top of field for natural ball flow
5. Smooth velocity transitions between launch zones

**Success Criteria:**
- No stuttering or jittery motion
- Trajectory line hidden in release builds
- Smooth, continuous motion from launch to field
- Curved top boundary implemented
- 60 FPS maintained

**Estimated Effort:** 3-4 hours

---

### Task 2.5.2 - Peg Animation Reset & Lifecycle
**Objective:** Pegs return to normal state after being hit

**Issue to Fix:**
- Pegs remain highlighted after hit (confusing visual state)

**Implementation:**
- Add timer to peg hit animation (0.5-1 second duration)
- Fade peg back to normal state after timer expires
- Maintain special peg shimmer for non-hit special pegs

**Success Criteria:**
- Pegs fade back to normal after ~0.5-1 second
- Special peg distinction maintained
- No performance impact (60 FPS maintained)
- Clear visual feedback which pegs just hit vs. already hit

**Estimated Effort:** 2-3 hours

---

### Task 2.5.3 - Audio Timing & Bonus Screen Behavior
**Objective:** Fix launch sound delay and bonus screen auto-dismiss

**Issues to Fix:**
1. Launch sound delayed by few milliseconds
2. Bonus screen stays visible for entire level

**Audio Timing Investigation:**
- Profile audio playback latency
- Check if AudioService preloading needed
- Verify audio player ready state before launch
- Consider moving audio trigger earlier in launch sequence

**Bonus Screen Auto-Dismiss:**
- Add 2-3 second timer to bonus screen overlay
- Fade out animation for smooth dismissal
- Update bonus text to be less technical ("BONUS!" vs. "Special Peg Activated")

**Success Criteria:**
- Launch sound perfectly synchronized with visual
- Bonus screen auto-dismisses after 2-3 seconds
- Smooth fade-out animation
- More engaging bonus text

**Estimated Effort:** 2-3 hours

---

### Task 2.5.4 - Visual Bonus Feedback & Confetti Effect
**Objective:** Add eye-catching visual feedback for bonus events

**Missing Visuals:**
1. Points bonus indicator (floating "+500 points!" text)
2. Ball bonus indicator (animated ball count change)
3. Confetti particle effect (was present, now missing?)

**Implementation:**
- Floating text animation for points bonuses
- Animated counter for ball bonuses with highlight effect
- Particle system for confetti (check if accidentally removed)
- Color-coded feedback (gold for points, blue for balls)

**Success Criteria:**
- Floating text appears on points bonus
- Ball counter highlights on ball bonus
- Confetti effect restored and triggers correctly
- Visuals don't impact 60 FPS performance
- Visuals auto-dismiss after 2-3 seconds

**Estimated Effort:** 3-4 hours

---

### Task 2.5.5 - Achievement Toast Notifications
**Objective:** Show in-game toast when achievements unlock

**Feature Request:**
- Achievement unlocks currently silent
- User must manually check achievements screen
- Toast notification provides immediate feedback

**Implementation:**
- Create toast widget for achievement unlocks
- Trigger toast from `onAchievementUnlocked` callback
- Display: achievement icon, name, point value
- Auto-dismiss after 3-4 seconds
- Position: Top center or bottom, non-intrusive
- Animation: Slide in from top, fade out

**Success Criteria:**
- Toast appears immediately on achievement unlock
- Toast shows achievement details clearly
- Toast doesn't obstruct gameplay
- Multiple toasts queue properly (don't overlap)
- Toast dismisses automatically after 3-4 seconds

**Estimated Effort:** 2-3 hours

---

### Task 2.5.6 - Field Boundary Enhancements & Manual Validation
**Objective:** Implement field boundary improvements and validate all fixes

**Field Boundary Enhancements:**
1. Use left line of ball launcher as right field boundary
2. Add explicit left boundary aligned with left-most scoring bin
3. Current: Full screen width makes right-edge scoring too easy

**Manual Validation:**
- Re-test all 15 tests after fixes
- Verify no regressions
- Confirm 60 FPS performance maintained
- User acceptance testing

**Optional Enhancement:**
- Add player name/initials to high scores (Test 10 enhancement)
- Design simple name entry dialog
- Update high score model and UI

**Success Criteria:**
- All 15 tests achieve FULL PASS (no partials)
- Field boundaries make gameplay more balanced
- No performance regressions
- User confirms "game ready for production"

**Estimated Effort:** 2-3 hours

---

## Phase 2.5 Success Criteria

### Functional Quality
- ✅ All 15 manual tests FULL PASS (no partials)
- ✅ No visual artifacts or debug overlays
- ✅ All audio perfectly synchronized
- ✅ All animations smooth and complete
- ✅ 60 FPS performance maintained

### Code Quality
- ✅ All existing tests still passing (440+ tests)
- ✅ Code coverage maintained above 85%
- ✅ No new linter warnings
- ✅ TDD cycle followed for new features

### Process
- ✅ Manual gameplay validation completed
- ✅ User acceptance: "game ready for production"
- ✅ Phase 2.5 lessons learned documented

---

## Agent Assignments

**Agent_Gameplay_Polish:** Tasks 2.5.1 - 2.5.6 (all tasks)
- Specialization: Visual polish, audio timing, animation refinement
- Authority: Full codebase access, all Phase 2 features
- Coordination: Reports to Manager Agent 2

---

## Phase 2.5 → Phase 3 Gate Criteria

**MANDATORY before resuming Phase 3:**

1. **All 15 Manual Tests FULL PASS:** No partial results
2. **User Confirmation:** "Game ready for production" approval
3. **Zero Visual Artifacts:** No debug overlays, trajectory lines hidden
4. **Perfect Audio Sync:** No delays or timing issues
5. **Performance Maintained:** 60 FPS sustained during gameplay

**Phase 3 will resume at Task 3.4** after Phase 2.5 completion.

---

## Lessons Learned

### What We Learned:
1. **Metrics ≠ Quality:** 440 tests + 96.4% coverage ≠ production-ready
2. **Manual testing catches polish issues:** Unit tests validate logic, not UX
3. **Initial diagnosis was wrong:** Persistence worked, polish needed
4. **Phase 2 completion was premature:** Polish should have been part of Phase 2

### Process Improvements:
1. **Add UX review to all phases:** Visual/audio polish mandatory
2. **Manual testing earlier:** Don't wait until Phase 3 to test gameplay
3. **Production-ready definition:** Functional + Polished, not just functional
4. **Debug artifacts:** Hide/remove before phase completion

---

## Expected Timeline

**Duration:** 1-2 days
**Tasks:** 6 tasks (12-20 hours estimated)
**Priority:** High (blocks Phase 3)

**After Phase 2.5:**
- Game production-ready in dev build
- All 15 tests FULL PASS
- Visual/audio polish complete
- Ready for Phase 3 Android optimization

---

## Phase 2.5 Status Tracking

**Phase Status:** 🚧 ACTIVE (started 2025-11-17, revised 2025-11-17)
**Current Task:** Planning complete, ready to issue tasks
**Blockers:** None
**Est. Completion:** 2025-11-18 or 2025-11-19

**Next Actions:**
1. Issue Task 2.5.1 to Agent_Gameplay_Polish
2. Sequential task execution with incremental validation
3. Final manual validation after all tasks complete
