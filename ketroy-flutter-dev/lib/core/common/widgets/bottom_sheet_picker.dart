import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ketroy_app/core/common/entities/menu.dart';
import 'package:ketroy_app/l10n/app_localizations.dart';

class CountryCodeBottomSheetPicker extends StatelessWidget {
  final List<Menu> items;
  final int? selectedValue;
  final Function(int?) onChanged;
  final String hintTitle;

  const CountryCodeBottomSheetPicker({
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
            selectedValue ?? (items.isNotEmpty ? items[0].value : 0);

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
                  // Верхняя панель
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
                  // Picker
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
                      children: items.map((item) {
                        return Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                height: 17.sp,
                                child: item.image,
                              ),
                              SizedBox(width: 8.w),
                              Text(
                                item.name,
                                style: TextStyle(
                                  fontSize: 17.sp,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
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
        height: 56.h,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(13.r),
        ),
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (selectedItem != null)
                    SizedBox(
                      height: 17.sp,
                      child: selectedItem.image,
                    ),
                  SizedBox(width: selectedItem != null ? 4.w : 0),
                  Expanded(
                    child: Text(
                      selectedItem?.name ?? hintTitle,
                      style: TextStyle(
                        fontSize: 15.sp,
                        color: selectedItem != null
                            ? const Color(0xFF212121)
                            : const Color(0xFF212121).withValues(alpha: 0.5),
                        fontWeight: FontWeight.w400,
                      ),
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.only(left: 4.w),
              child: Icon(
                Icons.arrow_drop_down,
                color: Colors.grey[600],
                size: 22.sp,
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
    for (var item in this) {
      if (test(item)) {
        return item;
      }
    }
    return null;
  }
}
