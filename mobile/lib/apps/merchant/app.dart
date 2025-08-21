import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/theme/app_theme.dart';
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
            // Add your BLoCs here
          ],
          child: MaterialApp.router(
            title: 'Wedy Business - Manage Your Services',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            routerConfig: AppRouter.merchantRouter,
            debugShowCheckedModeBanner: false,
          ),
        );
      },
    );
  }
}
