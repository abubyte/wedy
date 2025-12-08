import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:wedy/core/config/app_config.dart';
import 'package:wedy/features/auth/presentation/bloc/auth_event.dart';

import '../../core/di/injection_container.dart';
import '../../core/theme/app_theme.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/profile/presentation/bloc/profile_bloc.dart';
import '../../features/service/presentation/bloc/merchant_service_bloc.dart';
import '../../features/category/presentation/bloc/category_bloc.dart';
import '../../features/category/presentation/bloc/category_event.dart';
import '../../shared/navigation/app_router.dart';

class WedyMerchantApp extends StatelessWidget {
  const WedyMerchantApp({super.key});

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
            BlocProvider(create: (_) => getIt<MerchantServiceBloc>()),
            BlocProvider(create: (_) => getIt<CategoryBloc>()..add(const LoadCategoriesEvent())),
          ],
          child: MaterialApp.router(
            title: AppConfig.instance.appName,
            theme: AppTheme.lightTheme,
            // darkTheme: AppTheme.darkTheme,
            routerConfig: AppRouter.merchantRouter,
            debugShowCheckedModeBanner: false,
          ),
        );
      },
    );
  }
}
