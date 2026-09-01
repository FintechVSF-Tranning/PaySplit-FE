import 'package:equatable/equatable.dart';

class BankEntity extends Equatable {
  const BankEntity({
    required this.name,
    required this.code,
    required this.bin,
    required this.shortName,
    required this.logoUrl,
  });

  final String name;
  final String code;
  final String bin;
  final String shortName;
  final String logoUrl;

  @override
  List<Object?> get props => [name, code, bin, shortName, logoUrl];
}
