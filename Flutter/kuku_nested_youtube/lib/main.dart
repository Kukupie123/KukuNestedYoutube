import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:kuku_nested_youtube/backend/dto/vid_model.dart';
import 'package:kuku_nested_youtube/backend/hive.dart';
import 'package:kuku_nested_youtube/pages/dirs_page.dart';
import 'backend/dto/dir_model.dart';

void main() async {
  log("Initializing Hive Flutter");
  await Hive.initFlutter();
  log("Initializing Hive's DB");
  await HiveDB.instance.initInstance();
  log("Initialized Hive");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const PageDirs(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController _dirNameController = TextEditingController();
  final TextEditingController _videoLinkController = TextEditingController();
  final TextEditingController _dirIDController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  List<DirModel> _directories = [];
  List<VidModel> _videos = [];

  Future<void> _addDirectory() async {
    final name = _dirNameController.text;
    final desc = _descController.text;
    try {
      await HiveDB.instance.addDirectory(name: name, desc: desc);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Directory added successfully')),
        );
        await _fetchDirectories(); // Refresh the directory list
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding directory: $e')),
        );
      }
    }
  }

  Future<void> _addVideo() async {
    final link = _videoLinkController.text;
    final dirID = int.tryParse(_dirIDController.text) ?? -1;
    final desc = _descController.text;
    try {
      await HiveDB.instance.addVid(link: link, dirID: dirID, desc: desc);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Video added successfully')),
        );
        await _fetchVideos(); // Refresh the video list
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding video: $e')),
        );
      }
    }
  }

  Future<void> _fetchDirectories() async {
    try {
      final directories = await HiveDB.instance.getDirectories();
      if (mounted) {
        setState(() {
          _directories = directories;
        });
        log('Directories: $_directories');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fetched ${directories.length} directories')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error fetching directories: $e'),
            duration: const Duration(milliseconds: 500),
          ),
        );
      }
    }
  }

  Future<void> _fetchVideos() async {
    final dirID = int.tryParse(_dirIDController.text) ?? -1;
    try {
      final videos = await HiveDB.instance.getVideos(dirID: dirID);
      if (mounted) {
        setState(() {
          _videos = videos;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fetched ${videos.length} videos')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error fetching directories: $e'),
            duration: const Duration(milliseconds: 500),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // Directory Input Fields
            TextField(
              controller: _dirNameController,
              decoration: const InputDecoration(labelText: 'Directory Name'),
            ),
            TextField(
              controller: _descController,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            ElevatedButton(
              onPressed: _addDirectory,
              child: const Text('Add Directory'),
            ),
            const SizedBox(height: 16),

            // Video Input Fields
            TextField(
              controller: _videoLinkController,
              decoration: const InputDecoration(labelText: 'Video Link'),
            ),
            TextField(
              controller: _dirIDController,
              decoration: const InputDecoration(labelText: 'Directory ID'),
              keyboardType: TextInputType.number,
            ),
            ElevatedButton(
              onPressed: _addVideo,
              child: const Text('Add Video'),
            ),
            const SizedBox(height: 16),

            // Fetch Buttons
            ElevatedButton(
              onPressed: _fetchDirectories,
              child: const Text('Fetch Directories'),
            ),
            ElevatedButton(
              onPressed: _fetchVideos,
              child: const Text('Fetch Videos'),
            ),

            // Display directories
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _directories.length,
                itemBuilder: (context, index) {
                  final dir = _directories[index];
                  return ListTile(
                    title: Text(dir.name),
                    subtitle: Text('ID: ${dir.id}'),
                    trailing: Text(dir.desc),
                  );
                },
              ),
            ),

            // Display videos
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _videos.length,
                itemBuilder: (context, index) {
                  final video = _videos[index];
                  return ListTile(
                    title: Text(video.link),
                    subtitle: Text('Video ID: ${video.videoID}'),
                    trailing: Text(video.desc),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
