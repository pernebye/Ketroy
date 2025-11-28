import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ketroy_app/core/common/widgets/app_button.dart';
import 'package:ketroy_app/core/navBar/nav_bar.dart';
import 'package:ketroy_app/core/theme/theme.dart';
import 'package:ketroy_app/core/widgets/loader.dart';
import 'package:ketroy_app/features/active_gifts/presentation/view_model/all_gifts_view_model.dart';
import 'package:ketroy_app/features/active_gifts/presentation/widgets/active_gift_widget.dart';
import 'package:ketroy_app/features/active_gifts/widgets/my_gifts_widget.dart';
import 'package:ketroy_app/features/my_gifts/presentation/bloc/gifts_bloc.dart';
import 'package:ketroy_app/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

class ActivePageBody extends StatefulWidget {
  const ActivePageBody({
    super.key,
  });

// ✅ Добавляем статический GlobalKey
  static final GlobalKey<ActivePageBodyState> globalKey =
      GlobalKey<ActivePageBodyState>();

  @override
  State<ActivePageBody> createState() => ActivePageBodyState();
}

class ActivePageBodyState extends State<ActivePageBody> {
  bool _isRefreshing = false;
  int selectedIndex = 0;

  // ✅ Публичный метод для обновления страницы
  Future<void> refresh() async {
    if (_isRefreshing) return; // Предотвращаем множественные вызовы

    setState(() {
      _isRefreshing = true;
    });

    try {
      final allVm = Provider.of<AllGiftsViewModel>(context, listen: false);
      allVm.initialize(); // Перезагружаем данные
      NavScreen.globalKey.currentState?.updateNavState();

      if (mounted) {
        setState(() {}); // Принудительно обновляем UI
      }
    } catch (e) {
      debugPrint('Error refreshing ActivePageBody: $e');
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n?.updateError ?? "Update error"}: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final allVm = context.watch<AllGiftsViewModel>();
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.white, // ✅ Белый фон
      body: BlocConsumer<GiftsBloc, GiftsState>(
        listener: (context, state) {
          if (state.isActivate) {
            _showActivationSuccessDialog(context, state);
          }
        },
        builder: (context, state) {
          return SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 35.w),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedIndex = 0;
                            });
                          },
                          child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 5.w),
                              alignment: Alignment.center,
                              height: 41.h,
                              decoration: BoxDecoration(
                                  color: (selectedIndex == 0)
                                      ? const Color(0xFF3C4B1B)
                                      : null,
                                  border: Border.all(),
                                  borderRadius: BorderRadius.circular(13.r)),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  l10n.activeGifts,
                                  style: AppTheme.newsMediumTextStyle.copyWith(
                                      color: (selectedIndex == 0)
                                          ? Colors.white
                                          : Colors.black),
                                ),
                              )),
                        ),
                      ),
                      SizedBox(
                        width: 18.w,
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedIndex = 1;
                            });
                          },
                          child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 5.w),
                              alignment: Alignment.center,
                              height: 41.h,
                              decoration: BoxDecoration(
                                  color: (selectedIndex == 1)
                                      ? const Color(0xFF3C4B1B)
                                      : null,
                                  border: Border.all(),
                                  borderRadius: BorderRadius.circular(13.r)),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  l10n.savedGifts,
                                  style: AppTheme.newsMediumTextStyle.copyWith(
                                      color: (selectedIndex == 1)
                                          ? Colors.white
                                          : Colors.black),
                                ),
                              )),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20.h),
                  if (selectedIndex == 0)
                    Expanded(
                      child: Stack(
                        children: [
                          RefreshIndicator(
                            onRefresh: refresh,
                            child: allVm.items.isEmpty
                                ? _buildEmptyState(l10n)
                                : ListView.builder(
                                    physics:
                                        const AlwaysScrollableScrollPhysics(),
                                    padding: EdgeInsets.only(
                                        bottom:
                                            NavBar.getBottomPadding(context)),
                                    itemCount: allVm.items.length,
                                    itemBuilder: (_, index) {
                                      return ChangeNotifierProvider.value(
                                        value: allVm.items[index],
                                        child: const ActiveGiftTile(),
                                      );
                                    },
                                  ),
                          ),

                          // ✅ Показываем индикатор загрузки при обновлении
                          if (_isRefreshing)
                            Container(
                              color: Colors.black.withValues(alpha: 0.3),
                              child: const Loader(),
                            ),
                        ],
                      ),
                    ),
                  if (selectedIndex == 1)
                    Expanded(
                        child: RefreshIndicator(
                      onRefresh: () async {
                        context.read<GiftsBloc>().add(GetGiftsListFetch());
                        await Future.delayed(const Duration(milliseconds: 500));
                      },
                      child: (state.savedGiftsList.isNotEmpty)
                          ? ListView.builder(
                              padding: EdgeInsets.only(
                                  bottom: NavBar.getBottomPadding(context)),
                              itemCount: state.savedGiftsList.length,
                              itemBuilder: (contetx, index) {
                                return MyGiftsWidget(
                                  gift: state.savedGiftsList[index],
                                );
                              })
                          : ListView(
                              // ✅ Оборачиваем в ListView для RefreshIndicator
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: EdgeInsets.only(
                                  bottom: NavBar.getBottomPadding(context)),
                              children: [
                                SizedBox(
                                  height: 400.h,
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.card_giftcard_outlined,
                                          size: 80.sp,
                                          color: Colors.grey[400],
                                        ),
                                        SizedBox(height: 20.h),
                                        Text(
                                          l10n.noSavedGifts,
                                          style: TextStyle(
                                              fontSize: 18.sp,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.grey[600]),
                                        ),
                                        SizedBox(height: 10.h),
                                        Text(
                                          l10n.giftsWillAppear,
                                          style: TextStyle(
                                              fontSize: 14.sp,
                                              color: Colors.grey[500]),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                    )),
                  // Отступ для NavBar
                  SizedBox(height: NavBar.getBottomPadding(context)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.only(bottom: NavBar.getBottomPadding(context)),
      children: [
        SizedBox(height: 200.h),
        Center(
          child: Column(
            children: [
              Icon(
                Icons.card_giftcard_outlined,
                size: 80.sp,
                color: Colors.grey[400],
              ),
              SizedBox(height: 20.h),
              Text(
                l10n.noActiveGifts,
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 10.h),
              Text(
                l10n.activateGiftToSee,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.grey[500],
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20.h),
              ElevatedButton(
                onPressed: _isRefreshing ? null : refresh,
                child: Text(_isRefreshing ? l10n.updating : l10n.update),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showActivationSuccessDialog(BuildContext context, GiftsState state) {
    final l10n = AppLocalizations.of(context)!;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return SimpleDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          title: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 24),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  l10n.youActivatedGift,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          children: <Widget>[
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Text(
                l10n.giftIsNearby,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14.sp),
              ),
            ),
            SizedBox(height: 20.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: AppButton(
                title: l10n.done,
                onPressed: () async {
                  final allVm = context.read<AllGiftsViewModel>();

                  // Добавляем подарок в активные с правильными данными
                  if (state.savedGiftsList.isNotEmpty) {
                    final firstGift = state.savedGiftsList.first;
                    allVm.addItem(
                      firstGift.image ?? 'default_image',
                      firstGift.id,
                      l10n.activatedGiftNumber(firstGift.id.toString()),
                    );
                  }

                  context.read<GiftsBloc>().add(ResetStateFetch());
                  Navigator.of(dialogContext).pop();
                  Navigator.of(context).popUntil((route) => route.isFirst);

                  // ✅ Ждем небольшую задержку для завершения навигации
                  await Future.delayed(const Duration(milliseconds: 100));

                  // ✅ Переключаемся на вкладку активных подарков (индекс 4)
                  NavScreen.globalKey.currentState
                      ?.switchToTab(4, popToFirst: true);

                  // ✅ Обновляем счетчик в навигации
                  NavScreen.globalKey.currentState?.updateNavState();
                },
                backgroundColor: Colors.black,
              ),
            ),
            SizedBox(height: 12.h),
          ],
        );
      },
    );
  }
}
