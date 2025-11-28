import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:ketroy_app/core/theme/theme.dart';
import 'package:ketroy_app/l10n/app_localizations.dart';

class ProfileTextField extends StatelessWidget {
  final String hint;
  final TextEditingController controller;
  final double boxHeight;
  final double height;
  final bool readOnly;
  final int maxLines;
  final bool needIcon;
  const ProfileTextField(
      {super.key,
      required this.hint,
      required this.controller,
      this.boxHeight = 53,
      this.height = 71,
      this.readOnly = false,
      this.maxLines = 1,
      this.needIcon = true});

  ProfileTextField copyWith(
      {double? boxHeight,
      double? height,
      bool? readOnly,
      int? maxLines,
      bool? needIcon}) {
    return ProfileTextField(
      hint: hint,
      controller: controller,
      boxHeight: boxHeight ?? this.boxHeight,
      height: height ?? this.height,
      readOnly: readOnly ?? this.readOnly,
      maxLines: maxLines ?? this.maxLines,
      needIcon: needIcon ?? this.needIcon,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          hint,
          style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.w500),
        ),
        SizedBox(
          height: boxHeight.h,
          child: TextFormField(
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return l10n?.requiredField ?? 'Required field';
              }
              return null;
            },
            readOnly: readOnly,
            style: AppTheme.profileDetailMediumTextStyle,
            maxLines: maxLines,
            controller: controller,
            decoration: const InputDecoration().copyWith(
              prefix: needIcon
                  ? Padding(
                      padding: EdgeInsets.symmetric(horizontal: 21.w),
                      child: SvgPicture.asset('images/flash.svg'),
                    )
                  : null,
              contentPadding: const EdgeInsets.all(0),
              border: const UnderlineInputBorder(),
              enabledBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFFF2F2F2))),
              focusedBorder: const UnderlineInputBorder(),
            ),
          ),
        ),
      ],
    );
  }
}
