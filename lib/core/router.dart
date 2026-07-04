import 'package:go_router/go_router.dart';

import '../data/models.dart';
import '../ui/chart_screen.dart';
import '../ui/comparison/chart_comparison_screen.dart';
import '../ui/home_screen.dart';
import '../ui/input_screen.dart';
import '../ui/loading_screen.dart';
import '../ui/panchang_screen.dart';
import '../ui/settings_screen.dart';
import '../ui/tools/ayanamsa_sandbox_screen.dart';
import '../ui/tools/muhurta_finder_screen.dart';
import '../ui/tools/eclipse_calculations_screen.dart';
import '../ui/vedic_clock_screen.dart';

final router = GoRouter(
  initialLocation: '/loading',
  routes: [
    GoRoute(
      path: '/loading',
      builder: (context, state) => const LoadingScreen(),
    ),
    GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
    GoRoute(path: '/input', builder: (context, state) => const InputScreen()),
    GoRoute(
      path: '/chart',
      builder: (context, state) =>
          ChartScreen(birthData: state.extra as BirthData?),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/panchang',
      builder: (context, state) => const PanchangScreen(),
    ),
    GoRoute(
      path: '/comparison',
      builder: (context, state) => const ChartComparisonScreen(),
    ),
    GoRoute(
      path: '/muhurta',
      builder: (context, state) => const MuhurtaFinderScreen(),
    ),
    GoRoute(
      path: '/vedic-clock',
      builder: (context, state) => const VedicClockScreen(),
    ),
    GoRoute(
      path: '/ayanamsa-sandbox',
      builder: (context, state) =>
          AyanamsaSandboxScreen(birthData: state.extra as BirthData?),
    ),
    GoRoute(
      path: '/eclipses',
      builder: (context, state) => const EclipseCalculationsScreen(),
    ),
  ],
);
