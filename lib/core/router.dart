import 'package:go_router/go_router.dart';

import '../ui/chart_screen.dart';
import '../ui/comparison/chart_comparison_screen.dart';
import '../ui/home_screen.dart';
import '../ui/input_screen.dart';
import '../ui/loading_screen.dart';
import '../ui/panchang_screen.dart';
import '../ui/settings_screen.dart';
import '../ui/tools/muhurta_finder_screen.dart';

final router = GoRouter(
  initialLocation: '/loading',
  routes: [
    GoRoute(
      path: '/loading',
      builder: (context, state) => const LoadingScreen(),
    ),
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/input',
      builder: (context, state) => const InputScreen(),
    ),
    GoRoute(
      path: '/chart',
      builder: (context, state) => const ChartScreen(),
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
  ],
);
