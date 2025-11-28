import 'package:fpdart/fpdart.dart';
import 'package:ketroy_app/core/internet_services/error/failure.dart';
import 'package:ketroy_app/core/usecase/usecase.dart';
import 'package:ketroy_app/features/news/domain/repository/news_repository.dart';

class PostDeviceToken implements UseCase<String, PostDeviceTokenParams> {
  final NewsRepository newsRepository;

  PostDeviceToken({required this.newsRepository});
  @override
  Future<Either<Failure, String>> call(
      PostDeviceTokenParams params, String? path) async {
    return await newsRepository.postDeviceToken(token: params.token);
  }
}

class PostDeviceTokenParams {
  final String token;

  PostDeviceTokenParams({required this.token});
}
