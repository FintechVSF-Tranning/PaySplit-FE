import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/auth_repository.dart';

@injectable
class UploadAvatarUseCase implements UseCase<String, UploadAvatarParams> {
  UploadAvatarUseCase(this._repository);

  final AuthRepository _repository;

  @override
  Future<Either<Failure, String>> call(UploadAvatarParams params) {
    return _repository.uploadAvatar(
      avatar: params.avatar,
      bytes: params.bytes,
      filename: params.filename,
    );
  }
}

class UploadAvatarParams extends Equatable {
  const UploadAvatarParams({
    this.avatar,
    this.bytes,
    this.filename,
  });

  final File? avatar;
  final List<int>? bytes;
  final String? filename;

  @override
  List<Object?> get props => [avatar?.path, bytes?.length, filename];
}
