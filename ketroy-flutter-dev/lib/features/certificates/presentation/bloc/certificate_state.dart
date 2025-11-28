part of 'certificate_bloc.dart';

enum CertificateStatus { initial, loading, success, failure }

class CertificateState extends Equatable {
  final CertificateStatus status;
  final String? city;

  const CertificateState({this.status = CertificateStatus.initial, this.city});

  @override
  List<Object?> get props => [status, city];

  bool get isInitial => status == CertificateStatus.initial;
  bool get isLoading => status == CertificateStatus.loading;
  bool get isSuccess => status == CertificateStatus.success;
  bool get isFailure => status == CertificateStatus.failure;

  CertificateState copyWith({CertificateStatus? status, String? city}) {
    return CertificateState(
        status: status ?? this.status, city: city ?? this.city);
  }
}
