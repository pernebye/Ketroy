import 'package:fpdart/fpdart.dart';
import 'package:ketroy_app/core/internet_services/error/failure.dart';

abstract interface class PartnersRepository {
  Future<Either<Failure, String>> getAmountData();
}
