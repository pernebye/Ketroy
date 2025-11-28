import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:ketroy_app/core/common/widgets/app_button.dart';
import 'package:ketroy_app/core/navBar/nav_bar.dart';
import 'package:ketroy_app/core/theme/theme.dart';
import 'package:ketroy_app/features/active_gifts/presentation/view_model/all_gifts_view_model.dart';
import 'package:ketroy_app/features/my_gifts/domain/entities/gifts_entities.dart';
import 'package:ketroy_app/features/my_gifts/presentation/bloc/gifts_bloc.dart';
import 'package:ketroy_app/main.dart';
import 'package:provider/provider.dart';
import 'package:ketroy_app/l10n/app_localizations.dart';

class GiftPageActive extends StatelessWidget {
  final GiftsEntities newGift;
  const GiftPageActive({super.key, required this.newGift});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AllGiftsViewModel>(
      create: (context) => AllGiftsViewModel(),
      child: GiftPageActiveBody(
        newGift: newGift,
      ),
    );
  }
}

class GiftPageActiveBody extends StatelessWidget {
  final GiftsEntities newGift;
  const GiftPageActiveBody({super.key, required this.newGift});

  @override
  Widget build(BuildContext context) {
    final allVm = context.watch<AllGiftsViewModel>();
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Colors.white, // ✅ Белый фон
      body: BlocConsumer<GiftsBloc, GiftsState>(
        listener: (context, state) {
          if (state.isActivate) {
            showDialog<void>(
                context: context,
                builder: (BuildContext context) {
                  final dialogL10n = AppLocalizations.of(context)!;
                  return SimpleDialog(
                    backgroundColor: Colors.white,
                    // <-- SEE HERE
                    title:
                        Text(textAlign: TextAlign.center, state.message ?? ''),
                    children: <Widget>[
                      SimpleDialogOption(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: Text(
                            textAlign: TextAlign.center,
                            dialogL10n.activateGiftInstructions),
                      ),
                      SimpleDialogOption(
                        onPressed: () {
                          context
                              .read<GiftsBloc>()
                              .add(ActivateGiftFetch(giftId: newGift.id));
                        },
                        child: Container(
                          decoration: BoxDecoration(
                              border: Border.all(),
                              borderRadius: BorderRadius.circular(8.r)),
                          child: AppButton(
                              title: dialogL10n.readyButton,
                              onPressed: () {
                                Navigator.of(context)
                                    .popUntil((route) => route.isFirst);
                                allVm.addItem('image', 1, 'Test');
                              },
                              backgroundColor: Colors.black),
                        ),
                      ),
                      SimpleDialogOption(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: Container(
                          decoration: BoxDecoration(
                              border: Border.all(),
                              borderRadius: BorderRadius.circular(8.r)),
                          child: AppButton(
                              title: dialogL10n.myGiftsButton,
                              onPressed: () {
                                // Закрываем все предыдущие экраны до первого
                                Navigator.of(context)
                                    .popUntil((route) => route.isFirst);

                                // Открываем NavScreen с флагом, чтобы внутри уже открыть MyGiftsPage
                                navigatorKey.currentState?.pushReplacement(
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const NavScreen(fromGift: true),
                                  ),
                                );
                              },
                              backgroundColor: Colors.white),
                        ),
                      ),
                    ],
                  );
                });
          } else if (state.isSaved) {
            Navigator.pop(context);
          }
        },
        builder: (context, state) {
          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 35.w),
            child: Column(
              children: [
                SizedBox(
                  height: 131.h,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(children: [
                          TextSpan(
                              text: '${l10n.congratulations} \n',
                              style: AppTheme.giftTextStyle.copyWith(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold)),
                          TextSpan(
                              text: ' ${l10n.chooseOneGift}',
                              style: AppTheme.giftTextStyle
                                  .copyWith(color: Colors.black))
                        ])),
                  ],
                ),
                SizedBox(
                  height: 20.h,
                ),
                Container(
                  width: 216.w,
                  height: 233.h,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20.r),
                      color: const Color(0xFFF9F9FC)),
                  child: (state.gifts[0].image != null)
                      ? Image.network(state.gifts[0].image!)
                      : const SizedBox(),
                ),
                SizedBox(
                  height: 30.h,
                ),
                SvgPicture.asset('images/ketroy-logo.svg'),
                SizedBox(
                  height: 15.h,
                ),
                SvgPicture.asset('images/ketroy-word.svg'),
                SizedBox(
                  height: 20.h,
                ),
                Row(
                  children: [
                    Expanded(
                        child: AppButton(
                            title: l10n.activateButton,
                            onPressed: () {
                              Navigator.pop(context);
                              context
                                  .read<GiftsBloc>()
                                  .add(ActivateGiftFetch(giftId: newGift.id));
                            },
                            backgroundColor: Colors.black)),
                  ],
                ),
                SizedBox(
                  height: 20.h,
                ),
                Row(
                  children: [
                    Expanded(
                        child: Container(
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8.r),
                          border: Border.all()),
                      child: AppButton(
                          title: l10n.saveGiftButton,
                          onPressed: () {
                            context
                                .read<GiftsBloc>()
                                .add(SaveGiftFetch(giftId: newGift.id));
                          },
                          backgroundColor: Colors.white),
                    )),
                  ],
                )
              ],
            ),
          );
        },
      ),
    );
  }
}
