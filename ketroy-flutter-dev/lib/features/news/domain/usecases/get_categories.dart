import 'package:fpdart/fpdart.dart';
import 'package:ketroy_app/core/internet_services/error/failure.dart';
import 'package:ketroy_app/core/usecase/usecase.dart';
import 'package:ketroy_app/features/news/domain/entities/categories_entity.dart';
import 'package:ketroy_app/features/news/domain/repository/news_repository.dart';

class GetCategories implements UseCase<List<CategoriesEntity>, NoParams> {
  final NewsRepository newsRepository;
  GetCategories(this.newsRepository);

  @override
  Future<Either<Failure, List<CategoriesEntity>>> call(
      NoParams params, String? path) async {
    return await newsRepository.getCategoriesList();
  }
}
