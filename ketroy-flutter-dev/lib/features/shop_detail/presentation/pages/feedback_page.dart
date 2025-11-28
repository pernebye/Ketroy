import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:ketroy_app/core/common/widgets/app_button.dart';
import 'package:ketroy_app/core/theme/theme.dart';
import 'package:ketroy_app/core/widgets/loader.dart';
import 'package:ketroy_app/features/shop_detail/presentation/bloc/shop_detail_bloc.dart';
import 'package:ketroy_app/features/shop_detail/presentation/pages/feedback_sent.dart';

class FeedbackPage extends StatefulWidget {
  final int id;
  final String userId;
  const FeedbackPage({super.key, required this.id, required this.userId});

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  @override
  void initState() {
    super.initState();
    context.read<ShopDetailBloc>().add(GetShopReviewFetch(shopId: widget.id));
  }

  Future<void> _navigateAndFetchReviews() async {
    await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => FeedbackSent(
                  id: widget.id,
                  userId: widget.userId,
                )));

    // Проверяем, что виджет всё ещё смонтирован
    if (!mounted) return;

    // После возврата с экрана отправляем событие для загрузки отзывов
    context.read<ShopDetailBloc>().add(GetShopReviewFetch(shopId: widget.id));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        backgroundColor: Colors.white,
      ),
      body: BlocConsumer<ShopDetailBloc, ShopDetailState>(
        listener: (context, state) {},
        builder: (context, state) {
          if (state.isSuccess) {
            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 18.w),
              child: Column(
                children: [
                  // const Row(
                  //   children: [
                  //     CustomBackButton(),
                  //   ],
                  // ),
                  SizedBox(
                    height: 20.h,
                  ),
                  Row(
                    children: [
                      Text(
                        'Отзывы',
                        style: AppTheme.shopLargeTextStyle.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 20.h,
                  ),
                  for (int i = 0; i < state.shopReviewList.length; i++)
                    Column(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 9.w,
                            vertical: 16.h,
                          ),
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20.r),
                              color: Colors.black),
                          child: Column(
                            children: [
                              Text(
                                'Недавнее отзывы',
                                style: AppTheme.shopLargeTextStyle.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white),
                              ),
                              SizedBox(
                                height: 11.h,
                              ),
                              Container(
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16.r),
                                    color: Colors.white),
                                padding: EdgeInsets.only(
                                    left: 29.w,
                                    right: 17.w,
                                    top: 11.h,
                                    bottom: 11.h),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(40.r),
                                                child: Image.asset(
                                                    'images/profile1.png')),
                                            SizedBox(
                                              width: 6.w,
                                            ),
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  state.shopReviewList[i].user
                                                      .name,
                                                  style: AppTheme
                                                      .feedbackMediumTextStyle
                                                      .copyWith(
                                                          fontWeight:
                                                              FontWeight.bold),
                                                ),
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.start,
                                                  children: [
                                                    for (int j = 0;
                                                        j <
                                                            state
                                                                .shopReviewList[
                                                                    i]
                                                                .rating;
                                                        j++)
                                                      Row(
                                                        children: [
                                                          SvgPicture.asset(
                                                              'images/Star.svg'),
                                                          SizedBox(
                                                            width: 3.w,
                                                          )
                                                        ],
                                                      ),
                                                  ],
                                                )
                                              ],
                                            ),
                                          ],
                                        ),
                                        Text(
                                          DateFormat('dd.MM.yyyy').format(state
                                              .shopReviewList[i].createdAt),
                                          style:
                                              AppTheme.feedbackSmallTextStyle,
                                        )
                                      ],
                                    ),
                                    SizedBox(
                                      height: 6.h,
                                    ),
                                    Text(
                                      state.shopReviewList[i].review,
                                      style: AppTheme.feedbackMediumTextStyle
                                          .copyWith(
                                              fontWeight: FontWeight.w300),
                                    )
                                  ],
                                ),
                              )
                            ],
                          ),
                        ),
                        SizedBox(
                          height: 20.h,
                        )
                      ],
                    ),
                  AppButton(
                      title: 'Написать отзыв',
                      backgroundColor: Colors.black,
                      onPressed: () {
                        _navigateAndFetchReviews();
                      }),
                  SizedBox(
                    height: 20.h,
                  )
                ],
              ),
            );
          }
          return const Loader();
        },
      ),
    );
  }
}
