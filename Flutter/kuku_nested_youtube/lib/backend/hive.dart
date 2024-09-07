import 'dart:convert';
import 'dart:developer';

import 'package:hive_flutter/hive_flutter.dart';

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

  Future<List<DirModel>> getDirectories() async {
    List<DirModel> dirList = [];

    final futures = dirDB.keys.map((k) async {
      final value = await dirDB.get(k);

      // Ensure proper casting/parsing of data
      final parentID = value["parentID"] as int;
      final name = value["name"] as String;

      // Parse datetime strings into DateTime objects
      final createdString = value["created"] as String;
      final updatedString = value["updated"] as String;
      final created = DateTime.tryParse(createdString) ?? DateTime.now();
      final updated = DateTime.tryParse(updatedString) ?? DateTime.now();

      final desc = value["desc"] as String;

      return DirModel(
        id: k as int,
        parentDirID: parentID,
        name: name,
        created: created,
        updated: updated,
        desc: desc,
      );
    }).toList();

    dirList = await Future.wait(futures);
    return dirList;
  }

  // Add a new video in the specified directory.
  Future<void> addVid(
      {required String link, required int dirID, String desc = ""}) async {
    String? videoID;

    if (!dirDB.keys.contains(dirID)) {
      throw Exception("Invalid dirID. It doesn't exist");
    }

    // Regular expression to extract video ID from full YouTube link
    final fullUrlRegex = RegExp(r'v=([a-zA-Z0-9_-]{11})');
    final fullUrlMatch = fullUrlRegex.firstMatch(link);

    if (fullUrlMatch != null) {
      videoID = fullUrlMatch.group(1); // Extract from full YouTube URL
    } else {
      // Try to extract video ID from shortened youtu.be link
      final shortUrlRegex = RegExp(r'youtu\.be/([a-zA-Z0-9_-]{11})');
      final shortUrlMatch = shortUrlRegex.firstMatch(link);

      if (shortUrlMatch != null) {
        videoID = shortUrlMatch.group(1);
      } else {
        // Check if the link itself is a valid video ID (11 characters)
        final idRegex = RegExp(r'^[a-zA-Z0-9_-]{11}$');
        if (idRegex.hasMatch(link)) {
          videoID = link; // The link is already a valid video ID
        }
      }
    }

    // Throw an exception if the video ID is not found
    if (videoID == null) {
      throw Exception(
          'Invalid YouTube URL or video ID: Unable to extract video ID');
    }

    log("Video ID $videoID");

    final map = {
      "desc": desc,
      "created": DateTime.now().toString(),
      "updated": DateTime.now().toString(),
      "link": link,
    };

    log("Adding Video ${jsonEncode(map)} with videoID: $videoID");

    await vidDB.put(videoID, map);

    //Add the relationship of dirID and videoID;
    log("Adding Video $videoID tod Dir: $dirID");
    await dirVidDB.put("$dirID;$videoID", "");
  }

  Future<List<VidModel>> getVideos({int dirID = -1}) async {
    List<VidModel> videoList = [];

    if (dirID == -1) {
      // Fetch all videos if no dirID is provided
      final allKeys = vidDB.keys.toList();
      final futures = allKeys.map((videoID) async {
        final value = await vidDB.get(videoID);
        return _parseVidModel(videoID, value);
      }).toList();
      videoList = await Future.wait(futures);
    } else {
      // Fetch videos associated with the provided dirID
      final dirVidKeys =
          dirVidDB.keys.where((key) => key.startsWith('$dirID;')).toList();
      final futures = dirVidKeys.map((key) async {
        final videoID = key.split(';')[1]; // Extract videoID from key
        final value = await vidDB.get(videoID);
        return _parseVidModel(videoID, value);
      }).toList();
      videoList = await Future.wait(futures);
    }

    return videoList;
  }

  VidModel _parseVidModel(String videoID, dynamic value) {
    final createdStr = value["created"] as String;
    final updatedStr = value["updated"] as String;

    // Parse the date strings into DateTime objects
    final created = DateTime.tryParse(createdStr) ?? DateTime.now();
    final updated = DateTime.tryParse(updatedStr) ?? DateTime.now();

    return VidModel(
      videoID: videoID,
      link: value["link"] as String,
      desc: value["desc"] as String,
      created: created,
      updated: updated,
    );
  }
}
