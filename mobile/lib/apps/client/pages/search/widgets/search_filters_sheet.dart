part of '../search_page.dart';

class _SearchFiltersSheet extends StatefulWidget {
  const _SearchFiltersSheet({required this.filters, required this.onApply});

  final ServiceSearchFilters filters;
  final Function(ServiceSearchFilters) onApply;

  @override
  State<_SearchFiltersSheet> createState() => _SearchFiltersSheetState();
}

class _SearchFiltersSheetState extends State<_SearchFiltersSheet> {
  late int? _selectedCategoryId;
  late String? _selectedLocation;
  late double? _minPrice;
  late double? _maxPrice;
  late double? _minRating;
  late bool? _isVerifiedMerchant;
  late String? _sortBy;
  late String? _sortOrder;

  // Mapping from Uzbek names (UI) to English names (API)
  static const Map<String, String> _locationMapping = {
    'Toshkent': 'Tashkent',
    'Samarqand': 'Samarkand',
    'Buxoro': 'Bukhara',
    'Andijon': 'Andijan',
    'Farg\'ona': 'Ferghana',
    'Namangan': 'Namangan',
    'Qashqadaryo': 'Kashkadarya',
    'Surxondaryo': 'Surkhandarya',
    'Jizzax': 'Jizzakh',
    'Sirdaryo': 'Sirdarya',
    'Navoiy': 'Navoiy',
    'Xorazm': 'Khorezm',
    'Qoraqalpog\'iston': 'Karakalpakstan',
  };

  // Reverse mapping from English names (API) to Uzbek names (UI)
  static const Map<String, String> _locationReverseMapping = {
    'Tashkent': 'Toshkent',
    'Samarkand': 'Samarqand',
    'Bukhara': 'Buxoro',
    'Andijan': 'Andijon',
    'Ferghana': 'Farg\'ona',
    'Namangan': 'Namangan',
    'Kashkadarya': 'Qashqadaryo',
    'Surkhandarya': 'Surxondaryo',
    'Jizzakh': 'Jizzax',
    'Sirdarya': 'Sirdaryo',
    'Navoiy': 'Navoiy',
    'Khorezm': 'Xorazm',
    'Karakalpakstan': 'Qoraqalpog\'iston',
  };

  final List<String> _locations = [
    'Toshkent',
    'Samarqand',
    'Buxoro',
    'Andijon',
    'Farg\'ona',
    'Namangan',
    'Qashqadaryo',
    'Surxondaryo',
    'Jizzax',
    'Sirdaryo',
    'Navoiy',
    'Xorazm',
    'Qoraqalpog\'iston',
  ];

  final List<String> _sortOptions = ['created_at', 'price', 'rating', 'popularity', 'name'];

  @override
  void initState() {
    super.initState();
    _selectedCategoryId = widget.filters.categoryId;
    // Convert English API name to Uzbek UI name for display
    _selectedLocation = widget.filters.locationRegion != null
        ? _locationReverseMapping[widget.filters.locationRegion] ?? widget.filters.locationRegion
        : null;
    _minPrice = widget.filters.minPrice;
    _maxPrice = widget.filters.maxPrice;
    _minRating = widget.filters.minRating;
    _isVerifiedMerchant = widget.filters.isVerifiedMerchant;
    _sortBy = widget.filters.sortBy ?? 'created_at';
    _sortOrder = widget.filters.sortOrder ?? 'desc';
  }

  void _applyFilters() {
    // Convert Uzbek UI name to English API name
    final locationRegionForApi = _selectedLocation != null
        ? _locationMapping[_selectedLocation] ?? _selectedLocation
        : null;

    final filters = ServiceSearchFilters(
      query: widget.filters.query,
      categoryId: _selectedCategoryId,
      locationRegion: locationRegionForApi,
      minPrice: _minPrice,
      maxPrice: _maxPrice,
      minRating: _minRating,
      isVerifiedMerchant: _isVerifiedMerchant,
      sortBy: _sortBy,
      sortOrder: _sortOrder,
    );
    widget.onApply(filters);
    Navigator.pop(context);
  }

  void _clearFilters() {
    setState(() {
      _selectedCategoryId = null;
      _selectedLocation = null;
      _minPrice = null;
      _maxPrice = null;
      _minRating = null;
      _isVerifiedMerchant = null;
      _sortBy = 'created_at';
      _sortOrder = 'desc';
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CategoryBloc, CategoryState>(
      builder: (context, categoryState) {
        final categories = categoryState is CategoriesLoaded
            ? categoryState.categories.categories
            : <ServiceCategory>[];

        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimensions.radiusXL)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: AppDimensions.spacingL),
              // Header
              Padding(
                padding: const EdgeInsets.all(AppDimensions.spacingL),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Filtrlar', style: AppTextStyles.headline2),
                    Row(
                      children: [
                        TextButton(
                          onPressed: _clearFilters,
                          child: Text('Tozalash', style: AppTextStyles.bodyRegular.copyWith(color: AppColors.primary)),
                        ),
                        const SizedBox(width: AppDimensions.spacingS),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(IconsaxPlusLinear.close_circle),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppDimensions.spacingL),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category filter
                      Text('Kategoriya', style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: AppDimensions.spacingS),
                      Wrap(
                        spacing: AppDimensions.spacingS,
                        runSpacing: AppDimensions.spacingS,
                        children: [
                          _FilterChip(
                            label: 'Barchasi',
                            selected: _selectedCategoryId == null,
                            onTap: () => setState(() => _selectedCategoryId = null),
                          ),
                          ...categories.map(
                            (category) => _FilterChip(
                              label: category.name,
                              selected: _selectedCategoryId == category.id,
                              onTap: () => setState(() => _selectedCategoryId = category.id),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppDimensions.spacingL),

                      // Location filter
                      Text('Joylashuv', style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: AppDimensions.spacingS),
                      Wrap(
                        spacing: AppDimensions.spacingS,
                        runSpacing: AppDimensions.spacingS,
                        children: [
                          _FilterChip(
                            label: 'Barchasi',
                            selected: _selectedLocation == null,
                            onTap: () => setState(() => _selectedLocation = null),
                          ),
                          ..._locations.map(
                            (location) => _FilterChip(
                              label: location,
                              selected: _selectedLocation == location,
                              onTap: () => setState(() => _selectedLocation = location),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppDimensions.spacingL),

                      // Price range
                      Text('Narx', style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: AppDimensions.spacingS),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              decoration: InputDecoration(
                                labelText: 'dan',
                                hintText: '0',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusM)),
                              ),
                              keyboardType: TextInputType.number,
                              onChanged: (value) {
                                _minPrice = value.isEmpty ? null : double.tryParse(value);
                              },
                            ),
                          ),
                          const SizedBox(width: AppDimensions.spacingM),
                          Expanded(
                            child: TextField(
                              decoration: InputDecoration(
                                labelText: 'gacha',
                                hintText: '10000000',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusM)),
                              ),
                              keyboardType: TextInputType.number,
                              onChanged: (value) {
                                _maxPrice = value.isEmpty ? null : double.tryParse(value);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppDimensions.spacingL),

                      // Rating filter
                      Text('Reyting', style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: AppDimensions.spacingS),
                      Row(
                        children: [
                          _FilterChip(
                            label: 'Barchasi',
                            selected: _minRating == null,
                            onTap: () => setState(() => _minRating = null),
                          ),
                          const SizedBox(width: AppDimensions.spacingS),
                          _FilterChip(
                            label: '4.0+',
                            selected: _minRating == 4.0,
                            onTap: () => setState(() => _minRating = 4.0),
                          ),
                          const SizedBox(width: AppDimensions.spacingS),
                          _FilterChip(
                            label: '4.5+',
                            selected: _minRating == 4.5,
                            onTap: () => setState(() => _minRating = 4.5),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppDimensions.spacingL),

                      // Verified merchant filter
                      Row(
                        children: [
                          Checkbox(
                            value: _isVerifiedMerchant ?? false,
                            onChanged: (value) => setState(() => _isVerifiedMerchant = value),
                          ),
                          const SizedBox(width: AppDimensions.spacingS),
                          Text('Faqat tasdiqlangan sotuvchilar', style: AppTextStyles.bodyRegular),
                        ],
                      ),
                      const SizedBox(height: AppDimensions.spacingL),

                      // Sort by
                      Text('Saralash', style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: AppDimensions.spacingS),
                      DropdownButtonFormField<String>(
                        initialValue: _sortBy,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusM)),
                        ),
                        items: _sortOptions.map((option) {
                          String label;
                          switch (option) {
                            case 'created_at':
                              label = 'Yangi';
                              break;
                            case 'price':
                              label = 'Narx';
                              break;
                            case 'rating':
                              label = 'Reyting';
                              break;
                            case 'popularity':
                              label = 'Mashhur';
                              break;
                            case 'name':
                              label = 'Nomi';
                              break;
                            default:
                              label = option;
                          }
                          return DropdownMenuItem(value: option, child: Text(label));
                        }).toList(),
                        onChanged: (value) => setState(() => _sortBy = value),
                      ),
                      const SizedBox(height: AppDimensions.spacingS),
                      Row(
                        children: [
                          _FilterChip(
                            label: 'O\'sish',
                            selected: _sortOrder == 'asc',
                            onTap: () => setState(() => _sortOrder = 'asc'),
                          ),
                          const SizedBox(width: AppDimensions.spacingS),
                          _FilterChip(
                            label: 'Kamayish',
                            selected: _sortOrder == 'desc',
                            onTap: () => setState(() => _sortOrder = 'desc'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              // Apply button
              Padding(
                padding: const EdgeInsets.all(AppDimensions.spacingL),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _applyFilters,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: AppDimensions.spacingM),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusM)),
                    ),
                    child: Text('Qo\'llash', style: AppTextStyles.bodyLarge.copyWith(color: Colors.white)),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingM, vertical: AppDimensions.spacingS),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          border: Border.all(color: selected ? AppColors.primary : AppColors.border, width: 1),
        ),
        child: Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: selected ? Colors.white : AppColors.textPrimary,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
