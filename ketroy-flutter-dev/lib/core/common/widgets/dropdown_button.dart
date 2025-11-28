import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ketroy_app/core/common/entities/menu.dart';
import 'package:ketroy_app/core/common/widgets/unified_input_field.dart';

class DropdownButtonCustom extends StatefulWidget {
  const DropdownButtonCustom({
    super.key,
    required this.items,
    required this.selectedValue,
    required this.onChanged,
    required this.hintTitle,
    this.padding = false,
    this.fromPostUser = false,
    // required this.height,
  });

  final Function(int?) onChanged;

  final List<Menu> items;
  final int? selectedValue;
  final String hintTitle;
  final bool padding;
  final bool fromPostUser;

  @override
  State<DropdownButtonCustom> createState() => _DropdownButtonCustomState();
}

class _DropdownButtonCustomState extends State<DropdownButtonCustom>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 0.5).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Menu? get selectedItem {
    if (widget.selectedValue == null) return null;
    try {
      return widget.items.firstWhere(
        (item) => item.value == widget.selectedValue,
      );
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return DropdownButtonHideUnderline(
      child: DropdownButton2<int>(
        // Кастомная иконка стрелки
        iconStyleData: IconStyleData(
          icon: AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Row(
                children: [
                  Transform.rotate(
                    angle: _animation.value * 3.14159 * 2,
                    child: Icon(
                      Icons.arrow_drop_down,
                      color: Colors.grey[600],
                      size: 25.sp,
                    ),
                  ),
                  SizedBox(
                    width: 5.w,
                  )
                ],
              );
            },
          ),
          iconSize: 20.sp,
        ),
        isExpanded: true,
        hint: Text(
          widget.hintTitle,
          style: UnifiedInputField.hintStyle,
        ),
        items: widget.items
            .map((item) => DropdownMenuItem<int>(
                  value: item.value,
                  child: LayoutBuilder(builder: (context, constraints) {
                    return Container(
                      width: constraints.maxWidth,
                      constraints: BoxConstraints(
                        maxWidth: constraints.maxWidth,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(
                            height: 17.sp, // Высота = размеру текста
                            child: item.image,
                          ),
                          // Минимальный отступ
                          SizedBox(width: 4.w),
                          Expanded(
                            child: Text(
                              item.name,
                              style: UnifiedInputField.textStyle,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              softWrap: false,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ))
            .toList(),
        selectedItemBuilder: (BuildContext context) {
          return widget.items
              .map((item) => Align(
                    alignment: Alignment.centerLeft,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(
                          height: 17.sp, // Высота = размеру текста
                          child: item.image,
                        ),
                        SizedBox(width: 4.w),
                        Expanded(
                          child: Text(
                            item.name,
                            style: UnifiedInputField.textStyle,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            softWrap: false,
                          ),
                        ),
                      ],
                    ),
                  ))
              .toList();
        },
        value: widget.selectedValue,
        onChanged: widget.onChanged,
        onMenuStateChange: (isOpen) {
          setState(() {});
          if (isOpen) {
            _animationController.forward();
          } else {
            _animationController.reverse();
          }
        },
        buttonStyleData: ButtonStyleData(
          // Если padding=true, это самостоятельное поле. Если padding=false, это внутри UnifiedInputField
          height: widget.padding ? UnifiedInputField.fieldHeight.h : null,
          padding: EdgeInsets.only(
            left: widget.padding ? 20.w : 3.w,
            right: widget.padding ? 10.w : 3.w,
            top: widget.padding ? 18.h : 0.h,
            bottom: widget.padding ? 18.h : 0.h,
          ),
          decoration: BoxDecoration(
            borderRadius: widget.padding
                ? BorderRadius.circular(UnifiedInputField.borderRadius)
                : BorderRadius.circular(0),
            color: widget.padding
                ? UnifiedInputField.fillColor
                : Colors.transparent,
            border: widget.padding ? null : null,
          ),
        ),
        dropdownStyleData: DropdownStyleData(
          maxHeight: 250.h,
          padding: EdgeInsets.zero,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.r),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
                spreadRadius: 0,
              ),
            ],
          ),
          isOverButton: false,
          offset: Offset(0, -5.h),
          useRootNavigator: true,
          scrollbarTheme: ScrollbarThemeData(
            radius: Radius.circular(4.r),
            thickness: WidgetStateProperty.all(2),
            thumbVisibility: WidgetStateProperty.all(true),
            thumbColor: WidgetStateProperty.all(Colors.grey[300]),
          ),
        ),
        menuItemStyleData: MenuItemStyleData(
          height: 40.h,
          padding:
              EdgeInsets.only(left: widget.padding ? 28.w : 6.5.w, right: 0.w),
        ),
      ),
    );
  }
}
