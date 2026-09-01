import '../../domain/entities/bank_entity.dart';

class BankModel {
  const BankModel({
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

  factory BankModel.fromJson(Map<String, dynamic> json) {
    final rawLogo = json['logo'] as String? ?? '';
    final normalizedLogo = rawLogo.replaceAll(
      'https://cdn.vietqr.io/',
      'https://api.vietqr.io/',
    );
    return BankModel(
      name: json['name'] as String,
      code: json['code'] as String,
      bin: json['bin'] as String,
      shortName: json['short_name'] as String,
      logoUrl: normalizedLogo,
    );
  }

  BankEntity toEntity() => BankEntity(
    name: name,
    code: code,
    bin: bin,
    shortName: shortName,
    logoUrl: logoUrl,
  );
}
