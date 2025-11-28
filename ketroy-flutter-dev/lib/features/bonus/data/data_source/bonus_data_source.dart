import 'package:dio/dio.dart';
import 'package:ketroy_app/core/internet_services/dio_client.dart';
import 'package:ketroy_app/core/internet_services/error/dio_exception.dart';
import 'package:ketroy_app/core/internet_services/error/exceptions.dart';
import 'package:ketroy_app/core/internet_services/paths.dart';
import 'package:ketroy_app/features/bonus/data/models/bonus_programs_model.dart';

abstract interface class BonusDataSource {
  Future<List<BonusProgramsModel>> getBonusPrograms();
}

class BonusDataSourceImpl implements BonusDataSource {
  @override
  Future<List<BonusProgramsModel>> getBonusPrograms() async {
    try {
      final response = await DioClient.instance.getList(bonusPrograms);
      return response
          .map((bonusPrograms) => BonusProgramsModel.fromJson(bonusPrograms))
          .toList();
    } on DioException catch (e) {
      var error = DioExceptionService.fromDioError(e);
      throw ServerException(error.errorMessage);
    }
  }
}
