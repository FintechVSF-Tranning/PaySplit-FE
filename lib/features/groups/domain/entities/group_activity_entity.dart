import 'package:equatable/equatable.dart';

/// Thể loại sự kiện, quyết định màu chấm mốc trên timeline hoạt động nhóm.
enum GroupActivityKind { bill, payment, member, system }

/// Một sự kiện trong dòng hoạt động của nhóm.
class GroupActivityEntity extends Equatable {
  const GroupActivityEntity({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.timeText,
    required this.kind,
  });

  final String id;
  final String title;
  final String subtitle;
  final String timeText;
  final GroupActivityKind kind;

  @override
  List<Object?> get props => [id, title, subtitle, timeText, kind];
}
