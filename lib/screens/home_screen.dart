import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/project_provider.dart';
import '../screens/create_flashcard_screen.dart';
import '../screens/practice_screen.dart';
import '../models/project.dart';
import 'recently_deleted_screen.dart';
import '../widgets/home_background_painter.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  Widget _buildDrawer(BuildContext context) {
    final provider = Provider.of<ProjectProvider>(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    List<Widget> buildProjectList(List<Project> projects, {int depth = 0}) {
      return projects.map((p) {
        final children = provider.childrenOf(p.id);
        final indent = depth * 16.0;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DragTarget<Project>(
              onWillAccept: (dragged) {
                // prevent dropping a folder onto itself
                if (dragged == null || dragged.id == p.id) return false;
                return true;
              },
              onAccept: (dragged) async {
                // move dragged folder into this folder
                final updated = Project(
                  id: dragged.id,
                  name: dragged.name,
                  description: dragged.description,
                  parentId: p.id,
                );
                await provider.updateProject(updated);
              },
              builder: (context, candidateData, rejectedData) {
                final isHighlighted = candidateData.isNotEmpty;
                return LongPressDraggable<Project>(
                  data: p,
                  feedback: Material(
                    color: Colors.transparent,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 220),
                      child: ListTile(
                        leading: Icon(Icons.folder, color: colorScheme.primary),
                        title: Text(
                          p.name,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                  childWhenDragging: Opacity(
                    opacity: 0.3,
                    child: folderTile(p, indent, isHighlighted),
                  ),
                  child: folderTile(p, indent, isHighlighted),
                );
              },
            ),
            if (children.isNotEmpty)
              ...buildProjectList(children, depth: depth + 1),
          ],
        );
      }).toList();
    }

    return Drawer(
      backgroundColor: Colors.black,
      child: SafeArea(
        child: Column(
          children: [
            ListTile(
              title: Text(
                'All Flashcards',
                style: TextStyle(color: colorScheme.onBackground),
              ),
              leading: Icon(Icons.grid_view, color: colorScheme.primary),
              selected: provider.selectedProjectId == null,
              onTap: () {
                provider.selectedProjectId = null;
                Navigator.pop(context);
              },
            ),
            Divider(color: Colors.grey.shade800, height: 1),
            Expanded(
              child: DragTarget<Project>(
                onWillAccept: (dragged) => dragged != null,
                onAccept: (dragged) async {
                  final updated = Project(
                    id: dragged.id,
                    name: dragged.name,
                    description: dragged.description,
                    parentId: null,
                  );
                  await provider.updateProject(updated);
                },
                builder: (context, candidate, rejected) {
                  final isHighlighted = candidate.isNotEmpty;
                  return Container(
                    color: isHighlighted ? Colors.blueGrey.withOpacity(0.2) : Colors.transparent,
                    child: ListView(
                      children: buildProjectList(provider.rootProjects()),
                    ),
                  );
                },
              ),
            ),
            Divider(color: Colors.grey.shade800, height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton.icon(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        foregroundColor: Colors.redAccent,
                      ),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const RecentlyDeletedScreen()),
                        );
                      },
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Bin'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextButton.icon(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        foregroundColor: colorScheme.primary,
                      ),
                      icon: const Icon(Icons.add),
                      label: const Text('New Project'),
                      onPressed: () async {
                        final nameController = TextEditingController();
                        final createdProjectId = await showDialog<String>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            backgroundColor: Colors.grey[900],
                            title: const Text('Create Project', style: TextStyle(color: Colors.white)),
                            content: TextField(
                              controller: nameController,
                              decoration: const InputDecoration(hintText: 'Project name'),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(ctx).pop(),
                                child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
                              ),
                              TextButton(
                                onPressed: () async {
                                  final name = nameController.text.trim();
                                  if (name.isNotEmpty) {
                                    final project = await provider.createProject(name);
                                    Navigator.of(ctx).pop(project.id);
                                  }
                                },
                                child: Text('Create', style: TextStyle(color: colorScheme.primary)),
                              )
                            ],
                          ),
                        );
                        if (createdProjectId != null) {
                          provider.selectedProjectId = createdProjectId;
                          Navigator.of(context).pop();
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget folderTile(Project p, double indent, bool isHighlighted) {
    return Builder(
      builder: (context) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        return Container(
          decoration: BoxDecoration(
            color: isHighlighted ? Colors.blueGrey.withOpacity(0.3) : Colors.transparent,
          ),
          child: ListTile(
            contentPadding: EdgeInsets.only(left: 16 + indent, right: 16),
            leading: Icon(Icons.folder, color: colorScheme.primary),
            title: Text(
              p.name,
              style: TextStyle(color: colorScheme.onBackground),
            ),
            onTap: () {
              final provider = Provider.of<ProjectProvider>(context, listen: false);
              provider.selectedProjectId = p.id;
              Navigator.pop(context);
            },
            trailing: PopupMenuButton<String>(
              color: Colors.grey[900],
              icon: Icon(Icons.more_vert, color: colorScheme.onBackground),
              onSelected: (value) async {
                final provider = Provider.of<ProjectProvider>(context, listen: false);
                if (value == 'rename') {
                  final nameController = TextEditingController(text: p.name);
                  await showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: Colors.grey[900],
                      title: const Text('Rename Folder', style: TextStyle(color: Colors.white)),
                      content: TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          hintText: 'Folder name',
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
                        ),
                        TextButton(
                          onPressed: () async {
                            final newName = nameController.text.trim();
                            if (newName.isNotEmpty) {
                              final updated = Project(id: p.id, name: newName, description: p.description, parentId: p.parentId);
                              await provider.updateProject(updated);
                              Navigator.of(ctx).pop();
                            }
                          },
                          child: Text('Save', style: TextStyle(color: colorScheme.primary)),
                        )
                      ],
                    ),
                  );
                } else if (value == 'newFolder') {
                  final nameController = TextEditingController();
                  await showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: Colors.grey[900],
                      title: const Text('New Subfolder', style: TextStyle(color: Colors.white)),
                      content: TextField(
                        controller: nameController,
                        decoration: const InputDecoration(hintText: 'Folder name'),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
                        ),
                        TextButton(
                          onPressed: () async {
                            final name = nameController.text.trim();
                            if (name.isNotEmpty) {
                              await provider.createProject(name, parentId: p.id);
                              Navigator.of(ctx).pop();
                            }
                          },
                          child: Text('Create', style: TextStyle(color: colorScheme.primary)),
                        )
                      ],
                    ),
                  );
                } else if (value == 'makeRoot') {
                  final updated = Project(
                    id: p.id,
                    name: p.name,
                    description: p.description,
                    parentId: null,
                  );
                  await provider.updateProject(updated);
                } else if (value == 'delete') {
                  final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          backgroundColor: Colors.grey[900],
                          title: const Text('Delete folder?', style: TextStyle(color: Colors.white)),
                          content: const Text(
                            'This will move the folder and all its cards to Recently Deleted. You can restore them later.',
                            style: TextStyle(color: Colors.white70),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(false),
                              child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(true),
                              child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
                            ),
                          ],
                        ),
                      ) ??
                      false;
                  if (confirmed) {
                    await provider.deleteProject(p.id);
                  }
                }
              },
              itemBuilder: (ctx) => const [
                PopupMenuItem(
                  value: 'rename',
                  child: Text('Rename'),
                ),
                PopupMenuItem(
                  value: 'newFolder',
                  child: Text('Add subfolder'),
                ),
                PopupMenuItem(
                  value: 'makeRoot',
                  child: Text('Make main folder'),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Text(
                    'Delete',
                    style: TextStyle(color: Colors.redAccent),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProjectProvider>(context);
    final cards = provider.flashcardsForSelectedProject();
    final knownCount = cards.where((c) => c.known).length;
    final unknownCount = cards.length - knownCount;
    final categoryCount = provider.rootProjects().length;
    final recentCards = [...cards]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final visibleCards = recentCards.take(5).toList();
    final currentProject = provider.selectedProjectId == null
      ? null
      : provider.projects
        .firstWhere((p) => p.id == provider.selectedProjectId, orElse: () => provider.projects.first);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: Text(currentProject?.name ?? 'FlashQuanta'),
        actions: [
          if (currentProject != null)
            IconButton(
              icon: const Icon(Icons.home),
              onPressed: () {
                provider.selectedProjectId = null;
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: Colors.white24,
          ),
        ),
      ),
      drawer: _buildDrawer(context),
      body: Stack(
        children: [
          // abstract pen-style background
          Positioned.fill(
            child: CustomPaint(
              painter: HomeBackgroundPainter(),
            ),
          ),
          // subtle centered logo background (original look)
          Positioned.fill(
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.3,
                child: Center(
                  child: Image.asset(
                    'assets/logo/flashquanta_logo.png',
                    width: 260,
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Practice'),
                      onPressed: () {
                        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PracticeScreen()));
                      },
                    ),
                    const Spacer(),
                    Text('${cards.length} card(s) total'),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: _StatChip(
                          label: 'Known',
                          value: knownCount.toString(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: _StatChip(
                          label: 'Unknown',
                          value: unknownCount.toString(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: _StatChip(
                          label: 'Categories',
                          value: categoryCount.toString(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: Text(
                      'Recent',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w400,
                            fontSize: 25
                          ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: cards.isEmpty
                      ? const Center(child: Text('No flashcards yet.'))
                      : ListView.builder(
                          itemCount: visibleCards.length,
                          itemBuilder: (context, idx) {
                            final c = visibleCards[idx];
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10.0),
                              child: SizedBox(
                                height: 90,
                                child: GestureDetector(
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => CreateFlashcardScreen(existingCard: c),
                                      ),
                                    );
                                  },
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(22),
                                    child: Stack(
                                      children: [
                                        // Glassmorphism card background
                                        Positioned.fill(
                                          child: Container(
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(22),
                                              gradient: LinearGradient(
                                                colors: [
                                                  Colors.white.withOpacity(0.08),
                                                  Colors.white.withOpacity(0.02),
                                                ],
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              ),
                                              border: Border.all(
                                                color: Colors.white.withOpacity(0.12),
                                                width: 1,
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black.withOpacity(0.7),
                                                  blurRadius: 16,
                                                  offset: const Offset(0, 8),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        // Content row inside the glass card
                                        Positioned.fill(
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 20),
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    c.sideA,
                                                    maxLines: 2,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                      fontSize: 16,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                IconButton(
                                                  icon: const Icon(Icons.delete, color: Colors.redAccent),
                                                  onPressed: () async {
                                                    final confirmed = await showDialog<bool>(
                                                          context: context,
                                                          builder: (ctx) => AlertDialog(
                                                            backgroundColor: Colors.grey[900],
                                                            title: const Text('Delete card?', style: TextStyle(color: Colors.white)),
                                                            content: const Text(
                                                              'This will move the card to Recently Deleted. You can restore it later.',
                                                              style: TextStyle(color: Colors.white70),
                                                            ),
                                                            actions: [
                                                              TextButton(
                                                                onPressed: () => Navigator.of(ctx).pop(false),
                                                                child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
                                                              ),
                                                              TextButton(
                                                                onPressed: () => Navigator.of(ctx).pop(true),
                                                                child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
                                                              ),
                                                            ],
                                                          ),
                                                        ) ??
                                                        false;
                                                    if (confirmed) {
                                                      await provider.deleteFlashcard(c.id);
                                                    }
                                                  },
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        foregroundColor: Colors.white,
        backgroundColor: const Color.fromARGB(255, 20, 92, 150),
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const CreateFlashcardScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;

  const _StatChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container
    (
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white.withOpacity(0.06),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}