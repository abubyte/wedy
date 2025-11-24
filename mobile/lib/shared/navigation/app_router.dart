import 'package:go_router/go_router.dart';
import 'package:wedy/apps/client/pages/client_shell.dart';
import 'package:wedy/apps/client/pages/items/items_page.dart';
import 'package:wedy/apps/client/pages/service/service_page.dart';
import 'package:wedy/apps/merchant/pages/merchant_shell.dart';
import 'package:wedy/features/auth/presentation/screens/auth_screen.dart';
import 'package:wedy/shared/navigation/route_names.dart';

class AppRouter {
  static GoRouter get clientRouter {
    return GoRouter(
      initialLocation: RouteNames.home,
      routes: [
        GoRoute(
          path: RouteNames.auth,
          builder: (context, state) => const AuthScreen(),
        ),
        GoRoute(
          path: RouteNames.home,
          builder: (context, state) => const ClientShellPage(),
        ),
        GoRoute(
          path: RouteNames.hotOffers,
          builder: (context, state) => const ClientItemsPage(hotOffers: true),
        ),
        GoRoute(
          path: RouteNames.items,
          builder: (context, state) => const ClientItemsPage(),
        ),
        GoRoute(
          path: RouteNames.serviceDetails,
          builder: (context, state) => const ClientServicePage(),
        ),
      ],
    );
  }

  static GoRouter get merchantRouter {
    return GoRouter(
      initialLocation: RouteNames.home,
      routes: [
        GoRoute(
          path: RouteNames.auth,
          builder: (context, state) => const AuthScreen(),
        ),
        GoRoute(
          path: RouteNames.home,
          builder: (context, state) => const MerchantShellPage(),
        ),
      ],
    );
  }
}
