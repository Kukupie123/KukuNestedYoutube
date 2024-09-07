import 'package:flutter/material.dart';

import '../backend/dto/dir_model.dart';
import '../backend/hive.dart';

class PageDirs extends StatefulWidget {
  final int? dirID;

  const PageDirs({super.key, this.dirID});

  @override
  State<PageDirs> createState() => _PageDirsState();
}

class _PageDirsState extends State<PageDirs> {
  late Future<List<DirModel>> _dirsFuture;
  int _currentDirID = -1;
  final List<int> _breadcrumbs = [];

  @override
  void initState() {
    super.initState();
    _currentDirID = widget.dirID ?? -1; // Use -1 for root directory
    _breadcrumbs.add(_currentDirID);
    _loadDirectories();
  }

  void _loadDirectories() {
    _dirsFuture = HiveDB.instance.getDirectories().then((allDirs) {
      if (_currentDirID == -1) {
        // For root, return all directories without a parent
        return allDirs.where((dir) => dir.parentDirID == -1).toList();
      } else {
        // For other directories, return children as before
        return allDirs.where((dir) => dir.parentDirID == _currentDirID).toList();
      }
    });
  }

  void _navigateToDirectory(int dirID) {
    setState(() {
      _currentDirID = dirID;
      _breadcrumbs.add(dirID);
      _loadDirectories();
    });
  }

  void _navigateUp() {
    if (_breadcrumbs.length > 1) {
      setState(() {
        _breadcrumbs.removeLast();
        _currentDirID = _breadcrumbs.last;
        _loadDirectories();
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
            child: FutureBuilder<List<DirModel>>(
              future: _dirsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No directories found'));
                } else {
                  return ListView.builder(
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      final dir = snapshot.data![index];
                      return ListTile(
                        leading: const Icon(Icons.folder),
                        title: Text(dir.name),
                        subtitle: Text(dir.desc),
                        onTap: () => _navigateToDirectory(dir.id),
                      );
                    },
                  );
                }
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDirectoryDialog(context),
        child: const Icon(Icons.create_new_folder),
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
                    ? DirModel(id: -1, parentDirID: -1, name: 'Root', created: DateTime.now(), updated: DateTime.now(), desc: '')
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
                            _breadcrumbs.removeRange(index + 1, _breadcrumbs.length);
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
                    const SnackBar(content: Text('Directory name cannot be empty')),
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
}
