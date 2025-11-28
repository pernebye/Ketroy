import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:ketroy_app/core/theme/theme.dart';

class Certificate extends StatefulWidget {
  const Certificate(
      {super.key, required this.price, required this.sendCertificate});

  final String price;
  final bool sendCertificate;

  @override
  State<Certificate> createState() => _CertificateState();
}

class _CertificateState extends State<Certificate>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation _animation;
  AnimationStatus _status = AnimationStatus.dismissed;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 1));
    _animation = Tween(end: 1.0, begin: 0.0).animate(_controller)
      ..addListener(() {
        setState(() {});
      })
      ..addStatusListener((status) {
        _status = status;
      });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(color: Colors.white, boxShadow: [
        BoxShadow(
          color:
              Colors.black.withValues(alpha: 0.1), // Цвет тени с прозрачностью
          spreadRadius: 1, // Распределение тени
          blurRadius: 3, // Радиус размытия
          offset: const Offset(0, 0), // Смещение тени по оси x и y
        ),
      ]),
      child: Transform(
        alignment: FractionalOffset.center,
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.0015)
          ..rotateY(pi * _animation.value),
        child: GestureDetector(
          onTap: () {
            if (!widget.sendCertificate) {
              if (_status == AnimationStatus.dismissed) {
                _controller.forward();
              } else {
                _controller.reverse();
              }
            }
          },
          child: _animation.value <= 0.5
              ? Container(
                  padding: EdgeInsets.symmetric(horizontal: 35.w),
                  decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFF3C4B1B))),
                  child: Column(
                    children: [
                      SizedBox(
                        height: 24.8.h,
                      ),
                      SvgPicture.asset('images/ketroy-logo.svg'),
                      SizedBox(
                        height: 15.h,
                      ),
                      SvgPicture.asset('images/ketroy-word.svg'),
                      Text(
                        'ПОДАРОЧНЫЙ СЕРТИФИКАТ',
                        style: AppTheme.certificateMediumTextStyle
                            .copyWith(fontWeight: FontWeight.w300),
                      ),
                      SizedBox(
                        width: 170.w,
                        child: Divider(
                          thickness: 1.h,
                          color: const Color(0xFF3C4B1B),
                        ),
                      ),
                      Text(
                        widget.price,
                        style: AppTheme.certificatePriceTextStyle
                            .copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Скидки и акции в магазине не распространяются на подарочный сертификат',
                        style: AppTheme.certificateSmallTextStyle
                            .copyWith(color: const Color(0xFF3A4623)),
                      ),
                      SizedBox(
                        height: 26.h,
                      )
                    ],
                  ),
                )
              : Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: Column(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Transform.scale(
                              scaleX: -1,
                              child: const Text('От: Антона Антоновича')),
                          SizedBox(
                            height: 9.h,
                          ),
                          Transform.scale(
                              scaleX: -1,
                              child: const Text('От: Антона Антоновича')),
                          SizedBox(
                            height: 9.h,
                          ),
                          Transform.scale(
                              scaleX: -1,
                              child: const Text(
                                  'Желаю счастья, с днем рождения. Одевайся модно!')),
                          SizedBox(
                            height: 9.h,
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(
                              child: Transform.scale(
                            scaleX: -1,
                            child: Image.asset(
                                fit: BoxFit.cover, 'images/bar.png'),
                          )),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Transform.scale(
                              scaleX: -1, child: const Text('до 15.12.2033')),
                        ],
                      )
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
