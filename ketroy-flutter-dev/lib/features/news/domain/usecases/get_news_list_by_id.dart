import 'package:fpdart/fpdart.dart';
import 'package:ketroy_app/core/internet_services/error/failure.dart';
import 'package:ketroy_app/core/usecase/usecase.dart';
import 'package:ketroy_app/features/news/domain/entities/news_list_entity.dart';
import 'package:ketroy_app/features/news/domain/repository/news_repository.dart';

class GetNewsListById implements UseCase<NewsListEntity, NewsIdParams> {
  final NewsRepository newsRepository;
  GetNewsListById(this.newsRepository);
  @override
  Future<Either<Failure, NewsListEntity>> call(
      NewsIdParams params, String? path) async {
    return await newsRepository.getNewsById(id: params.id);
  }
}

class NewsIdParams {
  final int id;

  NewsIdParams({required this.id});
}
