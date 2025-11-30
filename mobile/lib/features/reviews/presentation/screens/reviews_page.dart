import 'package:flutter/material.dart';
import 'package:wedy/features/service/presentation/screens/service/service_page.dart';
import 'package:wedy/core/constants/app_dimensions.dart';
import 'package:wedy/core/theme/app_text_styles.dart';
import 'package:wedy/shared/widgets/circular_button.dart';

class ReviewsPage extends StatelessWidget {
  const ReviewsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.spacingL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back button
                const WedyCircularButton(),
                const SizedBox(height: AppDimensions.spacingM),

                // Header
                Text(
                  'Fikrlar',
                  style: AppTextStyles.headline2.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 24,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingL),

                // Reviews list
                const ServiceReviews(vertical: true),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
