import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ketroy_app/core/common/entities/menu.dart';
import 'package:ketroy_app/core/common/widgets/unified_input_field.dart';
import 'package:ketroy_app/l10n/app_localizations.dart';

class MenuBottomSheetPicker extends StatelessWidget {
  final List<Menu> items;
  final int? selectedValue;
  final ValueChanged<int?> onChanged;
  final String hintTitle;

  const MenuBottomSheetPicker({
    super.key,
    required this.items,
    required this.selectedValue,
    required this.onChanged,
    required this.hintTitle,
  });

  void _showBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        int tempValue =
            selectedValue ?? (items.isNotEmpty ? items.first.value : 0);

        return StatefulBuilder(
          builder: (context, setModalState) {
            final l10n = AppLocalizations.of(context)!;
            return Container(
              height: MediaQuery.of(context).size.height * 0.5,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20.r),
                  topRight: Radius.circular(20.r),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            l10n.cancel,
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 16.sp,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            onChanged(tempValue);
                            Navigator.pop(context);
                          },
                          child: Text(
                            l10n.done,
                            style: TextStyle(
                              color: Colors.blue,
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: CupertinoPicker(
                      scrollController: FixedExtentScrollController(
                        initialItem: items
                            .indexWhere((item) => item.value == selectedValue),
                      ),
                      itemExtent: 40.h,
                      onSelectedItemChanged: (index) {
                        setModalState(() {
                          tempValue = items[index].value;
                        });
                      },
                      children: items
                          .map(
                            (item) => Center(
                              child: Text(
                                item.name,
                                style: TextStyle(
                                  fontSize: 17.sp,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedItem = items.firstWhereOrNull(
      (item) => item.value == selectedValue,
    );

    return GestureDetector(
      onTap: () => _showBottomSheet(context),
      child: Container(
        height: UnifiedInputField.fieldHeight.h,
        decoration: BoxDecoration(
          color: UnifiedInputField.fillColor,
          borderRadius: BorderRadius.circular(UnifiedInputField.borderRadius),
        ),
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 18.h),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                selectedItem?.name ?? hintTitle,
                style: selectedItem != null
                    ? UnifiedInputField.textStyle
                    : UnifiedInputField.hintStyle,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Padding(
              padding: EdgeInsets.only(left: 8.w),
              child: Icon(
                Icons.arrow_drop_down,
                color: Colors.grey[600],
                size: 24.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension on List<Menu> {
  Menu? firstWhereOrNull(bool Function(Menu) test) {
    for (final item in this) {
      if (test(item)) return item;
    }
    return null;
  }
}
