import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:wedy/apps/client/pages/chats/chats_page.dart';
import 'package:wedy/apps/merchant/pages/boost/boost_page.dart';
import 'package:wedy/apps/merchant/pages/chats/chats_page.dart';
import 'package:wedy/apps/merchant/pages/edit/edit_page.dart';
import 'package:wedy/apps/merchant/pages/settings/settings_page.dart';
import 'package:wedy/features/reviews/presentation/screens/reviews_page.dart';
import 'package:wedy/shared/navigation/navigation_shell.dart';
import 'package:wedy/apps/client/pages/favorites/favorites_page.dart';
import 'package:wedy/apps/client/pages/home/home_page.dart';
import 'package:wedy/apps/client/pages/items/items_page.dart';
import 'package:wedy/apps/client/pages/profile/profile_page.dart';
import 'package:wedy/features/service/presentation/screens/service/service_page.dart';
import 'package:wedy/apps/merchant/pages/home/home_page.dart';
import 'package:wedy/features/auth/presentation/screens/auth_screen.dart';
import 'package:wedy/shared/navigation/route_names.dart';
import '../../core/di/injection_container.dart';
import '../../features/auth/data/datasources/auth_local_datasource.dart';

// Client router keys
final _clientRootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'clientRootNavigatorKey');
final _clientHomeNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'clientHomeNavigatorKey');
final _clientChatsNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'clientChatsNavigatorKey');
final _clientFavoritesNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'clientFavoritesNavigatorKey');
final _clientProfileNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'clientProfileNavigatorKey');

// Merchant router keys
final _merchantRootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'merchantRootNavigatorKey');
final _merchantHomeNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'merchantHomeNavigatorKey');
final _merchantProfileNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'merchantProfileNavigatorKey');
final _merchantChatsNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'merchantChatsNavigatorKey');
final _merchantSettingsNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'merchantSettingsNavigatorKey');

class AppRouter {
  static GoRouter? _clientRouterInstance;
  static GoRouter? _merchantRouterInstance;

  static GoRouter get clientRouter {
    return _clientRouterInstance ??= GoRouter(
      debugLogDiagnostics: true,
      navigatorKey: _clientRootNavigatorKey,
      initialLocation: RouteNames.home,
      redirect: (context, state) async {
        final localDataSource = getIt<AuthLocalDataSource>();
        // Check if access token exists (more reliable than isLoggedIn flag)
        final accessToken = await localDataSource.getAccessToken();
        final isLoggedIn = accessToken != null && accessToken.isNotEmpty;
        final isAuthRoute = state.matchedLocation == RouteNames.auth;
        final isProfileRoute = state.matchedLocation == RouteNames.profile;

        // Profile page can be accessed without authentication (shows login button)
        if (isProfileRoute) {
          return null;
        }

        // If not logged in and not on auth route, redirect to auth
        if (!isLoggedIn && !isAuthRoute) {
          return RouteNames.auth;
        }

        // If logged in and on auth route, redirect to home
        if (isLoggedIn && isAuthRoute) {
          return RouteNames.home;
        }

        return null; // No redirect needed
      },
      routes: [
        GoRoute(path: RouteNames.auth, name: RouteNames.auth, builder: (context, state) => const AuthScreen()),
        GoRoute(path: RouteNames.serviceDetails, builder: (context, state) => const WedyServicePage()),
        StatefulShellRoute.indexedStack(
          builder: (BuildContext context, GoRouterState state, StatefulNavigationShell navigationShell) =>
              NavigationShell(child: navigationShell),
          branches: [
            StatefulShellBranch(
              navigatorKey: _clientHomeNavigatorKey,
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
              navigatorKey: _clientChatsNavigatorKey,
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
              navigatorKey: _clientFavoritesNavigatorKey,
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
              navigatorKey: _clientProfileNavigatorKey,
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
    return _merchantRouterInstance ??= GoRouter(
      debugLogDiagnostics: true,
      navigatorKey: _merchantRootNavigatorKey,
      initialLocation: RouteNames.home,
      routes: [
        GoRoute(path: RouteNames.auth, builder: (context, state) => const AuthScreen()),
        GoRoute(path: RouteNames.edit, builder: (context, state) => const MerchantEditPage()),
        GoRoute(path: RouteNames.boost, builder: (context, state) => const BoostPage()),
        StatefulShellRoute.indexedStack(
          builder: (BuildContext context, GoRouterState state, StatefulNavigationShell navigationShell) =>
              NavigationShell(client: false, child: navigationShell),
          branches: [
            StatefulShellBranch(
              navigatorKey: _merchantHomeNavigatorKey,
              routes: [
                GoRoute(
                  path: RouteNames.home,
                  name: RouteNames.home,
                  pageBuilder: (context, state) => buildPageWithDefaultTransition<void>(
                    context: context,
                    state: state,
                    child: const MerchantHomePage(),
                  ),
                  routes: [
                    GoRoute(
                      path: RouteNames.reviews,
                      name: RouteNames.reviews,
                      builder: (context, state) => const ReviewsPage(),
                    ),
                  ],
                ),
              ],
            ),

            StatefulShellBranch(
              navigatorKey: _merchantProfileNavigatorKey,
              routes: [
                GoRoute(
                  path: RouteNames.profile,
                  name: RouteNames.profile,
                  pageBuilder: (context, state) => buildPageWithDefaultTransition<void>(
                    context: context,
                    state: state,
                    child: const WedyServicePage(isMerchant: true),
                  ),
                ),
              ],
            ),

            StatefulShellBranch(
              navigatorKey: _merchantChatsNavigatorKey,
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
              navigatorKey: _merchantSettingsNavigatorKey,
              routes: [
                GoRoute(
                  path: RouteNames.settings,
                  name: RouteNames.settings,
                  pageBuilder: (context, state) => buildPageWithDefaultTransition<void>(
                    context: context,
                    state: state,
                    child: const MerchantSettingsPage(),
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
