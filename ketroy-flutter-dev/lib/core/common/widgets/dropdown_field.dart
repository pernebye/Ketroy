import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ketroy_app/core/common/entities/menu.dart';

class DropDownField extends StatelessWidget {
  const DropDownField({
    super.key,
    required this.onChanged,
    this.selectedValue,
    required this.options,
    this.labelText,
    this.profile = false,
    this.enabled = true,
    this.validator,
    this.hint,
    this.prefixIcon,
    this.borderRadius = 8.0,
    this.fillColor,
    this.borderColor,
    this.focusedBorderColor,
    this.textStyle,
    this.labelStyle,
    this.dropdownColor,
  });

  final Function(String?) onChanged;
  final String? selectedValue;
  final List<Menu> options;
  final String? labelText;
  final bool profile;
  final bool enabled;
  final String? Function(String?)? validator;
  final String? hint;
  final Widget? prefixIcon;
  final double borderRadius;
  final Color? fillColor;
  final Color? borderColor;
  final Color? focusedBorderColor;
  final TextStyle? textStyle;
  final TextStyle? labelStyle;
  final Color? dropdownColor;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: selectedValue,
      elevation: 8,
      isExpanded: true,
      isDense: false,
      dropdownColor: dropdownColor ?? Colors.white,
      validator: validator,
      decoration: _buildInputDecoration(context),
      onTap: () => FocusScope.of(context).requestFocus(FocusNode()),
      onChanged: enabled ? onChanged : null,
      hint: hint != null
          ? Text(
              hint!,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14.sp,
              ),
            )
          : null,
      icon: const Icon(
        Icons.keyboard_arrow_down,
        color: Colors.grey,
      ),
      items: options.map<DropdownMenuItem<String>>((Menu value) {
        return DropdownMenuItem<String>(
          value: value.name,
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 0.h),
            child: Text(
              value.name,
              style: textStyle ??
                  TextStyle(
                    fontSize: 14.sp,
                    color: Colors.black87,
                    fontWeight: FontWeight.normal,
                  ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        );
      }).toList(),
    );
  }

  InputDecoration _buildInputDecoration(BuildContext context) {
    if (profile) {
      return _buildProfileDecoration(context);
    }
    return _buildStandardDecoration(context);
  }

  InputDecoration _buildProfileDecoration(BuildContext context) {
    return InputDecoration(
      filled: true,
      fillColor: fillColor ?? Colors.white,
      labelText: labelText?.isNotEmpty ?? false ? labelText : null,
      labelStyle: labelStyle ??
          TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w400,
            fontSize: 14.sp,
          ),
      prefixIcon: prefixIcon,
      contentPadding: EdgeInsets.symmetric(
        horizontal: 16.w,
        vertical: 12.h,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        borderSide: BorderSide(
          color: borderColor ?? Colors.grey[300]!,
          width: 1,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        borderSide: BorderSide(
          color: borderColor ?? Colors.grey[300]!,
          width: 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        borderSide: BorderSide(
          color: focusedBorderColor ?? Theme.of(context).primaryColor,
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        borderSide: const BorderSide(
          color: Colors.red,
          width: 1,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        borderSide: const BorderSide(
          color: Colors.red,
          width: 2,
        ),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        borderSide: BorderSide(
          color: Colors.grey[200]!,
          width: 1,
        ),
      ),
    );
  }

  InputDecoration _buildStandardDecoration(BuildContext context) {
    return InputDecoration(
      labelText: labelText?.isNotEmpty ?? false ? labelText : null,
      labelStyle: labelStyle ??
          TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w300,
            fontSize: 14.sp,
          ),
      prefixIcon: prefixIcon,
      contentPadding: EdgeInsets.symmetric(
        horizontal: 0.w,
        vertical: 0.h,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        borderSide: BorderSide(
          color: focusedBorderColor ?? Theme.of(context).primaryColor,
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        borderSide: const BorderSide(
          color: Colors.red,
          width: 1,
        ),
      ),
    );
  }
}
