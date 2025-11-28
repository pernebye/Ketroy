import 'package:dio/dio.dart';
import 'package:ketroy_app/core/internet_services/dio_client.dart';
import 'package:ketroy_app/core/internet_services/error/dio_exception.dart';
import 'package:ketroy_app/core/internet_services/error/exceptions.dart';
import 'package:ketroy_app/core/internet_services/paths.dart';

abstract interface class PartnersDataSource {
  Future<String> getAmountData();
}

class PartnersDataSourceImpl implements PartnersDataSource {
  @override
  Future<String> getAmountData() async {
    try {
      final response = await DioClient.instance.get(usersAmountUrl);
      return response['amount'].toString();
    } on DioException catch (e) {
      var error = DioExceptionService.fromDioError(e);
      throw ServerException(error.errorMessage);
    }
  }
}
