class DirModel {
  final int id;
  final int parentDirID;
  final String name;
  final DateTime created;
  final DateTime updated;
  final String desc;

  DirModel({
    required this.id,
    required this.parentDirID,
    required this.name,
    required this.created,
    required this.updated,
    required this.desc,
  });

  // Factory method to create a DirModel from a Map
  factory DirModel.fromMap(int id, Map<String, dynamic> map) {
    return DirModel(
      id: id,
      parentDirID: map['parentID'] as int,
      name: map['name'] as String,
      created: DateTime.parse(map['created'] as String),
      updated: DateTime.parse(map['updated'] as String),
      desc: map['desc'] as String,
    );
  }

  // Method to convert DirModel to a Map
  Map<String, dynamic> toMap() {
    return {
      'parentID': parentDirID,
      'name': name,
      'created': created.toIso8601String(),
      'updated': updated.toIso8601String(),
      'desc': desc,
    };
  }
}
