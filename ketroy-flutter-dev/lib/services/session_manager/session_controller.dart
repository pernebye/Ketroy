// import 'package:intl/intl.dart';
// import 'package:ketroy_app/features/auth/domain/entities/register_user_entity.dart';
// import 'package:ketroy_app/features/auth/domain/entities/user_entity.dart';
// import 'package:ketroy_app/services/local_storage.dart';

// class SessionController {
//   final LocalStorage localStorage = LocalStorage();

//   Future<void> saveUserData(AuthUserEntity? user) async {
//     localStorage.setValue('name', user?.name ?? '');
//     localStorage.setValue('id', user?.id.toString() ?? '');
//     localStorage.setValue('phoneNumber', user?.phone ?? '');
//     localStorage.setValue('avatar', user?.avatarImage ?? '');
//     localStorage.setValue('city', user?.city ?? '');
//     localStorage.setValue(
//         'birthDay',
//         (user?.birthdate != null)
//             ? DateFormat('dd.MM.yyyy').format(user!.birthdate!)
//             : '');
//     localStorage.setValue('height', user?.height ?? '');
//     localStorage.setValue('clothingSize', user?.clothingSize ?? '');
//     localStorage.setValue('shoeSize', user?.shoeSize ?? '');
//     localStorage.setValue('surname', user?.surname ?? '');
//   }

//   // Future<void> saveProfileData(ProfileUserEntity? user) async {
//   //   localStorage.setValue('name', user?.name ?? '');
//   //   localStorage.setValue('id', user?.id.toString() ?? '');
//   //   localStorage.setValue('phoneNumber', user?.phone ?? '');
//   //   localStorage.setValue('avatar', user?.avatarImage ?? '');
//   //   localStorage.setValue('city', user?.city ?? '');
//   //   localStorage.setValue(
//   //       'birthDay',
//   //       (user?.birthdate != null)
//   //           ? DateFormat('dd.MM.yyyy')
//   //               .format(DateTime.parse(user?.birthdate ?? ''))
//   //           : '');
//   //   localStorage.setValue('height', user?.height ?? '');
//   //   localStorage.setValue('clothingSize', user?.clothingSize ?? '');
//   //   localStorage.setValue('shoeSize', user?.shoeSize ?? '');
//   //   localStorage.setValue('surname', user?.surname ?? '');
//   //   localStorage.setValue('countryCode', user?.countryCode ?? '');
//   //   localStorage.setValue('verificationCode', user?.verificationCode ?? '');
//   //   localStorage.setValue(
//   //       'expire',
//   //       (user?.codeExpiresAt != null)
//   //           ? DateFormat('dd.MM.yyyy')
//   //               .format(DateTime.parse(user!.codeExpiresAt ?? ''))
//   //           : '');
//   //   localStorage.setValue(
//   //       'created',
//   //       (user?.createdAt != null)
//   //           ? DateFormat('dd.MM.yyyy')
//   //               .format(DateTime.parse(user!.createdAt ?? ''))
//   //           : '');
//   //   localStorage.setValue(
//   //       'updated',
//   //       (user?.updatedAt != null)
//   //           ? DateFormat('dd.MM.yyyy')
//   //               .format(DateTime.parse(user!.updatedAt ?? ''))
//   //           : '');
//   //   localStorage.setValue('deviceToken', user?.deviceToken ?? '');
//   // }

//   Future<void> saveToken(String token) async {
//     localStorage.setValue('token', token);
//   }

//   Future<void> saveAuthUserInfo(AuthUserEntity userData) async {
//     localStorage.setValue('id', userData.id.toString());
//     localStorage.setValue('name', userData.name);
//     localStorage.setValue('phone', userData.phone);
//     localStorage.setValue('avatarImage', userData.avatarImage ?? '');
//     localStorage.setValue('countryCode', userData.countryCode);
//     localStorage.setValue('city', userData.city);
//     localStorage.setValue(
//         'birthDay',
//         (userData.birthdate != null)
//             ? DateFormat('dd.MM.yyyy').format(userData.birthdate!)
//             : '');
//     localStorage.setValue('height', userData.height);
//     localStorage.setValue('clothingSize', userData.clothingSize);
//     localStorage.setValue('shoeSize', userData.shoeSize);
//     localStorage.setValue('verificationCode', userData.verificationCode);
//     localStorage.setValue(
//         'expire',
//         (userData.codeExpires != null)
//             ? DateFormat('dd.MM.yyyy').format(userData.codeExpires!)
//             : '');
//     localStorage.setValue(
//         'created',
//         (userData.createdAt != null)
//             ? DateFormat('dd.MM.yyyy').format(userData.createdAt!)
//             : '');
//     localStorage.setValue(
//         'updated',
//         (userData.updatedAt != null)
//             ? DateFormat('dd.MM.yyyy').format(userData.updatedAt!)
//             : '');
//     localStorage.setValue('surname', userData.surname);
//     localStorage.setValue('discount', userData.discount.toString());
//     localStorage.setValue('usedPromoCode', userData.userPromoCode.toString());
//     localStorage.setValue('referredId', userData.referrerId.toString());
//     localStorage.setValue('bonus', userData.bonusAmount.toString());
//     localStorage.setValue('promoCode', userData.promoCode?.code ?? '');
//   }

//   Future<void> saveRegisterUserInfo(RegisterUserEntity userData) async {
//     localStorage.setValue('id', userData.id.toString());
//     localStorage.setValue('name', userData.name);
//     localStorage.setValue('phone', userData.phone);
//     localStorage.setValue('countryCode', userData.countryCode);
//     localStorage.setValue('city', userData.city);
//     localStorage.setValue(
//         'birthDay',
//         (userData.birthdate != null)
//             ? DateFormat('dd.MM.yyyy').format(userData.birthdate!)
//             : '');
//     localStorage.setValue('height', userData.height);
//     localStorage.setValue('clothingSize', userData.clothingSize);
//     localStorage.setValue('shoeSize', userData.shoeSize);
//     localStorage.setValue(
//         'created',
//         (userData.createdAt != null)
//             ? DateFormat('dd.MM.yyyy').format(userData.createdAt!)
//             : '');
//     localStorage.setValue(
//         'updated',
//         (userData.updatedAt != null)
//             ? DateFormat('dd.MM.yyyy').format(userData.updatedAt!)
//             : '');
//     localStorage.setValue('surname', userData.surname);
//     localStorage.setValue('discount', userData.discount.toString());
//     localStorage.setValue('bonus', userData.bonusAmount.toString());
//     localStorage.setValue('usedPromoCode', userData.usedPromoCode.toString());
//   }

//   Future<void> saveQrToken(String token) async {
//     localStorage.setValue('tokenQr', token);
//   }

//   Future<void> saveUserImage(String userImage) async {
//     localStorage.setValue('avatarImage', userImage);
//   }

//   Future<void> saveUserName(String name) async {
//     localStorage.setValue('name', name);
//   }

//   Future<void> deleteAllData() async {
//     localStorage.clearAllValue();
//   }
// }
