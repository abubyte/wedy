import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:wedy/apps/client/pages/chats/chats_page.dart';
import 'package:wedy/apps/merchant/pages/chats/chats_page.dart';
import 'package:wedy/apps/merchant/pages/profile/profile_page.dart';
import 'package:wedy/shared/navigation/navigation_shell.dart';
import 'package:wedy/apps/client/pages/favorites/favorites_page.dart';
import 'package:wedy/apps/client/pages/home/home_page.dart';
import 'package:wedy/apps/client/pages/items/items_page.dart';
import 'package:wedy/apps/client/pages/profile/profile_page.dart';
import 'package:wedy/apps/client/pages/service/service_page.dart';
import 'package:wedy/apps/merchant/pages/home/home_page.dart';
import 'package:wedy/features/auth/presentation/screens/auth_screen.dart';
import 'package:wedy/shared/navigation/route_names.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'rootNavigatorKey');
final _homeNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'homeNavigatorKey');

class AppRouter {
  static GoRouter get clientRouter {
    return GoRouter(
      debugLogDiagnostics: true,
      navigatorKey: _rootNavigatorKey,
      initialLocation: RouteNames.home,
      routes: [
        GoRoute(path: RouteNames.auth, name: RouteNames.auth, builder: (context, state) => const AuthScreen()),
        GoRoute(path: RouteNames.serviceDetails, builder: (context, state) => const ClientServicePage()),
        StatefulShellRoute.indexedStack(
          builder: (BuildContext context, GoRouterState state, StatefulNavigationShell navigationShell) =>
              NavigationShell(child: navigationShell),
          branches: [
            StatefulShellBranch(
              navigatorKey: _homeNavigatorKey,
              routes: [
                GoRoute(
                  path: RouteNames.home,
                  name: RouteNames.home,
                  pageBuilder: (context, state) => buildPageWithDefaultTransition<void>(
                    context: context,
                    state: state,
                    child: const ClientHomePage(),
                  ),
                  routes: [
                    GoRoute(
                      path: RouteNames.items,
                      name: RouteNames.items,
                      builder: (context, state) => const ClientItemsPage(),
                    ),
                    GoRoute(
                      path: RouteNames.hotOffers,
                      name: RouteNames.hotOffers,
                      builder: (context, state) => const ClientItemsPage(hotOffers: true),
                    ),
                  ],
                ),
              ],
            ),

            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: RouteNames.chats,
                  name: RouteNames.chats,
                  pageBuilder: (context, state) => buildPageWithDefaultTransition<void>(
                    context: context,
                    state: state,
                    child: const ClientChatsPage(),
                  ),
                ),
              ],
            ),

            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: RouteNames.favorites,
                  name: RouteNames.favorites,
                  pageBuilder: (context, state) => buildPageWithDefaultTransition<void>(
                    context: context,
                    state: state,
                    child: const ClientFavoritesPage(),
                  ),
                ),
              ],
            ),

            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: RouteNames.profile,
                  name: RouteNames.profile,
                  pageBuilder: (context, state) => buildPageWithDefaultTransition<void>(
                    context: context,
                    state: state,
                    child: const ClientProfilePage(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  static GoRouter get merchantRouter {
    return GoRouter(
      debugLogDiagnostics: true,
      navigatorKey: _rootNavigatorKey,
      initialLocation: RouteNames.home,
      routes: [
        GoRoute(path: RouteNames.auth, builder: (context, state) => const AuthScreen()),
        StatefulShellRoute.indexedStack(
          builder: (BuildContext context, GoRouterState state, StatefulNavigationShell navigationShell) =>
              NavigationShell(client: false, child: navigationShell),
          branches: [
            StatefulShellBranch(
              navigatorKey: _homeNavigatorKey,
              routes: [
                GoRoute(
                  path: RouteNames.home,
                  name: RouteNames.home,
                  pageBuilder: (context, state) => buildPageWithDefaultTransition<void>(
                    context: context,
                    state: state,
                    child: const MerchantHomePage(),
                  ),
                ),
              ],
            ),

            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: RouteNames.profile,
                  name: RouteNames.profile,
                  pageBuilder: (context, state) => buildPageWithDefaultTransition<void>(
                    context: context,
                    state: state,
                    child: const MerchantProfilePage(),
                  ),
                ),
              ],
            ),

            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: RouteNames.chats,
                  name: RouteNames.chats,
                  pageBuilder: (context, state) => buildPageWithDefaultTransition<void>(
                    context: context,
                    state: state,
                    child: const MerchantChatsPage(),
                  ),
                ),
              ],
            ),

            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: RouteNames.settings,
                  name: RouteNames.settings,
                  pageBuilder: (context, state) => buildPageWithDefaultTransition<void>(
                    context: context,
                    state: state,
                    child: const MerchantProfilePage(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

CustomTransitionPage buildPageWithDefaultTransition<T>({
  required BuildContext context,
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 300),
    transitionsBuilder: (context, animation, secondaryAnimation, child) =>
        FadeTransition(opacity: animation, child: child),
  );
}
