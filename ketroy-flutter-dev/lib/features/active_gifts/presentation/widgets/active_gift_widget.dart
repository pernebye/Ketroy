import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ketroy_app/core/theme/theme.dart';
import 'package:ketroy_app/features/active_gifts/presentation/view_model/active_gifts_view_model.dart';
import 'package:provider/provider.dart';

class ActiveGiftTile extends StatelessWidget {
  const ActiveGiftTile({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final allVm = context.watch<ActiveGiftsViewModel>();
    return Column(
      children: [
        const SizedBox(
          height: 20,
        ),
        Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  spreadRadius: 0,
                  offset: const Offset(0, 0)),
            ], color: Colors.white, borderRadius: BorderRadius.circular(20.r)),
            child: Row(
              children: [
                SizedBox(
                    width: 159.w,
                    height: 148.h,
                    child: ClipRRect(
                        borderRadius: BorderRadiusGeometry.circular(20.r),
                        child: Image.network(allVm.giftImage))),
                SizedBox(
                  width: 16.w,
                ),
                Text(
                  allVm.formattedTime,
                  style: AppTheme.giftTextStyleLarge,
                )
              ],
            )),
      ],
    );
  }
}
