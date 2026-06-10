import 'package:go_router/go_router.dart';
import 'package:ocean_lens_ar/features/splash/splash_screen.dart';
import 'package:ocean_lens_ar/features/home/home_screen.dart';
import 'package:ocean_lens_ar/features/museum/museum_screen.dart';
import 'package:ocean_lens_ar/features/museum/fish_detail_screen.dart';
import 'package:ocean_lens_ar/features/ar_viewer/ar_fish_view.dart';
import 'package:ocean_lens_ar/features/game/game_screen.dart';
import 'package:ocean_lens_ar/features/quiz/quiz_screen.dart';
import 'package:ocean_lens_ar/features/aquarium/aquarium_screen.dart';
import 'package:ocean_lens_ar/features/museum/models/fish_model.dart';

class AppRoutes {
  static const String splash = '/';
  static const String home = '/home';
  static const String museum = '/museum';
  static const String fishDetail = '/museum/detail';
  static const String arViewer = '/ar';
  static const String game = '/game';
  static const String quiz = '/quiz';
  static const String aquarium = '/aquarium';
}

final appRouter = GoRouter(
  initialLocation: AppRoutes.splash,
  routes: [
    GoRoute(
      path: AppRoutes.splash,
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: AppRoutes.home,
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: AppRoutes.museum,
      builder: (context, state) => const MuseumScreen(),
    ),
    GoRoute(
      path: AppRoutes.fishDetail,
      builder: (context, state) {
        final fish = state.extra as FishModel;
        return FishDetailScreen(fish: fish);
      },
    ),
    GoRoute(
      path: AppRoutes.arViewer,
      builder: (context, state) {
        final fish = state.extra as FishModel;
        return ArFishView(fish: fish);
      },
    ),
    GoRoute(
      path: AppRoutes.game,
      builder: (context, state) => const GameScreen(),
    ),
    GoRoute(
      path: AppRoutes.quiz,
      builder: (context, state) => const QuizScreen(),
    ),
    GoRoute(
      path: AppRoutes.aquarium,
      builder: (context, state) => const AquariumScreen(),
    ),
  ],
);
