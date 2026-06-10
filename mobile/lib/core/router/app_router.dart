import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/chat/screens/chat_detail_screen.dart';
import '../../features/chat/screens/chat_list_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/knowledge/screens/doc_detail_screen.dart';
import '../../features/knowledge/screens/knowledge_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/study_plan/screens/plan_detail_screen.dart';
import '../../features/study_plan/screens/plan_list_screen.dart';
import '../../features/study_plan/screens/plan_wizard_screen.dart';
import '../shell/main_shell.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/home',
    redirect: (context, state) {
      final isLoggedIn = authState.isAuthenticated;
      final isLoginRoute = state.matchedLocation == '/login';

      if (!isLoggedIn && !isLoginRoute) return '/login';
      if (isLoggedIn && isLoginRoute) return '/home';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
          GoRoute(path: '/chat', builder: (context, state) => const ChatListScreen()),
          GoRoute(path: '/knowledge', builder: (context, state) => const KnowledgeScreen()),
          GoRoute(path: '/profile', builder: (context, state) => const ProfileScreen()),
        ],
      ),
      GoRoute(
        path: '/chat/:id',
        builder: (context, state) => ChatDetailScreen(
          conversationId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(path: '/plans', builder: (context, state) => const PlanListScreen()),
      GoRoute(path: '/plans/new', builder: (context, state) => const PlanWizardScreen()),
      GoRoute(
        path: '/plans/:id',
        builder: (context, state) => PlanDetailScreen(planId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/documents/:id',
        builder: (context, state) => DocDetailScreen(documentId: state.pathParameters['id']!),
      ),
    ],
  );
});
