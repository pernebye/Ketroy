import 'package:fpdart/fpdart.dart';
import 'package:ketroy_app/core/internet_services/error/failure.dart';
import 'package:ketroy_app/core/usecase/usecase.dart';
import 'package:ketroy_app/features/news/domain/entities/actuals_entity.dart';
import 'package:ketroy_app/features/news/domain/repository/news_repository.dart';

class GetActuals implements UseCase<List<ActualsEntity>, GetActualsParams> {
  final NewsRepository newsRepository;

  GetActuals(this.newsRepository);
  @override
  Future<Either<Failure, List<ActualsEntity>>> call(
      GetActualsParams params, String? path) async {
    return await newsRepository.getActuals(city: params.city);
  }
}

class GetActualsParams {
  final String city;

  GetActualsParams({required this.city});
}
