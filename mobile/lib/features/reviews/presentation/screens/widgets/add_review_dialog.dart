import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:wedy/core/theme/app_colors.dart';
import 'package:wedy/core/constants/app_dimensions.dart';
import 'package:wedy/core/theme/app_text_styles.dart';
import '../../bloc/review_bloc.dart';
import '../../bloc/review_event.dart';
import '../../bloc/review_state.dart';

class AddReviewDialog extends StatefulWidget {
  const AddReviewDialog({super.key, required this.serviceId});

  final String serviceId;

  @override
  State<AddReviewDialog> createState() => _AddReviewDialogState();
}

class _AddReviewDialogState extends State<AddReviewDialog> {
  int _rating = 5;
  final TextEditingController _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ReviewBloc, ReviewState>(
      listener: (context, state) {
        if (state is ReviewCreated) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Fikr muvaffaqiyatli qo\'shildi'),
              backgroundColor: AppColors.success,
            ),
          );
        } else if (state is ReviewError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      child: AlertDialog(
        title: const Text('Fikr qo\'shish'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Baholash:', style: AppTextStyles.bodyLarge),
              const SizedBox(height: AppDimensions.spacingS),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final starIndex = index + 1;
                  return IconButton(
                    icon: Icon(
                      starIndex <= _rating ? IconsaxPlusBold.star_1 : IconsaxPlusLinear.star_1,
                      color: starIndex <= _rating ? Colors.yellow : Colors.grey,
                      size: 32,
                    ),
                    onPressed: () => setState(() => _rating = starIndex),
                  );
                }),
              ),
              const SizedBox(height: AppDimensions.spacingM),
              Text('Izoh:', style: AppTextStyles.bodyLarge),
              const SizedBox(height: AppDimensions.spacingS),
              TextField(
                controller: _commentController,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: 'Fikringizni yozing...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Bekor qilish'),
          ),
          BlocBuilder<ReviewBloc, ReviewState>(
            builder: (context, state) {
              final isLoading = state is ReviewLoading;
              return ElevatedButton(
                onPressed: isLoading
                    ? null
                    : () {
                        context.read<ReviewBloc>().add(
                              CreateReviewEvent(
                                serviceId: widget.serviceId,
                                rating: _rating,
                                comment: _commentController.text.trim().isEmpty
                                    ? null
                                    : _commentController.text.trim(),
                              ),
                            );
                      },
                child: isLoading ? const CircularProgressIndicator() : const Text('Yuborish'),
              );
            },
          ),
        ],
      ),
    );
  }
}
