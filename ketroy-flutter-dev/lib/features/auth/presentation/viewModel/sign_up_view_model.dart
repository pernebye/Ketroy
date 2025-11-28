import 'package:flutter/material.dart';

class SignUpViewModel extends ChangeNotifier {
  String _name = '';
  String _surname = '';
  // String _phoneNumber = '';
  String _code = '';
  String _phoneNumberFormat = '';
  int _selectedValue = 1;
  final TextEditingController _userNameController = TextEditingController();
  final TextEditingController _userSurnameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  String get name => _name;
  String get surname => _surname;
  // String get phoneNumber => _phoneNumber;
  String get code => _code;
  String get phoneNumberFormat => _phoneNumberFormat;
  int get selectedValue => _selectedValue;
  TextEditingController get userNameController => _userNameController;
  TextEditingController get userSurnameController => _userSurnameController;
  TextEditingController get phoneController => _phoneController;

  void setName(String value) {
    _name = value;
  }

  void setSurname(String value) {
    _surname = value;
  }

  // void setPhoneNumber(String value) {
  //   _phoneNumber = value;
  // }

  void setCode(String value) {
    _code = value;
  }

  void setPhoneNumberFormat(String value) {
    _phoneNumberFormat = value;
  }

  void setSelectedValue(int value) {
    _selectedValue = value;
    notifyListeners();
  }

  @override
  void dispose() {
    userNameController.dispose();
    userSurnameController.dispose();
    phoneController.dispose();
    super.dispose();
  }
}
