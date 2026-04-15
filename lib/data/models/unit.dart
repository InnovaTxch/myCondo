import 'resident.dart';

class Unit {
  final int id;
  final String name;
  final List<Resident> members;
  Unit({
    required this.id,
    required this.name,
    required this.members
  });
}