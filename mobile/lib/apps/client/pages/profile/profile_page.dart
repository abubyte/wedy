import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'dart:io';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wedy/core/utils/shimmer_helper.dart';
import 'package:wedy/shared/navigation/route_names.dart';
import 'package:wedy/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:wedy/features/auth/presentation/bloc/auth_event.dart';
import 'package:wedy/features/auth/presentation/bloc/auth_state.dart';
import 'package:wedy/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:wedy/features/profile/presentation/bloc/profile_event.dart';
import 'package:wedy/features/profile/presentation/bloc/profile_state.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';

class ClientProfilePage extends StatefulWidget {
  const ClientProfilePage({super.key});

  @override
  State<ClientProfilePage> createState() => _ClientProfilePageState();
}

class _ClientProfilePageState extends State<ClientProfilePage> {
  final RefreshController _refreshController = RefreshController(initialRefresh: false);

  @override
  void initState() {
    super.initState();
    // Load profile when page opens
    context.read<ProfileBloc>().add(const LoadProfileEvent());
  }

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }

  void _onRefresh() {
    // Refresh profile data
    context.read<ProfileBloc>().add(const LoadProfileEvent());
    // Also refresh auth status to get latest user data
    context.read<AuthBloc>().add(const CheckAuthStatusEvent());
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is Unauthenticated) {
          // Navigate to auth screen when logged out
          if (context.mounted) {
            context.go(RouteNames.auth);
          }
        }
      },
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, authState) {
          final isAuthenticated = authState is Authenticated;
          final authenticatedUser = isAuthenticated ? authState.user : null;
          final authLoading = authState is AuthLoading || authState is AuthInitial;

          return BlocListener<ProfileBloc, ProfileState>(
            listener: (context, state) {
              // Handle refresh completion
              if (state is ProfileLoaded && _refreshController.isRefresh) {
                _refreshController.refreshCompleted();
              } else if (state is ProfileError && _refreshController.isRefresh) {
                _refreshController.refreshFailed();
              }

              if (state is ProfileError) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: AppColors.error));
              } else if (state is ProfileUpdated || state is AvatarUploaded) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Profil yangilandi'), backgroundColor: AppColors.success));
                // Update auth state with new user data
                context.read<AuthBloc>().add(const CheckAuthStatusEvent());
              }
            },
            child: Scaffold(
              backgroundColor: AppColors.background,
              body: SafeArea(
                child: SmartRefresher(
                  controller: _refreshController,
                  onRefresh: _onRefresh,
                  enablePullDown: true,
                  enablePullUp: false,
                  header: const ClassicHeader(
                    refreshingText: 'Yangilanmoqda...',
                    completeText: 'Yangilandi!',
                    idleText: 'Yangilash uchun torting',
                    releaseText: 'Yangilash uchun qo\'yib yuboring',
                    textStyle: TextStyle(color: AppColors.primary),
                  ),
                  child: authLoading
                      ? SizedBox(
                          height: MediaQuery.of(context).size.height - 200,
                          width: double.infinity,
                          child: const Center(child: CircularProgressIndicator()),
                        )
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(AppDimensions.spacingL),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              if (!isAuthenticated && !authLoading) ...[
                                // Header
                                Row(
                                  mainAxisSize: MainAxisSize.max,
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [Text('Profil', style: AppTextStyles.headline2)],
                                ),
                                const SizedBox(height: AppDimensions.spacingL),

                                // Login button
                                GestureDetector(
                                  onTap: () => context.pushNamed(RouteNames.auth),
                                  child: Container(
                                    height: 43,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      borderRadius: BorderRadius.circular(AppDimensions.radiusL),
                                      border: Border.all(color: const Color(0xFF1E4ED8), width: .5),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppDimensions.spacingM,
                                      vertical: AppDimensions.spacingS,
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Icon(IconsaxPlusLinear.profile, color: AppColors.surface, size: 24),
                                        const SizedBox(width: AppDimensions.spacingM),
                                        Expanded(
                                          child: Text(
                                            'Kirish',
                                            style: AppTextStyles.bodyRegular.copyWith(color: AppColors.surface),
                                          ),
                                        ),
                                        const Icon(IconsaxPlusLinear.arrow_right_3, color: AppColors.surface, size: 16),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: AppDimensions.spacingM),
                              ],

                              if (isAuthenticated && authenticatedUser != null) ...[
                                BlocBuilder<ProfileBloc, ProfileState>(
                                  builder: (context, state) {
                                    final user = authenticatedUser;
                                    final isLoading = state is ProfileLoading || authLoading;

                                    return isLoading
                                        ? SizedBox(
                                            height: MediaQuery.of(context).size.height - 200,
                                            width: double.infinity,
                                            child: const Center(child: CircularProgressIndicator()),
                                          )
                                        : Column(
                                            children: [
                                              // Avatar
                                              Stack(
                                                children: [
                                                  GestureDetector(
                                                    onTap: isLoading ? null : _showAvatarEditOptions,
                                                    child: Container(
                                                      width: 100,
                                                      height: 100,
                                                      decoration: BoxDecoration(
                                                        color: AppColors.surface,
                                                        borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
                                                        border: Border.all(color: AppColors.border, width: .5),
                                                      ),
                                                      child: user.avatarUrl != null && user.avatarUrl!.isNotEmpty
                                                          ? ClipRRect(
                                                              borderRadius: BorderRadius.circular(
                                                                AppDimensions.radiusPill,
                                                              ),
                                                              child: CachedNetworkImage(
                                                                imageUrl: user.avatarUrl!,
                                                                fit: BoxFit.cover,
                                                                placeholder: (context, url) => Center(
                                                                  child: ShimmerHelper.shimmerCircle(height: 100),
                                                                ),
                                                                errorWidget: (context, url, error) => const Icon(
                                                                  IconsaxPlusLinear.profile,
                                                                  size: 70,
                                                                  color: Colors.black,
                                                                ),
                                                              ),
                                                            )
                                                          : const Icon(
                                                              IconsaxPlusLinear.profile,
                                                              size: 70,
                                                              color: Colors.black,
                                                            ),
                                                    ),
                                                  ),
                                                  Positioned(
                                                    right: 0,
                                                    bottom: 0,
                                                    child: GestureDetector(
                                                      onTap: isLoading ? null : _showAvatarEditOptions,
                                                      child: Container(
                                                        width: 27,
                                                        height: 27,
                                                        decoration: BoxDecoration(
                                                          color: AppColors.surface,
                                                          borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
                                                          border: Border.all(color: AppColors.border, width: .5),
                                                        ),
                                                        child: const Icon(
                                                          IconsaxPlusLinear.edit_2,
                                                          size: 16,
                                                          color: Colors.black,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: AppDimensions.spacingS),

                                              Text(
                                                user.name,
                                                style: AppTextStyles.title2.copyWith(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),

                                              Text(
                                                'ID: ${user.id}',
                                                style: AppTextStyles.caption.copyWith(
                                                  fontSize: 12,
                                                  color: AppColors.textMuted,
                                                ),
                                              ),

                                              const SizedBox(height: AppDimensions.spacingM),

                                              // Edit Profile Button
                                              GestureDetector(
                                                onTap: isLoading ? null : () => context.pushNamed(RouteNames.account),
                                                // onTap: isLoading ? null : () => _showEditProfileDialog(context, user),
                                                child: Container(
                                                  height: 43,
                                                  decoration: BoxDecoration(
                                                    color: AppColors.surface,
                                                    borderRadius: BorderRadius.circular(AppDimensions.radiusL),
                                                    border: Border.all(color: AppColors.border, width: .5),
                                                  ),
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: AppDimensions.spacingM,
                                                    vertical: AppDimensions.spacingS,
                                                  ),
                                                  child: Row(
                                                    children: [
                                                      const Icon(
                                                        IconsaxPlusLinear.profile,
                                                        size: 24,
                                                        color: Colors.black,
                                                      ),
                                                      const SizedBox(width: AppDimensions.spacingM),
                                                      Text(
                                                        'Akkount',
                                                        style: AppTextStyles.bodyRegular.copyWith(
                                                          fontWeight: FontWeight.bold,
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                      const Spacer(),
                                                      const Icon(
                                                        IconsaxPlusLinear.arrow_right_3,
                                                        size: 16,
                                                        color: Colors.black,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: AppDimensions.spacingM),
                                            ],
                                          );
                                  },
                                ),

                                // Profile items
                                Container(
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius: BorderRadius.circular(AppDimensions.radiusL),
                                    border: Border.all(color: AppColors.border, width: .5),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppDimensions.spacingM,
                                    vertical: AppDimensions.spacingS,
                                  ),
                                  child: Column(
                                    children: [
                                      const SizedBox(height: AppDimensions.spacingXS),
                                      GestureDetector(
                                        onTap: () => context.pushNamed(RouteNames.myReviews, extra: 'user'),
                                        child: Row(
                                          children: [
                                            const Icon(
                                              IconsaxPlusLinear.message_question,
                                              size: 24,
                                              color: Colors.black,
                                            ),
                                            const SizedBox(width: AppDimensions.spacingM),
                                            Text(
                                              'Fikrlar',
                                              style: AppTextStyles.bodyRegular.copyWith(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            ),
                                            const Spacer(),
                                            const Icon(IconsaxPlusLinear.arrow_right_3, size: 16, color: Colors.black),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: AppDimensions.spacingS),
                                      const Padding(
                                        padding: EdgeInsets.symmetric(horizontal: AppDimensions.spacingS),
                                        child: Divider(height: 1, color: AppColors.border),
                                      ),
                                      const SizedBox(height: AppDimensions.spacingS),
                                      GestureDetector(
                                        onTap: () => context.pushNamed(RouteNames.favorites),
                                        child: Row(
                                          children: [
                                            const Icon(IconsaxPlusLinear.heart, size: 24, color: Colors.black),
                                            const SizedBox(width: AppDimensions.spacingM),
                                            Text(
                                              'Sevimlilar',
                                              style: AppTextStyles.bodyRegular.copyWith(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            ),
                                            const Spacer(),
                                            const Icon(IconsaxPlusLinear.arrow_right_3, size: 16, color: Colors.black),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: AppDimensions.spacingXS),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: AppDimensions.spacingM),
                              ],

                              // Help items
                              Container(
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(AppDimensions.radiusL),
                                  border: Border.all(color: AppColors.border, width: .5),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppDimensions.spacingM,
                                  vertical: AppDimensions.spacingS,
                                ),
                                child: Column(
                                  children: [
                                    const SizedBox(height: AppDimensions.spacingXS),
                                    GestureDetector(
                                      onTap: () => context.pushNamed(RouteNames.help),
                                      child: Row(
                                        children: [
                                          const Icon(IconsaxPlusLinear.message_question, size: 24, color: Colors.black),
                                          const SizedBox(width: AppDimensions.spacingM),
                                          Text(
                                            'Yordam',
                                            style: AppTextStyles.bodyRegular.copyWith(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                          const Spacer(),
                                          const Icon(IconsaxPlusLinear.arrow_right_3, size: 16, color: Colors.black),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: AppDimensions.spacingS),
                                    const Padding(
                                      padding: EdgeInsets.symmetric(horizontal: AppDimensions.spacingS),
                                      child: Divider(height: 1, color: AppColors.border),
                                    ),
                                    const SizedBox(height: AppDimensions.spacingS),
                                    GestureDetector(
                                      onTap: () => context.pushNamed(RouteNames.policy),
                                      child: Row(
                                        children: [
                                          const Icon(IconsaxPlusLinear.document_text_1, size: 24, color: Colors.black),
                                          const SizedBox(width: AppDimensions.spacingM),
                                          Text(
                                            'Foydalanish shartlari / Maxfiylik siyosati',
                                            style: AppTextStyles.bodyRegular.copyWith(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                          const Spacer(),
                                          const Icon(IconsaxPlusLinear.arrow_right_3, size: 16, color: Colors.black),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: AppDimensions.spacingS),
                                    const Padding(
                                      padding: EdgeInsets.symmetric(horizontal: AppDimensions.spacingS),
                                      child: Divider(height: 1, color: AppColors.border),
                                    ),
                                    const SizedBox(height: AppDimensions.spacingS),
                                    GestureDetector(
                                      onTap: _openPlayStoreReview,
                                      child: Row(
                                        children: [
                                          const Icon(IconsaxPlusLinear.like_tag, size: 24, color: Colors.black),
                                          const SizedBox(width: AppDimensions.spacingM),
                                          Text(
                                            'Ilovani baxolash',
                                            style: AppTextStyles.bodyRegular.copyWith(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                          const Spacer(),
                                          const Icon(IconsaxPlusLinear.arrow_right_3, size: 16, color: Colors.black),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: AppDimensions.spacingS),
                                    const Padding(
                                      padding: EdgeInsets.symmetric(horizontal: AppDimensions.spacingS),
                                      child: Divider(height: 1, color: AppColors.border),
                                    ),
                                    const SizedBox(height: AppDimensions.spacingS),
                                    GestureDetector(
                                      onTap: _openPlayStoreReview,
                                      child: Row(
                                        children: [
                                          const Icon(IconsaxPlusLinear.sms_tracking, size: 24, color: Colors.black),
                                          const SizedBox(width: AppDimensions.spacingM),
                                          Text(
                                            'Fikr bildirish',
                                            style: AppTextStyles.bodyRegular.copyWith(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                          const Spacer(),
                                          const Icon(IconsaxPlusLinear.arrow_right_3, size: 16, color: Colors.black),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: AppDimensions.spacingXS),
                                  ],
                                ),
                              ),
                              const SizedBox(height: AppDimensions.spacingM),

                              // Wedy Biznes Button
                              GestureDetector(
                                onTap: () => launchUrl(Uri.parse('https://wedy.uz/biznes')),
                                child: Container(
                                  height: 43,
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius: BorderRadius.circular(AppDimensions.radiusL),
                                    border: Border.all(color: AppColors.border, width: .5),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppDimensions.spacingM,
                                    vertical: AppDimensions.spacingS,
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(IconsaxPlusLinear.status_up, size: 24, color: Colors.black),
                                      const SizedBox(width: AppDimensions.spacingM),
                                      Text(
                                        'Wedy Biznes',
                                        style: AppTextStyles.bodyRegular.copyWith(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                      const Spacer(),
                                      const Icon(IconsaxPlusLinear.arrow_right_3, size: 16, color: Colors.black),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppDimensions.spacingS),
                            ],
                          ),
                        ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showAvatarEditOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(IconsaxPlusLinear.camera),
              title: const Text('Kameradan olish'),
              onTap: () {
                Navigator.pop(context);
                _pickImageFromCamera();
              },
            ),
            ListTile(
              leading: const Icon(IconsaxPlusLinear.gallery),
              title: const Text('Galereyadan tanlash'),
              onTap: () {
                Navigator.pop(context);
                _pickImageFromGallery();
              },
            ),
            ListTile(
              leading: const Icon(IconsaxPlusLinear.trash, color: Colors.red),
              title: const Text('O\'chirish', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement delete avatar
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImageFromCamera() async {
    if (!mounted) return;
    final profileBloc = context.read<ProfileBloc>();

    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (image != null && mounted) {
        profileBloc.add(UploadAvatarEvent(image.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Kamera xatosi: ${e.toString()}'), backgroundColor: AppColors.error));
      }
    }
  }

  Future<void> _openPlayStoreReview() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final packageName = packageInfo.packageName;

      if (Platform.isAndroid) {
        // Try to open in Play Store app first
        final marketUrl = Uri.parse('market://details?id=$packageName');
        if (await canLaunchUrl(marketUrl)) {
          await launchUrl(marketUrl);
        } else {
          // Fallback to web URL
          final webUrl = Uri.parse('https://play.google.com/store/apps/details?id=$packageName');
          await launchUrl(webUrl, mode: LaunchMode.externalApplication);
        }
      } else if (Platform.isIOS) {
        // For iOS, open App Store (you'll need to set the app ID)
        final url = Uri.parse('https://apps.apple.com/app/id1234567890?action=write-review');
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Xatolik yuz berdi: ${e.toString()}'), backgroundColor: AppColors.error));
      }
    }
  }

  Future<void> _pickImageFromGallery() async {
    if (!mounted) return;
    final profileBloc = context.read<ProfileBloc>();

    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (image != null && mounted) {
        profileBloc.add(UploadAvatarEvent(image.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Galereya xatosi: ${e.toString()}'), backgroundColor: AppColors.error));
      }
    }
  }

  void _showEditProfileDialog(BuildContext context, user) {
    final nameController = TextEditingController(text: user.name);
    final phoneController = TextEditingController(text: user.phoneNumber);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Profilni tahrirlash'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Ism', hintText: 'Ismingizni kiriting'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(labelText: 'Telefon raqam', hintText: 'Telefon raqamingizni kiriting'),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Bekor qilish')),
          TextButton(
            onPressed: () {
              final newName = nameController.text.trim();
              final newPhone = phoneController.text.trim();

              if (newName.isNotEmpty || newPhone.isNotEmpty) {
                context.read<ProfileBloc>().add(
                  UpdateProfileEvent(
                    name: newName.isNotEmpty ? newName : null,
                    phoneNumber: newPhone.isNotEmpty && newPhone != user.phoneNumber ? newPhone : null,
                  ),
                );
                Navigator.pop(context);
              }
            },
            child: const Text('Saqlash'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chiqish'),
        content: const Text('Haqiqatan ham chiqmoqchimisiz?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Bekor qilish')),
          TextButton(
            onPressed: () {
              context.read<AuthBloc>().add(const LogoutEvent());
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Chiqish'),
          ),
        ],
      ),
    );
  }
}
