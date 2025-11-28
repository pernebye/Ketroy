import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ketroy_app/core/theme/theme.dart';
import 'package:ketroy_app/core/widgets/loader.dart';
import 'package:ketroy_app/features/my_gifts/domain/entities/gifts_entities.dart';
import 'package:ketroy_app/features/my_gifts/presentation/bloc/gifts_bloc.dart';
import 'package:ketroy_app/features/my_gifts/presentation/pages/gift_page_active.dart';
import 'package:ketroy_app/l10n/app_localizations.dart';

class GiftsPage extends StatelessWidget {
  const GiftsPage({super.key});

  @override
  Widget build(BuildContext context) {
    context.read<GiftsBloc>().add(GetGiftsListFetch());
    return Scaffold(
      backgroundColor: Colors.white, // ✅ Белый фон
      body: BlocConsumer<GiftsBloc, GiftsState>(
        listener: (context, state) {},
        builder: (context, state) {
          if (state.isSuccess) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    (state.avaImage != null && state.avaImage!.isNotEmpty)
                        ? CircleAvatar(
                            child: Image.network(state.avaImage!),
                          )
                        : const CircleAvatar(),
                    SizedBox(
                      width: 9.w,
                    ),
                    Text(
                      '${state.name} ${state.surname}',
                      style: AppTheme.giftTextStyle,
                    )
                  ],
                ),
                SizedBox(
                  height: 20.h,
                ),
                Builder(
                  builder: (context) {
                    final l10n = AppLocalizations.of(context)!;
                    return RichText(
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
                        ]));
                  },
                ),
                SizedBox(
                  height: 45.h,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                        onTap: () {
                          if (state.gifts.isNotEmpty) {
                            _navigateToPage(context, state.gifts[0]);
                          }
                        },
                        child: Image.asset('images/giftR.png')),
                    SizedBox(
                      width: 39.w,
                    ),
                    GestureDetector(
                        onTap: () {
                          if (state.gifts.isNotEmpty) {
                            _navigateToPage(context, state.gifts[0]);
                          }
                        },
                        child: Image.asset('images/giftR.png')),
                  ],
                ),
                SizedBox(
                  height: 20.h,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                        onTap: () {
                          if (state.gifts.isNotEmpty) {
                            _navigateToPage(context, state.gifts[0]);
                          }
                        },
                        child: Image.asset('images/giftR.png')),
                    SizedBox(
                      width: 39.w,
                    ),
                    GestureDetector(
                        onTap: () {
                          if (state.gifts.isNotEmpty) {
                            _navigateToPage(context, state.gifts[0]);
                          }
                        },
                        child: Image.asset('images/giftR.png')),
                  ],
                )
              ],
            );
          }
          return const Loader();
        },
      ),
    );
  }

  void _navigateToPage(BuildContext context, GiftsEntities newGift) {
    Navigator.of(context).pushReplacement(PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => GiftPageActive(
        newGift: newGift,
      ),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, 1.0); // снизу
        const end = Offset.zero;
        const curve = Curves.ease;

        var tween =
            Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        var offsetAnimation = animation.drive(tween);

        return SlideTransition(
          position: offsetAnimation,
          child: child,
        );
      },
    ));
  }
}
