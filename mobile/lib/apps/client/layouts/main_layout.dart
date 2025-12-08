import 'package:flutter/material.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:wedy/core/theme/app_colors.dart';
import 'package:wedy/core/constants/app_dimensions.dart';

class ClientMainLayout extends StatelessWidget {
  final Widget headerContent;
  final List<Widget> bodyChildren;
  final double expandedHeight;
  final double collapsedHeight;
  final RefreshController? refreshController;
  final VoidCallback? onRefresh;
  final Widget? refreshHeader;

  const ClientMainLayout({
    super.key,
    required this.headerContent,
    required this.bodyChildren,
    this.expandedHeight = 80,
    this.collapsedHeight = 70,
    this.refreshController,
    this.onRefresh,
    this.refreshHeader,
  });

  @override
  Widget build(BuildContext context) {
    final bodyContent = Container(
      color: AppColors.background,
      child: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.only(top: AppDimensions.spacingL),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(AppDimensions.radiusXL),
              topRight: Radius.circular(AppDimensions.radiusXL),
            ),
            border: Border(top: BorderSide(color: AppColors.border, width: .5)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: bodyChildren),
        ),
      ),
    );

    return Scaffold(
      body: SafeArea(
        child: NestedScrollView(
          headerSliverBuilder: (_, innerBoxIsScrollable) => [
            SliverAppBar(
              floating: true,
              expandedHeight: expandedHeight,
              collapsedHeight: collapsedHeight,
              automaticallyImplyLeading: false,
              backgroundColor: AppColors.background,
              flexibleSpace: headerContent,
            ),
          ],
          body: refreshController != null && onRefresh != null
              ? SmartRefresher(
                  controller: refreshController!,
                  onRefresh: onRefresh,
                  enablePullDown: true,
                  enablePullUp: false,
                  header:
                      refreshHeader ??
                      const ClassicHeader(
                        refreshingText: 'Yuklanmoqda...',
                        completeText: 'Yangilandi!',
                        idleText: 'Yuklab olish uchun torting',
                        releaseText: 'Qo\'yib bering',
                        textStyle: TextStyle(color: AppColors.primary),
                      ),
                  child: bodyContent,
                )
              : bodyContent,
        ),
      ),
    );
  }
}
