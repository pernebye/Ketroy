import 'package:fpdart/fpdart.dart';
import 'package:ketroy_app/core/internet_services/error/failure.dart';
import 'package:ketroy_app/core/usecase/usecase.dart';
import 'package:ketroy_app/features/partners/domain/repository/partners_repository.dart';

class GetAmount implements UseCase<String, NoParams> {
  final PartnersRepository partnersRepository;

  GetAmount({required this.partnersRepository});
  @override
  Future<Either<Failure, String>> call(NoParams params, String? path) async {
    return await partnersRepository.getAmountData();
  }
}
