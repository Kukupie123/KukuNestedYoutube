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
}
