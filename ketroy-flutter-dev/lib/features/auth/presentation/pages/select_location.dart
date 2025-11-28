// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:ketroy_app/core/common/entities/menu.dart';
// import 'package:ketroy_app/core/common/widgets/app_button.dart';
// import 'package:ketroy_app/core/common/widgets/dropdown_button.dart';
// import 'package:ketroy_app/core/constants/constants.dart';
// import 'package:ketroy_app/core/theme/app_pallete.dart';
// import 'package:ketroy_app/core/theme/theme.dart';
// import 'package:ketroy_app/features/auth/presentation/pages/post_users_info_page.dart';

// class SelectLocation extends StatefulWidget {
//   const SelectLocation({super.key});

//   @override
//   State<SelectLocation> createState() => _SelectLocationState();
// }

// class _SelectLocationState extends State<SelectLocation> {
//   final List<Menu> itemsSkud = [
//     Menu(name: 'Выберите город', value: 1, image: const SizedBox()),
//     Menu(name: 'Рост', value: 2, image: const SizedBox()),
//     Menu(name: 'Размер одежды', value: 2, image: const SizedBox())
//   ];

//   int? selectedValue;
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: AppPallete.authBackColor,
//       body: Padding(
//         padding: EdgeInsets.symmetric(horizontal: 35.w),
//         child: Column(
//           children: [
//             SizedBox(
//               height: 235.h,
//             ),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Text(
//                   'Еще немного',
//                   style: AppTheme.authTitleTextStyle,
//                 ),
//               ],
//             ),
//             SizedBox(
//               height: 10.h,
//             ),
//             Text(
//               textAlign: TextAlign.center,
//               'Пожалуйста, предоставьте актуальные данные, чтобы мы могли подобрать для вас оптимальный вариант одежды.',
//               style:
//                   AppTheme.regularText.copyWith(color: AppPallete.halfOpacity),
//             ),
//             SizedBox(
//               height: 20.h,
//             ),
//             DropdownButtonCustom(
//                 padding: true,
//                 items: Constants.clothingSizes,
//                 selectedValue: selectedValue,
//                 onChanged: (value) {},
//                 hintTitle: 'Выберите город'),
//             SizedBox(
//               height: 20.h,
//             ),
//             Row(
//               children: [
//                 Expanded(
//                     child: AppButton(
//                         title: 'Далее',
//                         color: Colors.black,
//                         pressAction: () {
//                           Navigator.push(
//                               context,
//                               MaterialPageRoute(
//                                   builder: (context) => PostUsersInfoPage()));
//                         })),
//               ],
//             )
//           ],
//         ),
//       ),
//     );
//   }
// }
