import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:ketroy_app/core/theme/theme.dart';

class ProfileMenu extends StatelessWidget {
  const ProfileMenu({
    super.key,
    required this.image,
    required this.title,
    this.subTitle,
    this.onTap,
  });

  final String image;
  final String title;
  final String? subTitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20.r),
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 16.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: const Color(0xFFEAEAEA)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0D000000),
              blurRadius: 16,
              offset: Offset(0, 6),
            )
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44.w,
              height: 44.w,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFF6F6F6),
              ),
              child: Center(
                child: SvgPicture.asset(
                  image,
                  width: 20.w,
                  height: 20.h,
                ),
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTheme.profileLargeTextStyle.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (subTitle != null) ...[
                    SizedBox(height: 4.h),
                    Text(
                      subTitle!,
                      style: AppTheme.profileSmallTextStyle,
                    ),
                  ]
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF8C8C8C),
            )
          ],
        ),
      ),
    );
  }
}
