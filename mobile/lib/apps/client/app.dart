import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:wedy/core/config/app_config.dart';
import 'package:wedy/core/utils/deep_link_service.dart';
import 'package:wedy/features/auth/presentation/bloc/auth_event.dart';
import 'package:wedy/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:wedy/features/service/presentation/bloc/service_bloc.dart';
import 'package:wedy/features/category/presentation/bloc/category_bloc.dart';

import '../../core/di/injection_container.dart';
import '../../core/theme/app_theme.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../shared/navigation/app_router.dart';

class WedyClientApp extends StatefulWidget {
  const WedyClientApp({super.key});

  @override
  State<WedyClientApp> createState() => _WedyClientAppState();
}

class _WedyClientAppState extends State<WedyClientApp> {
  final DeepLinkService _deepLinkService = DeepLinkService();

  @override
  void initState() {
    super.initState();
    _handleInitialDeepLink();
    _listenToDeepLinks();
  }

  /// Handle deep link when app is opened via deep link
  Future<void> _handleInitialDeepLink() async {
    final deepLink = await _deepLinkService.getInitialDeepLink();
    if (deepLink != null && mounted) {
      _navigateFromDeepLink(deepLink);
    }
  }

  /// Listen to deep links when app is running
  void _listenToDeepLinks() {
    _deepLinkService.deepLinkStream.listen((deepLink) {
      if (mounted) {
        _navigateFromDeepLink(deepLink);
      }
    });
  }

  /// Navigate to route from deep link
  void _navigateFromDeepLink(String deepLink) {
    final route = _deepLinkService.deepLinkToRoute(deepLink);
    if (route != null && mounted) {
      // Use a post-frame callback to ensure router is ready
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          final router = GoRouter.of(context);
          router.go(route);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MultiBlocProvider(
          providers: [
            BlocProvider(create: (_) => getIt<AuthBloc>()..add(const CheckAuthStatusEvent())),
            BlocProvider(create: (_) => getIt<ServiceBloc>()),
            BlocProvider(create: (_) => getIt<ProfileBloc>()),
            BlocProvider(create: (_) => getIt<CategoryBloc>()),
          ],
          child: MaterialApp.router(
            title: AppConfig.instance.appName,
            theme: AppTheme.lightTheme,
            // darkTheme: AppTheme.darkTheme,
            routerConfig: AppRouter.clientRouter,
            debugShowCheckedModeBanner: false,
          ),
        );
      },
    );
  }
}
