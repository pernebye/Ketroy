import 'package:flutter/material.dart';
import 'package:ketroy_app/features/active_gifts/presentation/view_model/all_gifts_view_model.dart';
import 'package:ketroy_app/features/active_gifts/presentation/widgets/active_page_body.dart';
import 'package:provider/provider.dart';

class ActivaeGiftsPage extends StatelessWidget {
  const ActivaeGiftsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AllGiftsViewModel()..initialize(),
      child: const ActivePageBody(),
    );
  }
}
