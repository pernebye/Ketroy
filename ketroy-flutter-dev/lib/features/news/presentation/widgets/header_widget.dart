// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:ketroy_app/core/theme/theme.dart';
// import 'package:ketroy_app/features/news/presentation/widgets/carousle.dart';

// const double _minHeaderExtent = 80;
// const double _maxHeaderExtent = 420;

// class HeaderWidget extends SliverPersistentHeaderDelegate {
//   @override
//   Widget build(
//       BuildContext context, double shrinkOffset, bool overlapsContent) {
//     final size = MediaQuery.of(context).size;
//     final percent = shrinkOffset / _maxHeaderExtent;

//     return SizedBox.expand(
//       child: Stack(
//         alignment: Alignment.bottomCenter,
//         children: [
//           Container(
//             color: Colors.white,
//           ),
//           (shrinkOffset < _maxHeaderExtent * 0.8)
//               ? (Positioned(
//                   child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Carousel(
//                       controller: controller,
//                       bannerList: state.banners?.data ?? [],
//                     ),
//                     SizedBox(
//                       height: 27.h,
//                     ),
//                     SingleChildScrollView(
//                       scrollDirection: Axis.horizontal,
//                       child: Row(
//                         children: [
//                           SizedBox(
//                             width: 35.w,
//                           ),
//                           Row(
//                             children: [
//                               for (int actualsLength = 0;
//                                   actualsLength < state.actuals.length;
//                                   actualsLength++)
//                                 Row(
//                                   children: [
//                                     Stories(
//                                       stories:
//                                           state.actuals[actualsLength].stories,
//                                       title: state
//                                           .actuals[actualsLength].actualGroup,
//                                     ),
//                                     SizedBox(
//                                       width: 15.w,
//                                     ),
//                                   ],
//                                 ),

//                               // Stories(actuals: ,)
//                             ],
//                           ),
//                         ],
//                       ),
//                     ),
//                     SizedBox(
//                       height: 20.h,
//                     ),
//                     Padding(
//                       padding: EdgeInsets.symmetric(horizontal: 35.w),
//                       child: Text(
//                         'Новости',
//                         style: AppTheme.newsLargeTextStyle
//                             .copyWith(fontWeight: FontWeight.bold),
//                       ),
//                     ),
//                     SizedBox(
//                       height: 20.h,
//                     ),
//                   ],
//                 )))
//               : SizedBox(),
//           SingleChildScrollView(
//             scrollDirection: Axis.horizontal,
//             child: Row(
//               children: [
//                 SizedBox(
//                   width: 35.w,
//                 ),
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     GestureDetector(
//                       onTap: () {
//                         setState(() {
//                           selectedIndex = 0;
//                           // context.read<NewsBloc>().add(
//                           //     GetNewsListFetch(
//                           //         category: state
//                           //             .categoriesList[
//                           //                 categoriesIndex]
//                           //             .name));
//                         });
//                       },
//                       child: Row(
//                         children: [
//                           Container(
//                               alignment: Alignment.center,
//                               width: 94.w,
//                               height: 41.h,
//                               decoration: BoxDecoration(
//                                   color: (selectedIndex == 0)
//                                       ? const Color(0xFF3C4B1B)
//                                       : null,
//                                   border: Border.all(),
//                                   borderRadius: BorderRadius.circular(13.r)),
//                               child: FittedBox(
//                                 fit: BoxFit.scaleDown,
//                                 child: Text(
//                                   'All',
//                                   style: AppTheme.newsMediumTextStyle.copyWith(
//                                       color: (selectedIndex == 0)
//                                           ? Colors.white
//                                           : Colors.black),
//                                 ),
//                               )),
//                           SizedBox(
//                             width: 18.w,
//                           )
//                         ],
//                       ),
//                     ),
//                     for (int categoriesIndex = 0;
//                         categoriesIndex < state.categoriesList.length;
//                         categoriesIndex++)
//                       GestureDetector(
//                         onTap: () {
//                           setState(() {
//                             selectedIndex = categoriesIndex + 1;
//                             context.read<NewsBloc>().add(GetNewsListFetch(
//                                 category: state
//                                     .categoriesList[categoriesIndex].name));
//                           });
//                         },
//                         child: Row(
//                           children: [
//                             Container(
//                                 alignment: Alignment.center,
//                                 width: 94.w,
//                                 height: 41.h,
//                                 decoration: BoxDecoration(
//                                     color:
//                                         (selectedIndex == categoriesIndex + 1)
//                                             ? const Color(0xFF3C4B1B)
//                                             : null,
//                                     border: Border.all(),
//                                     borderRadius: BorderRadius.circular(13.r)),
//                                 child: FittedBox(
//                                   fit: BoxFit.scaleDown,
//                                   child: Text(
//                                     state.categoriesList[categoriesIndex].name,
//                                     style: AppTheme.newsMediumTextStyle
//                                         .copyWith(
//                                             color: (selectedIndex ==
//                                                     categoriesIndex + 1)
//                                                 ? Colors.white
//                                                 : Colors.black),
//                                   ),
//                                 )),
//                             SizedBox(
//                               width: 18.w,
//                             )
//                           ],
//                         ),
//                       ),
//                     // Container(
//                     //     alignment: Alignment.center,
//                     //     width: 94.w,
//                     //     height: 41.h,
//                     //     decoration: BoxDecoration(
//                     //         border: Border.all(),
//                     //         borderRadius: BorderRadius.circular(13.r)),
//                     //     child: Text(
//                     //       'Акции',
//                     //       style: AppTheme.newsMediumTextStyle,
//                     //     )),
//                     // Container(
//                     //     alignment: Alignment.center,
//                     //     width: 94.w,
//                     //     height: 41.h,
//                     //     decoration: BoxDecoration(
//                     //         border: Border.all(),
//                     //         borderRadius: BorderRadius.circular(13.r)),
//                     //     child: Text(
//                     //       'Новые',
//                     //       style: AppTheme.newsMediumTextStyle,
//                     //     )),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//           SizedBox(
//             height: 20.h,
//           ),
//           if (state.newsEntity != null && state.newsEntity!.data.isNotEmpty)
//             for (int i = 0; i < state.newsEntity!.data.length; i++)
//               Padding(
//                 padding: EdgeInsets.symmetric(horizontal: 35.w),
//                 child: GestureDetector(
//                   onTap: () {
//                     Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                             builder: (context) => NewsPageDetail(
//                                 description:
//                                     state.newsEntity?.data[i].description ??
//                                         '')));
//                   },
//                   child: Column(
//                     children: [
//                       Container(
//                         height: 191.h,
//                         width: MediaQuery.of(context).size.width,
//                         decoration: BoxDecoration(
//                             borderRadius: BorderRadius.circular(21.r)),
//                         child: ClipRRect(
//                           borderRadius: BorderRadius.circular(20.r),
//                           child: Image.network(
//                               fit: BoxFit.cover,
//                               state.newsEntity?.data[i].filePath ?? ''),
//                         ),
//                       ),
//                       SizedBox(
//                         height: 20.h,
//                       ),
//                       Text(
//                         state.newsEntity?.data[i].name ?? '',
//                         style: AppTheme.newsLargeTextStyle
//                             .copyWith(fontWeight: FontWeight.bold),
//                       ),
//                       SizedBox(
//                         height: 20.h,
//                       )
//                     ],
//                   ),
//                 ),
//               )
//           else
//             SizedBox(
//               height: 500.h,
//             ),
//           SizedBox(
//             height: 100.h,
//           )
//         ],
//       ),
//     );
//   }

//   @override
//   // TODO: implement maxExtent
//   double get maxExtent => throw UnimplementedError();

//   @override
//   // TODO: implement minExtent
//   double get minExtent => throw UnimplementedError();

//   @override
//   bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
//     // TODO: implement shouldRebuild
//     throw UnimplementedError();
//   }
// }
