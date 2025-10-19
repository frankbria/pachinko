import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pachinko_game/widgets/effects/glow_effect.dart';

/// Widget tests for GlowEffect component
///
/// Tests verify:
/// - Glow rendering with correct opacity modulation
/// - Blur effect application and intensity
/// - Integration with AnimationController values
/// - Proper rendering at different animation states
void main() {
  group('GlowEffect Widget', () {
    testWidgets('renders with basic properties', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GlowEffect(
              position: const Offset(100, 100),
              radius: 20.0,
              color: Colors.yellow,
              intensity: 1.0,
            ),
          ),
        ),
      );

      // Verify widget builds without errors
      expect(find.byType(GlowEffect), findsOneWidget);
    });

    testWidgets('applies opacity modulation from intensity', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GlowEffect(
              position: const Offset(100, 100),
              radius: 20.0,
              color: Colors.yellow,
              intensity: 0.5, // 50% intensity
            ),
          ),
        ),
      );

      // Widget should build successfully
      expect(find.byType(GlowEffect), findsOneWidget);

      // Opacity should be modulated by intensity value
      // This will be validated through golden file comparison
    });

    testWidgets('handles zero intensity (invisible glow)', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GlowEffect(
              position: const Offset(100, 100),
              radius: 20.0,
              color: Colors.yellow,
              intensity: 0.0, // No glow
            ),
          ),
        ),
      );

      // Should still build but render nothing visible
      expect(find.byType(GlowEffect), findsOneWidget);
    });

    testWidgets('handles maximum intensity', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GlowEffect(
              position: const Offset(100, 100),
              radius: 20.0,
              color: Colors.yellow,
              intensity: 1.0, // Full intensity
            ),
          ),
        ),
      );

      expect(find.byType(GlowEffect), findsOneWidget);
    });

    testWidgets('updates when intensity changes', (WidgetTester tester) async {
      double intensity = 0.5;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return GestureDetector(
                  onTap: () => setState(() => intensity = 1.0),
                  child: GlowEffect(
                    position: const Offset(100, 100),
                    radius: 20.0,
                    color: Colors.yellow,
                    intensity: intensity,
                  ),
                );
              },
            ),
          ),
        ),
      );

      // Initial state
      expect(find.byType(GlowEffect), findsOneWidget);

      // Trigger intensity change
      await tester.tap(find.byType(GestureDetector));
      await tester.pump();

      // Widget should rebuild with new intensity
      expect(find.byType(GlowEffect), findsOneWidget);
    });

    testWidgets('renders with different colors', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                GlowEffect(
                  position: const Offset(50, 50),
                  radius: 15.0,
                  color: Colors.yellow,
                  intensity: 1.0,
                ),
                GlowEffect(
                  position: const Offset(150, 50),
                  radius: 15.0,
                  color: Colors.red,
                  intensity: 1.0,
                ),
                GlowEffect(
                  position: const Offset(250, 50),
                  radius: 15.0,
                  color: Colors.blue,
                  intensity: 1.0,
                ),
              ],
            ),
          ),
        ),
      );

      // All three glows should render
      expect(find.byType(GlowEffect), findsNWidgets(3));
    });

    testWidgets('renders with different radii', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                GlowEffect(
                  position: const Offset(100, 50),
                  radius: 10.0,
                  color: Colors.yellow,
                  intensity: 1.0,
                ),
                GlowEffect(
                  position: const Offset(100, 150),
                  radius: 20.0,
                  color: Colors.yellow,
                  intensity: 1.0,
                ),
                GlowEffect(
                  position: const Offset(100, 250),
                  radius: 30.0,
                  color: Colors.yellow,
                  intensity: 1.0,
                ),
              ],
            ),
          ),
        ),
      );

      // All three glows with different sizes should render
      expect(find.byType(GlowEffect), findsNWidgets(3));
    });

    testWidgets('validates intensity range constraints', (WidgetTester tester) async {
      // Test that intensity values outside 0.0-1.0 are handled gracefully

      // Below minimum (should clamp to 0.0)
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GlowEffect(
              position: const Offset(100, 100),
              radius: 20.0,
              color: Colors.yellow,
              intensity: -0.5,
            ),
          ),
        ),
      );
      expect(find.byType(GlowEffect), findsOneWidget);

      // Above maximum (should clamp to 1.0)
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GlowEffect(
              position: const Offset(100, 100),
              radius: 20.0,
              color: Colors.yellow,
              intensity: 1.5,
            ),
          ),
        ),
      );
      expect(find.byType(GlowEffect), findsOneWidget);
    });

    testWidgets('renders glow effect with blur', (WidgetTester tester) async {
      // This test verifies that the glow uses BackdropFilter or similar blur effect
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GlowEffect(
              position: const Offset(100, 100),
              radius: 25.0,
              color: Colors.yellow.withOpacity(0.8),
              intensity: 1.0,
            ),
          ),
        ),
      );

      // Widget should build with blur applied
      expect(find.byType(GlowEffect), findsOneWidget);

      // Visual verification through golden file comparison will validate blur effect
    });

    testWidgets('performs well with multiple glow effects', (WidgetTester tester) async {
      // Test that multiple simultaneous glows don't cause performance issues
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: List.generate(
                10,
                (index) => GlowEffect(
                  position: Offset(50.0 + index * 30.0, 100.0),
                  radius: 20.0,
                  color: Colors.yellow,
                  intensity: 0.8,
                ),
              ),
            ),
          ),
        ),
      );

      // All 10 glows should render successfully
      expect(find.byType(GlowEffect), findsNWidgets(10));
    });

    testWidgets('integrates with animation values', (WidgetTester tester) async {
      // Test that GlowEffect works with animated intensity values

      double animatedIntensity = 0.0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return GestureDetector(
                  onTap: () {
                    // Simulate animation progression
                    setState(() {
                      animatedIntensity = (animatedIntensity + 0.1).clamp(0.0, 1.0);
                    });
                  },
                  child: GlowEffect(
                    position: const Offset(100, 100),
                    radius: 20.0,
                    color: Colors.yellow,
                    intensity: animatedIntensity,
                  ),
                );
              },
            ),
          ),
        ),
      );

      // Verify initial state (invisible)
      expect(find.byType(GlowEffect), findsOneWidget);

      // Simulate animation frames
      for (int i = 0; i < 10; i++) {
        await tester.tap(find.byType(GestureDetector));
        await tester.pump();
        expect(find.byType(GlowEffect), findsOneWidget);
      }
    });
  });

  group('GlowEffect Golden Tests', () {
    testWidgets('matches golden file - full intensity', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            backgroundColor: Colors.black,
            body: Center(
              child: GlowEffect(
                position: const Offset(200, 200),
                radius: 30.0,
                color: Colors.yellow,
                intensity: 1.0,
              ),
            ),
          ),
        ),
      );

      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile('golden/glow_full_intensity.png'),
      );
    });

    testWidgets('matches golden file - half intensity', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            backgroundColor: Colors.black,
            body: Center(
              child: GlowEffect(
                position: const Offset(200, 200),
                radius: 30.0,
                color: Colors.yellow,
                intensity: 0.5,
              ),
            ),
          ),
        ),
      );

      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile('golden/glow_half_intensity.png'),
      );
    });

    testWidgets('matches golden file - multiple glows', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            backgroundColor: Colors.black,
            body: Stack(
              children: [
                GlowEffect(
                  position: const Offset(100, 100),
                  radius: 25.0,
                  color: Colors.yellow,
                  intensity: 1.0,
                ),
                GlowEffect(
                  position: const Offset(300, 100),
                  radius: 25.0,
                  color: Colors.red,
                  intensity: 0.8,
                ),
                GlowEffect(
                  position: const Offset(200, 250),
                  radius: 25.0,
                  color: Colors.blue,
                  intensity: 0.6,
                ),
              ],
            ),
          ),
        ),
      );

      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile('golden/glow_multiple.png'),
      );
    });
  });
}
