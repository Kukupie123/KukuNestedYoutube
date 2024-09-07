import 'dart:convert';
import 'dart:developer';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:youtube_video_info/youtube.dart';

import 'dto/dir_model.dart';
import 'dto/vid_model.dart';

class HiveDB {
  HiveDB._();

  static HiveDB instance = HiveDB._();
  late final Box dirDB;
  late final Box vidDB;
  late final Box dirVidDB;
  final dirsTable = "dir";
  final vidsTable = "vids";
  final dirVidTable = "dirVidTable";

  ///Initialize the static instance.
  Future<void> initInstance() async {
    await Hive.initFlutter();
    dirDB = await Hive.openBox(dirsTable);
    vidDB = await Hive.openBox(vidsTable);
    dirVidDB = await Hive.openBox(dirVidTable);
  }

  ///Add a new directory. If no parentID is mentioned it will be a root folder
  Future<void> addDirectory(
      {required String name, int parentID = -1, String desc = ""}) async {
    final map = {
      "name": name,
      "desc": desc,
      "parentID": parentID,
      "created": DateTime.now().toString(),
      "updated": DateTime.now().toString()
    };
    int id = dirDB.length;
    log("Adding directory ${jsonEncode(map)} with ID ${id.toString()}");
    await dirDB.put(id, map);
  }

  Future<List<DirModel>> getDirectories({int? parentDirID}) async {
    List<DirModel> dirList = [];

    final futures = dirDB.keys.map((k) async {
      final value = await dirDB.get(k);
      return DirModel.fromMap(k as int, value);
    }).toList();

    dirList = await Future.wait(futures);
    // Filter the directories if parentDirID is provided
    if (parentDirID != null) {
      dirList = dirList.where((dir) => dir.parentDirID == parentDirID).toList();
    }
    return dirList;
  }

  // Add a new video in the specified directory.
  Future<void> addVid({
    required String link,
    required int dirID,
    String desc = "",
  }) async {
    String? videoID;

    if (!dirDB.keys.contains(dirID)) {
      throw Exception("Invalid dirID. It doesn't exist");
    }

    // Extract video ID (unchanged)
    final fullUrlRegex = RegExp(r'v=([a-zA-Z0-9_-]{11})');
    final fullUrlMatch = fullUrlRegex.firstMatch(link);

    if (fullUrlMatch != null) {
      videoID = fullUrlMatch.group(1);
    } else {
      final shortUrlRegex = RegExp(r'youtu\.be/([a-zA-Z0-9_-]{11})');
      final shortUrlMatch = shortUrlRegex.firstMatch(link);

      if (shortUrlMatch != null) {
        videoID = shortUrlMatch.group(1);
      } else {
        final idRegex = RegExp(r'^[a-zA-Z0-9_-]{11}$');
        if (idRegex.hasMatch(link)) {
          videoID = link;
        }
      }
    }

    if (videoID == null) {
      throw Exception(
          'Invalid YouTube URL or video ID: Unable to extract video ID');
    }

    log("Video ID $videoID");

    // Fetch video details using youtube_explode_dart
    var yt = await YoutubeData.getData(link);

    var thumb = yt.thumbnailUrl;
    var title = yt.title;
    log("Title is $title");
    log("Title : $title");
    final map = {
      "desc": desc,
      "created": DateTime.now().toString(),
      "updated": DateTime.now().toString(),
      "link": link,
      "title": title,
      "thumbnailUrl": thumb,
    };

    log("Adding Video ${jsonEncode(map)} with videoID: $videoID");

    await vidDB.put(videoID, map);

    log("Adding Video $videoID to Dir: $dirID");
    await dirVidDB.put("$dirID;$videoID", "");
  }

  Future<List<VidModel>> getVideos({int dirID = -1}) async {
    List<VidModel> videoList = [];

    if (dirID == -1) {
      // Fetch all videos if no dirID is provided
      final allKeys = vidDB.keys.toList();
      final futures = allKeys.map((videoID) async {
        final value = await vidDB.get(videoID);
        return VidModel.fromMap(
            videoID as String, value as Map<String, dynamic>);
      }).toList();
      videoList = await Future.wait(futures);
    } else {
      // Fetch videos associated with the provided dirID
      final dirVidKeys =
          dirVidDB.keys.where((key) => key.startsWith('$dirID;')).toList();
      final futures = dirVidKeys.map((key) async {
        final videoID = key.split(';')[1]; // Extract videoID from key
        final value = await vidDB.get(videoID);
        return VidModel.fromMap(videoID, value as Map<String, dynamic>);
      }).toList();
      videoList = await Future.wait(futures);
    }

    return videoList;
  }
}
