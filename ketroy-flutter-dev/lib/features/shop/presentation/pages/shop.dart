import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ketroy_app/core/common/entities/menu.dart';
import 'package:ketroy_app/core/common/widgets/dropdown_field.dart';
import 'package:ketroy_app/core/widgets/loader.dart';
import 'package:ketroy_app/features/shop/presentation/bloc/shop_bloc.dart';
import 'package:ketroy_app/features/shop_detail/presentation/pages/shop_detail.dart';
import 'package:ketroy_app/l10n/app_localizations.dart';
import 'package:ketroy_app/services/local_storage/user_data_manager.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import 'package:ketroy_app/core/common/widgets/app_button.dart' show AppLiquidGlassSettings;
import 'package:ketroy_app/core/common/mixins/adaptive_header_mixin.dart';

class ShopPage extends StatefulWidget {
  final bool pop;
  const ShopPage({super.key, required this.pop});

  @override
  State<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> with SingleTickerProviderStateMixin, AdaptiveHeaderMixin {
  // Цвета дизайна
  static const Color _primaryGreen = Color(0xFF3C4B1B);
  static const Color _accentGreen = Color(0xFF8BC34A);
  static const Color _darkBg = Color(0xFF1A1F12);
  static const Color _cardBg = Color(0xFFF5F7F0);
  static const String _allCitiesKey = '__ALL_CITIES__';

  String? _selectedValue;
  final List<Menu> _cityNames = [];
  bool _isInitialized = false;

  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _loadShopList();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
    
    // Инициализация адаптивного хедера
    initAdaptiveHeader(fallbackHeightRatio: 0.25);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _initializeCityList(ShopState state, AppLocalizations l10n) {
    if (!_isInitialized && state.cityList.isNotEmpty) {
      _cityNames.clear();
      _cityNames.add(Menu(
        name: l10n.allCities,
        value: 0,
        image: const SizedBox.shrink(),
      ));

      final uniqueCities = <String>{};
      int counter = 1;

      for (var item in state.cityList) {
        if (item.city.isNotEmpty && uniqueCities.add(item.city)) {
          _cityNames.add(Menu(
            name: item.city,
            value: counter,
            image: const SizedBox.shrink(),
          ));
          counter++;
        }
      }

      _isInitialized = true;
      _selectedValue ??= l10n.allCities;
    }
  }

  Future<void> _loadShopList() async {
    try {
      final user = await UserDataManager.getUser();
      final city = user?.city;
      _selectedValue = (city != null && city.isNotEmpty) ? city : _allCitiesKey;

      if (!mounted) return;

      context.read<ShopBloc>()
        ..add(GetShopListFetch(city: city?.isEmpty == true ? null : city))
        ..add(GetCityListFetch());
    } catch (e) {
      debugPrint('Error loading data: $e');
    }
  }

  void _onCityChanged(String? newValue, AppLocalizations l10n) {
    if (newValue == null || newValue == _selectedValue) return;
    setState(() => _selectedValue = newValue);
    final city = (newValue == _allCitiesKey || newValue == l10n.allCities) ? null : newValue;
    context.read<ShopBloc>().add(GetShopListFetch(city: city));
  }

  void _navigateToShopDetail(dynamic shopData, String? userId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ShopDetail(userId: userId ?? '', shopData: shopData),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _cardBg,
        body: BlocConsumer<ShopBloc, ShopState>(
          listener: (context, state) {},
          builder: (context, state) {
            if (!state.isSuccess) {
              return const Center(child: Loader());
            }
            _initializeCityList(state, l10n);
            return _buildContent(state, l10n);
          },
        ),
      ),
    );
  }

  Widget _buildContent(ShopState state, AppLocalizations l10n) {
    // Планируем измерение хедера
    scheduleHeaderMeasurement();
    
    return Stack(
      children: [
        // Адаптивный градиентный header
        buildAdaptiveGradient(colors: [_darkBg, _primaryGreen]),

        // Контент
        SafeArea(
          child: RefreshIndicator(
            color: _accentGreen,
            onRefresh: _loadShopList,
            child: CustomScrollView(
              slivers: [
                // Header с ключом для измерения
                SliverToBoxAdapter(
                  child: KeyedSubtree(key: headerKey, child: _buildHeader(l10n)),
                ),

                // Dropdown города
                SliverToBoxAdapter(
                  child: Container(
                    margin: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 0),
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.location_on_outlined,
                            color: _primaryGreen, size: 22.w),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: DropDownField(
                            selectedValue: _selectedValue == _allCitiesKey ? l10n.allCities : (_selectedValue ?? l10n.allCities),
                            onChanged: (value) {
                              FocusScope.of(context).unfocus();
                              _onCityChanged(value, l10n);
                            },
                            options: _cityNames,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SliverToBoxAdapter(child: SizedBox(height: 20.h)),

                // Список магазинов или пустое состояние
                state.shopList.isNotEmpty
                    ? _buildShopList(state, l10n)
                    : SliverToBoxAdapter(child: _buildEmptyState(l10n)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(AppLocalizations l10n) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Row(
        children: [
          if (widget.pop)
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: LiquidGlass.withOwnLayer(
                settings: AppLiquidGlassSettings.button,
                shape: LiquidRoundedSuperellipse(borderRadius: 22.r),
                child: SizedBox(
                  width: 44.w,
                  height: 44.w,
                  child: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                    size: 20.sp,
                  ),
                ),
              ),
            )
          else
            SizedBox(width: 44.w),
          Expanded(
            child: Column(
              children: [
                Text(
                  l10n.shops,
                  style: TextStyle(
                    fontSize: 22.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.store_outlined, size: 16.w, color: _accentGreen),
                    SizedBox(width: 6.w),
                    Text(
                      l10n.ketroyStoreNetwork,
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(width: 44.w),
        ],
      ),
    );
  }

  Widget _buildShopList(ShopState state, AppLocalizations l10n) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          return AnimatedBuilder(
            animation: _animController,
            builder: (context, child) {
              final delay = (index * 0.1).clamp(0.0, 0.5);
              final value = Curves.easeOut.transform(
                ((_animController.value - delay) / (1 - delay)).clamp(0.0, 1.0),
              );
              return Transform.translate(
                offset: Offset(0, 30 * (1 - value)),
                child: Opacity(opacity: value, child: child),
              );
            },
            child: _buildShopCard(state.shopList[index], state.id, l10n),
          );
        },
        childCount: state.shopList.length,
      ),
    );
  }

  Widget _buildShopCard(dynamic shop, String? userId, AppLocalizations l10n) {
    return GestureDetector(
      onTap: () => _navigateToShopDetail(shop, userId),
      child: Container(
        margin: EdgeInsets.fromLTRB(16.w, 0, 16.w, 20.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Изображение
            ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20.r),
                topRight: Radius.circular(20.r),
              ),
              child: CachedNetworkImage(
                imageUrl: shop.filePath,
                height: 180.h,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  height: 180.h,
                  color: _cardBg,
                  child: const Center(child: CompactLoader()),
                ),
                errorWidget: (context, url, error) => Container(
                  height: 180.h,
                  color: _cardBg,
                  child: Icon(Icons.image_not_supported,
                      color: Colors.grey, size: 48.w),
                ),
              ),
            ),

            // Информация
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (shop.addresses != null)
                    Text(
                      shop.addresses!,
                      style: TextStyle(
                        fontSize: 17.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  SizedBox(height: 6.h),
                  Row(
                    children: [
                      Icon(Icons.access_time_rounded,
                          size: 16.w, color: _primaryGreen),
                      SizedBox(width: 6.w),
                      Text(
                        shop.openingHours ?? '',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  Row(
                    children: [
                      Text(
                        l10n.moreDetails,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: _primaryGreen,
                        ),
                      ),
                      SizedBox(width: 4.w),
                      Icon(Icons.arrow_forward_ios,
                          size: 14.w, color: _primaryGreen),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    return Container(
      height: 400.h,
      padding: EdgeInsets.symmetric(horizontal: 40.w),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100.w,
              height: 100.w,
              decoration: BoxDecoration(
                color: _primaryGreen.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.store_outlined,
                size: 48.w,
                color: _primaryGreen.withValues(alpha: 0.5),
              ),
            ),
            SizedBox(height: 24.h),
            Text(
              l10n.noShopsFound,
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              l10n.noShopsInCity,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15.sp,
                color: Colors.black45,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
