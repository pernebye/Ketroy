import 'package:fpdart/fpdart.dart';
import 'package:ketroy_app/core/internet_services/error/exceptions.dart';
import 'package:ketroy_app/core/internet_services/error/failure.dart';
import 'package:ketroy_app/features/partners/data/data_source/partners_data_source.dart';
import 'package:ketroy_app/features/partners/domain/repository/partners_repository.dart';

class PartnersRepositoryImpl implements PartnersRepository {
  final PartnersDataSource partnersDataSource;

  PartnersRepositoryImpl({required this.partnersDataSource});

  @override
  Future<Either<Failure, String>> getAmountData() async {
    return _getAmountData(() async => await partnersDataSource.getAmountData());
  }

  Future<Either<Failure, String>> _getAmountData(
      Future<String> Function() fn) async {
    try {
      final data = await fn();
      return right(data);
    } on ServerException catch (e) {
      return left(Failure(e.message));
    }
  }
}
