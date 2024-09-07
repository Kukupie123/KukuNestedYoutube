class VidModel {
  final String videoID;
  final String link;
  final String desc;
  final DateTime created;
  final DateTime updated;
  final String title;
  final String thumbnailUrl;

  VidModel({
    required this.videoID,
    required this.link,
    required this.desc,
    required this.created,
    required this.updated,
    required this.title,
    required this.thumbnailUrl,
  });

  // You might want to add a factory method to create a VidModel from a Map
  factory VidModel.fromMap(String videoID, Map<String, dynamic> map) {
    return VidModel(
      videoID: videoID,
      link: map['link'] as String,
      desc: map['desc'] as String,
      created: DateTime.parse(map['created'] as String),
      updated: DateTime.parse(map['updated'] as String),
      title: map['title'] as String,
      thumbnailUrl: map['thumbnailUrl'] as String,
    );
  }

  // You might also want to add a method to convert the VidModel to a Map
  Map<String, dynamic> toMap() {
    return {
      'videoID': videoID,
      'link': link,
      'desc': desc,
      'created': created.toIso8601String(),
      'updated': updated.toIso8601String(),
      'title': title,
      'thumbnailUrl': thumbnailUrl,
    };
  }
}
