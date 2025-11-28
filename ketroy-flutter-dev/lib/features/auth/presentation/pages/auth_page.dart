// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:flutter_svg/svg.dart';
// import 'package:ketroy_app/core/common/entities/menu.dart';
// import 'package:ketroy_app/core/theme/app_pallete.dart';
// import 'package:ketroy_app/core/theme/theme.dart';
// import 'package:ketroy_app/core/common/widgets/app_button.dart';
// import 'package:ketroy_app/core/common/widgets/dropdown_button.dart';
// import 'package:ketroy_app/features/auth/presentation/bloc/auth_bloc.dart';

// class AuthPage extends StatefulWidget {
//   const AuthPage({super.key});

//   @override
//   State<AuthPage> createState() => _AuthPageState();
// }

// class _AuthPageState extends State<AuthPage> {
//   final List<Menu> itemsSkud = [
//     Menu(name: '+7', value: 1, image: Image.asset('images/kz.png')),
//     Menu(name: '+8', value: 2, image: Image.asset('images/rus.png')),
//     Menu(name: '+90', value: 3, image: Image.asset('images/tur.png')),
//   ];

//   int selectedValue = 1;

//   @override
//   void initState() {
//     super.initState();
//     context.read<AuthBloc>().add(CountryCodesFetch());
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: AppPallete.authBackColor,
//       body: Stack(
//         children: [
//           Row(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               SvgPicture.asset('images/logoK.svg'),
//             ],
//           ),
//           Padding(
//             padding: EdgeInsets.symmetric(horizontal: 34.w),
//             child: Column(
//               children: [
//                 SizedBox(
//                   height: 250.h,
//                 ),
//                 Text(
//                   'Добро пожаловать!',
//                   style: AppTheme.authTitleTextStyle,
//                 ),
//                 SizedBox(
//                   height: 20.h,
//                 ),
//                 Text(
//                   textAlign: TextAlign.center,
//                   'Пожалуйста зарегистрируйтесь чтобы получить полный доступ к магазину',
//                   style: AppTheme.authHintTextStyle,
//                 ),
//                 SizedBox(
//                   height: 20.h,
//                 ),
//                 TextFormField(
//                   decoration:
//                       const InputDecoration(hintText: 'Имя пользователя'),
//                 ),
//                 SizedBox(
//                   height: 20.h,
//                 ),
//                 Row(
//                   children: [
//                     SizedBox(
//                       width: 80.w,
//                       child: DropdownButtonCustom(
//                           items: itemsSkud,
//                           selectedValue: selectedValue,
//                           onChanged: (value) {},
//                           hintTitle: itemsSkud[0].name),
//                     ),
//                     SizedBox(
//                       width: 6.w,
//                     ),
//                     Expanded(child: TextFormField())
//                   ],
//                 ),
//                 SizedBox(
//                   height: 21.h,
//                 ),
//                 Row(
//                   children: [
//                     Expanded(
//                         child: AppButton(
//                             title: 'Зарегистрироваться',
//                             color: Colors.black,
//                             pressAction: () {})),
//                   ],
//                 ),
//                 SizedBox(
//                   height: 20.h,
//                 ),
//                 RichText(
//                     textAlign: TextAlign.center,
//                     text: TextSpan(
//                       children: [
//                         TextSpan(
//                             text:
//                                 'Нажав "Зарегистрироваться", вы соглашаетесь с ',
//                             style: AppTheme.regularText),
//                         TextSpan(
//                             text: 'Условиями использования',
//                             style: AppTheme.underLineWords),
//                         TextSpan(text: ' и ', style: AppTheme.regularText),
//                         TextSpan(
//                             text: 'Политикой конфиденциальности',
//                             style: AppTheme.underLineWords)
//                       ],
//                     )),
//                 SizedBox(
//                   height: 20.h,
//                 ),
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Text(
//                       'Уже есть аккаунт?',
//                       style: AppTheme.haveAccount,
//                     ),
//                     Text(
//                       ' Войти',
//                       style: AppTheme.haveAccount
//                           .copyWith(fontWeight: FontWeight.bold),
//                     )
//                   ],
//                 )
//               ],
//             ),
//           )
//         ],
//       ),
//     );
//   }
// }

// class MenuItem {
//   const MenuItem({
//     required this.text,
//     required this.icon,
//   });

//   final String text;
//   final IconData icon;
// }

// abstract class MenuItems {
//   static const List<MenuItem> firstItems = [home, share, settings];
//   // static const List<MenuItem> secondItems = [logout];

//   static const home = MenuItem(text: 'Home', icon: Icons.home);
//   static const share = MenuItem(text: 'Share', icon: Icons.share);
//   static const settings = MenuItem(text: 'Settings', icon: Icons.settings);
//   // static const logout = MenuItem(text: 'Log Out', icon: Icons.logout);

//   static Widget buildItem(MenuItem item) {
//     return Row(
//       children: [
//         Icon(item.icon, color: Colors.white, size: 22),
//         const SizedBox(
//           width: 10,
//         ),
//         Expanded(
//           child: Text(
//             item.text,
//             style: const TextStyle(
//               color: Colors.white,
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   static void onChanged(BuildContext context, MenuItem item) {
//     switch (item) {
//       case MenuItems.home:
//         //Do something
//         break;
//       case MenuItems.settings:
//         //Do something
//         break;
//       case MenuItems.share:
//         //Do something
//         break;
//       // case MenuItems.logout:
//       //   //Do something
//       //   break;
//     }
//   }
// }
