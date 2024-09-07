import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../backend/dto/dir_model.dart';
import '../backend/dto/vid_model.dart';
import '../backend/hive.dart';

class PageDirs extends StatefulWidget {
  final int? dirID;

  const PageDirs({super.key, this.dirID});

  @override
  State<PageDirs> createState() => _PageDirsState();
}

class _PageDirsState extends State<PageDirs> {
  late Future<List<DirModel>> _dirsFuture;
  late Future<List<VidModel>> _vidsFuture;
  int _currentDirID = -1;
  final List<int> _breadcrumbs = [];

  @override
  void initState() {
    super.initState();
    _currentDirID = widget.dirID ?? -1; // Use -1 for root directory
    _breadcrumbs.add(_currentDirID);
    _loadDirectories();
    _loadVideos();
  }

  void _loadDirectories() {
    _dirsFuture = HiveDB.instance.getDirectories(parentDirID: _currentDirID);
  }

  void _loadVideos() {
    _vidsFuture = HiveDB.instance.getVideos(dirID: _currentDirID);
  }

  void _navigateToDirectory(int dirID) {
    setState(() {
      _currentDirID = dirID;
      _breadcrumbs.add(dirID);
      _loadDirectories();
      _loadVideos();
    });
  }

  void _navigateUp() {
    if (_breadcrumbs.length > 1) {
      setState(() {
        _breadcrumbs.removeLast();
        _currentDirID = _breadcrumbs.last;
        _loadDirectories();
        _loadVideos();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Directory Browser'),
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_upward),
            onPressed: _breadcrumbs.length > 1 ? _navigateUp : null,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildBreadcrumbs(),
          Expanded(
            child: FutureBuilder<List<Object>>(
              future: Future.wait([_dirsFuture, _vidsFuture]),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData ||
                    (snapshot.data![0] as List).isEmpty &&
                        (snapshot.data![1] as List).isEmpty) {
                  return const Center(
                      child: Text('No directories or videos found'));
                } else {
                  final dirs = snapshot.data![0] as List<DirModel>;
                  final vids = snapshot.data![1] as List<VidModel>;
                  return ListView(
                    children: [
                      ...dirs.map((dir) => ListTile(
                            leading: const Icon(Icons.folder),
                            title: Text(dir.name),
                            subtitle: Text(dir.desc),
                            onTap: () => _navigateToDirectory(dir.id),
                          )),
                      ...vids.map((vid) => ListTile(
                            leading: Image.network(
                              vid.thumbnailUrl,
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.error),
                            ),
                            title: Text(vid.title),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(vid.desc),
                                Text('Video ID: ${vid.videoID}',
                                    style: const TextStyle(fontSize: 12)),
                              ],
                            ),
                            isThreeLine: true,
                            onTap: () {
                              // Implement video playback or details view
                            },
                          )),
                    ],
                  );
                }
              },
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: () => _showAddVideoDialog(context),
            heroTag: 'addVideo',
            child: const Icon(Icons.video_call),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            onPressed: () => _showAddDirectoryDialog(context),
            heroTag: 'addDirectory',
            child: const Icon(Icons.create_new_folder),
          ),
        ],
      ),
    );
  }

  Widget _buildBreadcrumbs() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _breadcrumbs.asMap().entries.map((entry) {
          final int index = entry.key;
          final int dirID = entry.value;
          return FutureBuilder<List<DirModel>>(
            future: HiveDB.instance.getDirectories(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                final dir = dirID == -1
                    ? DirModel(
                        id: -1,
                        parentDirID: -1,
                        name: 'Root',
                        created: DateTime.now(),
                        updated: DateTime.now(),
                        desc: '')
                    : snapshot.data!.firstWhere((d) => d.id == dirID);
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton(
                      child: Text(dir.name),
                      onPressed: () {
                        if (index < _breadcrumbs.length - 1) {
                          setState(() {
                            _currentDirID = dirID;
                            _breadcrumbs.removeRange(
                                index + 1, _breadcrumbs.length);
                            _loadDirectories();
                          });
                        }
                      },
                    ),
                    if (index < _breadcrumbs.length - 1)
                      const Icon(Icons.chevron_right),
                  ],
                );
              } else {
                return const CircularProgressIndicator();
              }
            },
          );
        }).toList(),
      ),
    );
  }

  void _showAddDirectoryDialog(BuildContext context) {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController descController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Add New Directory'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Directory Name'),
              ),
              TextField(
                controller: descController,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            TextButton(
              child: const Text('Add'),
              onPressed: () {
                if (nameController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Directory name cannot be empty')),
                  );
                  return;
                }

                Navigator.of(dialogContext).pop();

                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (BuildContext context) {
                    return const AlertDialog(
                      content: Row(
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(width: 20),
                          Text("Adding directory..."),
                        ],
                      ),
                    );
                  },
                );

                HiveDB.instance
                    .addDirectory(
                  name: nameController.text,
                  parentID: _currentDirID,
                  desc: descController.text,
                )
                    .then((_) {
                  Navigator.of(context).pop(); // Dismiss the loading dialog
                  if (mounted) {
                    setState(() {
                      _loadDirectories();
                    });
                  }
                }).catchError((error) {
                  Navigator.of(context).pop(); // Dismiss the loading dialog
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error adding directory: $error')),
                  );
                });
              },
            ),
          ],
        );
      },
    );
  }

  void _showAddVideoDialog(BuildContext context) {
    final TextEditingController linkController = TextEditingController();
    final TextEditingController descController = TextEditingController();

    // Check clipboard for YouTube link
    Clipboard.getData(Clipboard.kTextPlain).then((value) {
      if (value != null && value.text != null) {
        final clipboardText = value.text!;
        if (clipboardText.contains('youtube.com/watch?v=') ||
            clipboardText.contains('youth.be/')) {
          linkController.text = clipboardText;
        }
      }
    });

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Add New Video'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: linkController,
                decoration: const InputDecoration(labelText: 'Video Link'),
              ),
              TextField(
                controller: descController,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            TextButton(
              child: const Text('Add'),
              onPressed: () {
                if (linkController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Video link cannot be empty')),
                  );
                  return;
                }

                Navigator.of(dialogContext).pop();

                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (BuildContext context) {
                    return const AlertDialog(
                      content: Row(
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(width: 20),
                          Text("Adding video..."),
                        ],
                      ),
                    );
                  },
                );

                HiveDB.instance
                    .addVid(
                  link: linkController.text,
                  dirID: _currentDirID,
                  desc: descController.text,
                )
                    .then((_) {
                  Navigator.of(context).pop(); // Dismiss the loading dialog
                  if (mounted) {
                    setState(() {
                      _loadVideos();
                    });
                  }
                }).catchError((error) {
                  Navigator.of(context).pop(); // Dismiss the loading dialog
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error adding video: $error')),
                  );
                });
              },
            ),
          ],
        );
      },
    );
  }
}
