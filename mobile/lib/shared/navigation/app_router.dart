import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';

class AppRouter {
  static GoRouter get clientRouter {
    return GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const Scaffold(body: Center(child: Text('Wedy Client App - Coming Soon!'))),
        ),
      ],
    );
  }

  static GoRouter get merchantRouter {
    return GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const Scaffold(body: Center(child: Text('Wedy Merchant App - Coming Soon!'))),
        ),
      ],
    );
  }
}
