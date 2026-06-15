/// Voter data model for MY Talamudipi app.
class Voter {
  final int? id;
  final String serialNo;
  final String houseNumber;
  final String voterName;
  final String relationshipType;
  final String relationshipName;
  final int age;
  final String voterId;
  final String gender;
  final String partName;

  const Voter({
    this.id,
    required this.serialNo,
    required this.houseNumber,
    required this.voterName,
    required this.relationshipType,
    required this.relationshipName,
    required this.age,
    required this.voterId,
    required this.gender,
    this.partName = '',
  });

  factory Voter.fromMap(Map<String, dynamic> map) {
    return Voter(
      id: map['id'] as int?,
      serialNo: (map['serial_no'] ?? '').toString(),
      houseNumber: (map['house_number'] ?? '').toString(),
      voterName: (map['voter_name'] ?? '').toString(),
      relationshipType: (map['relationship_type'] ?? '').toString(),
      relationshipName: (map['relationship_name'] ?? '').toString(),
      age: _parseInt(map['age']),
      voterId: (map['voter_id'] ?? '').toString(),
      gender: (map['gender'] ?? '').toString(),
      partName: (map['part_name'] ?? '').toString(),
    );
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? 0;
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'serial_no': serialNo,
        'house_number': houseNumber,
        'voter_name': voterName,
        'relationship_type': relationshipType,
        'relationship_name': relationshipName,
        'age': age,
        'voter_id': voterId,
        'gender': gender,
        'part_name': partName,
      };
}
