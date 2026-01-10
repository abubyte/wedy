/// Service entity (domain layer)
class Service {
  final String id;
  final String name;
  final String description;
  final double price;
  final String locationRegion;
  final double? latitude;
  final double? longitude;
  final int viewCount;
  final int likeCount;
  final int saveCount;
  final int shareCount;
  final double overallRating;
  final int totalReviews;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final MerchantBasicInfo merchant;
  final int categoryId;
  final String categoryName;
  final List<ServiceImage> images;
  final List<MerchantContact> contacts;
  final bool isFeatured;
  final DateTime? featuredUntil;
  final bool isLiked;
  final bool isSaved;

  Service({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.locationRegion,
    this.latitude,
    this.longitude,
    required this.viewCount,
    required this.likeCount,
    required this.saveCount,
    required this.shareCount,
    required this.overallRating,
    required this.totalReviews,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    required this.merchant,
    required this.categoryId,
    required this.categoryName,
    required this.images,
    this.contacts = const [],
    this.isFeatured = false,
    this.featuredUntil,
    this.isLiked = false,
    this.isSaved = false,
  });

  /// Get phone contacts only
  List<MerchantContact> get phoneContacts =>
      contacts.where((c) => c.isPhone).toList()..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));

  /// Get social media contacts only
  List<MerchantContact> get socialMediaContacts =>
      contacts.where((c) => c.isSocialMedia).toList()..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
}

/// Service list item (simplified version for listings)
class ServiceListItem {
  final String id;
  final String name;
  final String description;
  final double price;
  final String locationRegion;
  final double overallRating;
  final int totalReviews;
  final int viewCount;
  final int likeCount;
  final int saveCount;
  final DateTime createdAt;
  final MerchantBasicInfo merchant;
  final int categoryId;
  final String categoryName;
  final String? mainImageUrl;
  final bool isFeatured;
  final bool isLiked;
  final bool isSaved;

  ServiceListItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.locationRegion,
    required this.overallRating,
    required this.totalReviews,
    required this.viewCount,
    required this.likeCount,
    required this.saveCount,
    required this.createdAt,
    required this.merchant,
    required this.categoryId,
    required this.categoryName,
    this.mainImageUrl,
    this.isFeatured = false,
    this.isLiked = false,
    this.isSaved = false,
  });
}

/// Merchant service (simplified version for merchant's own services)
class MerchantService {
  final String id;
  final String name;
  final String description;
  final int categoryId;
  final String categoryName;
  final double price;
  final String locationRegion;
  final double? latitude;
  final double? longitude;
  final bool isActive;
  final int viewCount;
  final int likeCount;
  final int saveCount;
  final double overallRating;
  final int totalReviews;
  final String? mainImageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  MerchantService({
    required this.id,
    required this.name,
    required this.description,
    required this.categoryId,
    required this.categoryName,
    required this.price,
    required this.locationRegion,
    this.latitude,
    this.longitude,
    required this.isActive,
    required this.viewCount,
    required this.likeCount,
    required this.saveCount,
    required this.overallRating,
    required this.totalReviews,
    this.mainImageUrl,
    required this.createdAt,
    required this.updatedAt,
  });
}

/// Merchant services response
class MerchantServicesResponse {
  final List<MerchantService> services;
  final int activeCount;
  final int inactiveCount;

  MerchantServicesResponse({required this.services, required this.activeCount, required this.inactiveCount});
}

/// Merchant basic information
class MerchantBasicInfo {
  final String id;
  final String businessName;
  final double overallRating;
  final int totalReviews;
  final String locationRegion;
  final bool isVerified;
  final String? avatarUrl;

  MerchantBasicInfo({
    required this.id,
    required this.businessName,
    required this.overallRating,
    required this.totalReviews,
    required this.locationRegion,
    required this.isVerified,
    this.avatarUrl,
  });
}

/// Service image
class ServiceImage {
  final String id;
  final String s3Url;
  final String fileName;
  final int displayOrder;

  ServiceImage({required this.id, required this.s3Url, required this.fileName, required this.displayOrder});
}

/// Merchant contact (phone or social media)
class MerchantContact {
  final String id;
  final String contactType; // "phone" or "social_media"
  final String contactValue; // Phone number or social media URL
  final String? platformName; // Platform name for social media (instagram, telegram, etc.)
  final int displayOrder;

  MerchantContact({
    required this.id,
    required this.contactType,
    required this.contactValue,
    this.platformName,
    required this.displayOrder,
  });

  bool get isPhone => contactType == 'phone';
  bool get isSocialMedia => contactType == 'social_media';
}

/// Service search filters
class ServiceSearchFilters {
  final String? query;
  final int? categoryId;
  final String? locationRegion;
  final double? minPrice;
  final double? maxPrice;
  final double? minRating;
  final bool? isVerifiedMerchant;
  final String? sortBy;
  final String? sortOrder;

  ServiceSearchFilters({
    this.query,
    this.categoryId,
    this.locationRegion,
    this.minPrice,
    this.maxPrice,
    this.minRating,
    this.isVerifiedMerchant,
    this.sortBy,
    this.sortOrder,
  });
}

/// Paginated service response
class PaginatedServiceResponse {
  final List<ServiceListItem> services;
  final int total;
  final int page;
  final int limit;
  final bool hasMore;
  final int totalPages;

  PaginatedServiceResponse({
    required this.services,
    required this.total,
    required this.page,
    required this.limit,
    required this.hasMore,
    required this.totalPages,
  });
}
