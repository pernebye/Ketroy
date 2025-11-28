part of 'certificate_bloc.dart';

abstract class CertificateEvent extends Equatable {
  const CertificateEvent();

  @override
  List<Object> get props => [];
}

class LoadUserInfoFetch extends CertificateEvent {}
