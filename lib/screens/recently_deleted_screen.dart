import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/project_provider.dart';

class RecentlyDeletedScreen extends StatelessWidget {
  const RecentlyDeletedScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProjectProvider>(context);
    final deletedProjects = provider.deletedProjects;
    final deletedCards = provider.deletedFlashcards;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Recently Deleted'),
        actions: [
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
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          if (deletedProjects.isNotEmpty) ...[
            Text('Folders', style: TextStyle(color: colorScheme.primary, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...deletedProjects.map((p) => Card(
                  color: const Color(0xFF111111),
                  child: ListTile(
                    leading: Icon(Icons.folder, color: colorScheme.primary),
                    title: Text(p.name, style: const TextStyle(color: Colors.white)),
                    subtitle: Text(
                      p.description ?? '',
                      style: const TextStyle(color: Colors.white54),
                    ),
                    trailing: TextButton(
                      onPressed: () async {
                        await provider.restoreProject(p.id);
                      },
                      child: const Text('Restore'),
                    ),
                  ),
                )),
            const SizedBox(height: 16),
          ],
          if (deletedCards.isNotEmpty) ...[
            Text('Cards', style: TextStyle(color: colorScheme.primary, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...deletedCards.map((c) => Card(
                  color: const Color(0xFF111111),
                  child: ListTile(
                    leading: const Icon(Icons.style, color: Colors.white70),
                    title: Text(c.sideA, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white)),
                    subtitle: Text(c.sideB, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white54)),
                    trailing: TextButton(
                      onPressed: () async {
                        await provider.restoreFlashcard(c.id);
                      },
                      child: const Text('Restore'),
                    ),
                  ),
                )),
          ],
          if (deletedProjects.isEmpty && deletedCards.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.only(top: 32.0),
                child: Text('Nothing in Recently Deleted.', style: TextStyle(color: Colors.white70)),
              ),
            ),
        ],
      ),
    );
  }
}
