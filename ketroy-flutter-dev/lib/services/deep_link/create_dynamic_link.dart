import 'package:chottu_link/chottu_link.dart';
import 'package:chottu_link/dynamic_link/cl_dynamic_link_behaviour.dart';
import 'package:chottu_link/dynamic_link/cl_dynamic_link_parameters.dart';
import 'package:flutter/material.dart';

class KetroyDynamicLinksCallback {
  /// Создание пригласительной ссылки
  static void createInviteLink({
    required String referralCode,
    required Function(String link) onSuccess,
    required Function(String error) onError,
  }) {
    final parameters = CLDynamicLinkParameters(
      link:
          Uri.parse("https://ketroy-shop.chottu.link/invite?ref=$referralCode"),
      domain: "ketroy-shop.chottu.link",
      androidBehaviour: CLDynamicLinkBehaviour.app,
      iosBehaviour: CLDynamicLinkBehaviour.app,
      linkName: "invite_$referralCode",
      socialTitle: "Присоединяйтесь к Ketroy Shop!",
      socialDescription: "Получите бонусы при регистрации по этой ссылке",
    );

    ChottuLink.createDynamicLink(
      parameters: parameters,
      onSuccess: (link) {
        debugPrint("✅ Invite link created: $link");
        onSuccess(link);
      },
      onError: (error) {
        debugPrint("❌ Error creating invite link: ${error.description}");
        onError(error.description ?? 'Unknown error');
      },
    );
  }
}
