import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/project_provider.dart';
import '../models/project.dart';
import '../models/flashcard.dart';

class CreateFlashcardScreen extends StatefulWidget {
  final Flashcard? existingCard;

  const CreateFlashcardScreen({Key? key, this.existingCard}) : super(key: key);

  @override
  State<CreateFlashcardScreen> createState() => _CreateFlashcardScreenState();
}

class _CreateFlashcardScreenState extends State<CreateFlashcardScreen> {
  final _formKey = GlobalKey<FormState>();
  final _sideA = TextEditingController();
  final _sideB = TextEditingController();
  String? _selectedProjectId;

  @override
  void dispose() {
    _sideA.dispose();
    _sideB.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProjectProvider>(context);
    final projects = provider.projects;

    // Initialize fields when editing an existing card
    if (widget.existingCard != null && _selectedProjectId == null) {
      _selectedProjectId = widget.existingCard!.projectId;
      _sideA.text = widget.existingCard!.sideA;
      _sideB.text = widget.existingCard!.sideB;
    } else {
      _selectedProjectId ??=
          provider.selectedProjectId ?? (projects.isNotEmpty ? projects.first.id : null);
    }

    final isEditing = widget.existingCard != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Flashcard' : 'Create Flashcard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () {
              final provider = Provider.of<ProjectProvider>(context, listen: false);
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
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
              DropdownButtonFormField<String>(
                value: _selectedProjectId,
                decoration: const InputDecoration(labelText: 'Project / Category'),
                items: projects
                    .map((p) => DropdownMenuItem(value: p.id, child: Text(p.name)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedProjectId = v),
              ),
              TextFormField(
                controller: _sideA,
                decoration: const InputDecoration(labelText: 'Side A (front)'),
                maxLines: 4,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              TextFormField(
                controller: _sideB,
                decoration: const InputDecoration(labelText: 'Side B (back)'),
                maxLines: 4,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState?.validate() ?? false) {
                    final projectId = _selectedProjectId ?? projects.first.id;
                    if (isEditing) {
                      final existing = widget.existingCard!;
                      final updated = Flashcard(
                        id: existing.id,
                        projectId: projectId,
                        sideA: _sideA.text.trim(),
                        sideB: _sideB.text.trim(),
                        tags: existing.tags,
                        known: existing.known,
                        createdAt: existing.createdAt,
                      );
                      await provider.updateFlashcard(updated);
                    } else {
                      await provider.createFlashcard(
                        projectId: projectId,
                        sideA: _sideA.text.trim(),
                        sideB: _sideB.text.trim(),
                      );
                    }
                    Navigator.of(context).pop();
                  }
                },
                child: Text(isEditing ? 'Save' : 'Create'),
              ),
              const SizedBox(height: 80),
              Center(
                child: Image.asset(
                  'assets/logo/flashquanta_logo.png',
                  height: 240,
                ),
              ),
            ],
          ),
          ),
        ),
      ),
    );
  }
}