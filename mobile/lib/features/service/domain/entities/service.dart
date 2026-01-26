/// Service entity (domain layer)
class Service {
  final String id;
  final String name;
  final String description;
  final double price;
  final String? priceType;
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

  const Service({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.priceType,
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

  Service copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    String? priceType,
    String? locationRegion,
    double? Function()? latitude,
    double? Function()? longitude,
    int? viewCount,
    int? likeCount,
    int? saveCount,
    int? shareCount,
    double? overallRating,
    int? totalReviews,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    MerchantBasicInfo? merchant,
    int? categoryId,
    String? categoryName,
    List<ServiceImage>? images,
    List<MerchantContact>? contacts,
    bool? isFeatured,
    DateTime? Function()? featuredUntil,
    bool? isLiked,
    bool? isSaved,
  }) {
    return Service(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      priceType: priceType ?? this.priceType,
      locationRegion: locationRegion ?? this.locationRegion,
      latitude: latitude != null ? latitude() : this.latitude,
      longitude: longitude != null ? longitude() : this.longitude,
      viewCount: viewCount ?? this.viewCount,
      likeCount: likeCount ?? this.likeCount,
      saveCount: saveCount ?? this.saveCount,
      shareCount: shareCount ?? this.shareCount,
      overallRating: overallRating ?? this.overallRating,
      totalReviews: totalReviews ?? this.totalReviews,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      merchant: merchant ?? this.merchant,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      images: images ?? this.images,
      contacts: contacts ?? this.contacts,
      isFeatured: isFeatured ?? this.isFeatured,
      featuredUntil: featuredUntil != null ? featuredUntil() : this.featuredUntil,
      isLiked: isLiked ?? this.isLiked,
      isSaved: isSaved ?? this.isSaved,
    );
  }

  /// Create a copy with toggled like status and updated count
  Service toggleLike() {
    return copyWith(
      isLiked: !isLiked,
      likeCount: isLiked ? likeCount - 1 : likeCount + 1,
    );
  }

  /// Create a copy with toggled save status and updated count
  Service toggleSave() {
    return copyWith(
      isSaved: !isSaved,
      saveCount: isSaved ? saveCount - 1 : saveCount + 1,
    );
  }
}

/// Service list item (simplified version for listings)
class ServiceListItem {
  final String id;
  final String name;
  final String description;
  final double price;
  final String? priceType;
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

  const ServiceListItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.priceType,
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

  ServiceListItem copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    String? priceType,
    String? locationRegion,
    double? overallRating,
    int? totalReviews,
    int? viewCount,
    int? likeCount,
    int? saveCount,
    DateTime? createdAt,
    MerchantBasicInfo? merchant,
    int? categoryId,
    String? categoryName,
    String? Function()? mainImageUrl,
    bool? isFeatured,
    bool? isLiked,
    bool? isSaved,
  }) {
    return ServiceListItem(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      priceType: priceType ?? this.priceType,
      locationRegion: locationRegion ?? this.locationRegion,
      overallRating: overallRating ?? this.overallRating,
      totalReviews: totalReviews ?? this.totalReviews,
      viewCount: viewCount ?? this.viewCount,
      likeCount: likeCount ?? this.likeCount,
      saveCount: saveCount ?? this.saveCount,
      createdAt: createdAt ?? this.createdAt,
      merchant: merchant ?? this.merchant,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      mainImageUrl: mainImageUrl != null ? mainImageUrl() : this.mainImageUrl,
      isFeatured: isFeatured ?? this.isFeatured,
      isLiked: isLiked ?? this.isLiked,
      isSaved: isSaved ?? this.isSaved,
    );
  }

  /// Create a copy with toggled like status and updated count
  ServiceListItem toggleLike() {
    return copyWith(
      isLiked: !isLiked,
      likeCount: isLiked ? likeCount - 1 : likeCount + 1,
    );
  }

  /// Create a copy with toggled save status and updated count
  ServiceListItem toggleSave() {
    return copyWith(
      isSaved: !isSaved,
      saveCount: isSaved ? saveCount - 1 : saveCount + 1,
    );
  }

  /// Update with actual API response counts
  ServiceListItem withInteractionResponse(String interactionType, int newCount, bool isActive) {
    if (interactionType == 'like') {
      return copyWith(isLiked: isActive, likeCount: newCount);
    } else if (interactionType == 'save') {
      return copyWith(isSaved: isActive, saveCount: newCount);
    }
    return this;
  }
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

  const MerchantService({
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

  const MerchantServicesResponse({required this.services, required this.activeCount, required this.inactiveCount});
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

  const MerchantBasicInfo({
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

  const ServiceImage({required this.id, required this.s3Url, required this.fileName, required this.displayOrder});
}

/// Merchant contact (phone or social media)
class MerchantContact {
  final String id;
  final String contactType; // "phone" or "social_media"
  final String contactValue; // Phone number or social media URL
  final String? platformName; // Platform name for social media (instagram, telegram, etc.)
  final int displayOrder;

  const MerchantContact({
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

  const ServiceSearchFilters({
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

  ServiceSearchFilters copyWith({
    String? Function()? query,
    int? Function()? categoryId,
    String? Function()? locationRegion,
    double? Function()? minPrice,
    double? Function()? maxPrice,
    double? Function()? minRating,
    bool? Function()? isVerifiedMerchant,
    String? Function()? sortBy,
    String? Function()? sortOrder,
  }) {
    return ServiceSearchFilters(
      query: query != null ? query() : this.query,
      categoryId: categoryId != null ? categoryId() : this.categoryId,
      locationRegion: locationRegion != null ? locationRegion() : this.locationRegion,
      minPrice: minPrice != null ? minPrice() : this.minPrice,
      maxPrice: maxPrice != null ? maxPrice() : this.maxPrice,
      minRating: minRating != null ? minRating() : this.minRating,
      isVerifiedMerchant: isVerifiedMerchant != null ? isVerifiedMerchant() : this.isVerifiedMerchant,
      sortBy: sortBy != null ? sortBy() : this.sortBy,
      sortOrder: sortOrder != null ? sortOrder() : this.sortOrder,
    );
  }
}

/// Paginated service response
class PaginatedServiceResponse {
  final List<ServiceListItem> services;
  final int total;
  final int page;
  final int limit;
  final bool hasMore;
  final int totalPages;

  const PaginatedServiceResponse({
    required this.services,
    required this.total,
    required this.page,
    required this.limit,
    required this.hasMore,
    required this.totalPages,
  });
}
