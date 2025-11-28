import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:ketroy_app/services/local_storage/user_data_manager.dart';

part 'certificate_events.dart';
part 'certificate_state.dart';

class CertificateBloc extends Bloc<CertificateEvent, CertificateState> {
  CertificateBloc() : super(const CertificateState()) {
    on<LoadUserInfoFetch>(_loadUserinfoFetch);
  }

  Future<void> _loadUserinfoFetch(
      LoadUserInfoFetch event, Emitter<CertificateState> emit) async {
    final user = await UserDataManager.getUser();
    final city = user?.city;
    emit(state.copyWith(city: city));
  }
}
