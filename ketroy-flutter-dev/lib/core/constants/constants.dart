import 'package:flutter/material.dart';
import 'package:ketroy_app/core/common/entities/menu.dart';

class Constants {
  static final List<Menu> days = [
    for (int i = 1; i < 32; i++)
      Menu(name: '$i', value: i, image: const SizedBox())
  ];

  static final List<Menu> months = [
    for (int month = 1; month <= 12; month++)
      Menu(name: '$month', value: month, image: const SizedBox())
  ];

  static final List<Menu> years = [
    for (int year = DateTime.now().year;
        year >= DateTime.now().year - 100;
        year--)
      Menu(name: '$year', value: year, image: const SizedBox())
  ];

  static final List<Menu> heights = [
    for (int height = 4; height <= 8; height += 2)
      Menu(name: '$height', value: height, image: const SizedBox())
  ];

  static final List<Menu> shoeSize = [
    for (int i = 39; i <= 46; i++)
      Menu(name: '$i', value: i, image: const SizedBox())
  ];

  static List<Menu> clothingSizes = [
    for (int i = 46; i <= 64; i += 2)
      Menu(name: '$i', value: i, image: const SizedBox())
  ];
}

const Duration splashDuration = Duration(seconds: 2);
