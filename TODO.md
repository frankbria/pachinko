# Pachinko Game - TODO List

## Known Issues (Polish Phase)

### Launch Transition Discontinuity
**Priority**: P3 (Polish)  
**Location**: `lib/models/ball_launcher.dart:134` (_calculateReleaseVelocity)

**Issue**: Ball experiences visible "snap" when transitioning from guided launch path to physics simulation. Two distinct motion phases are noticeable:
1. Smooth guided motion along launch channel curve
2. Abrupt transition to ballistic physics at release point

**Root Cause**: The release velocity is calculated independently without considering the ball's motion along the guided path. Should calculate velocity tangent to the final path segment.

**Fix Approach**:
```dart
// Calculate velocity based on path direction at release point
final pathDirection = (_launchPath[_launchPath.length - 1] - _launchPath[_launchPath.length - 2]).normalized();
final releaseSpeed = 200.0 + (_launchPower / _maxPower) * 300.0;
final releaseVelocity = pathDirection * releaseSpeed;
```

**Impact**: Low - game is playable, but polish would improve perceived quality
**Effort**: 30 minutes - modify _calculateReleaseVelocity() and test

---

## Future Enhancements

### Phase 6: UI Polish (T058-T067)
- FadeTransition widget
- Score animations
- UI transitions
- Power meter rendering enhancements
- Level transition animations
- Anti-aliasing for all UI text

### Phase 7: Performance Optimization (T068-T072)
- Particle quality adjustment
- Performance monitoring hooks
- Degradation/recovery testing
- Memory stability validation

### Phase 8: Documentation (T073-T082)
- Particle count debug display
- Batch rendering optimization
- Performance overlay toggle
- Code cleanup
- Documentation updates
- Final testing (Linux + Android)
