import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:wedy/core/config/app_config.dart';
import 'package:wedy/features/auth/presentation/bloc/auth_event.dart';
import 'package:wedy/features/profile/presentation/bloc/profile_bloc.dart';

import '../../core/di/injection_container.dart';
import '../../core/theme/app_theme.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../shared/navigation/app_router.dart';

class WedyClientApp extends StatelessWidget {
  const WedyClientApp({super.key});

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
            BlocProvider(create: (_) => getIt<ProfileBloc>()),
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
