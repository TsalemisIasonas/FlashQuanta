import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/project.dart';
import '../models/flashcard.dart';
import '../services/storage_service.dart';

class ProjectProvider extends ChangeNotifier {
  final StorageService storage;
  final _uuid = const Uuid();

  ProjectProvider({required this.storage});

  List<Project> _projects = [];
  List<Flashcard> _flashcards = [];

  // Recently deleted items (soft delete)
  List<Project> _deletedProjects = [];
  List<Flashcard> _deletedFlashcards = [];

  String? _selectedProjectId; // null = All
  Set<String> _selectedFlashcardIdsForFilter = {};

  // Practice filter: null = all, true = known only, false = unknown only
  bool? _practiceKnownFilter;

  UnmodifiableListView<Project> get projects => UnmodifiableListView(_projects);
  UnmodifiableListView<Flashcard> get flashcards =>
      UnmodifiableListView(_flashcards);

    UnmodifiableListView<Project> get deletedProjects =>
      UnmodifiableListView(_deletedProjects);
    UnmodifiableListView<Flashcard> get deletedFlashcards =>
      UnmodifiableListView(_deletedFlashcards);

  String? get selectedProjectId => _selectedProjectId;
  set selectedProjectId(String? id) {
    _selectedProjectId = id;
    _selectedFlashcardIdsForFilter.clear();
    notifyListeners();
  }

  Set<String> get selectedFlashcardIdsForFilter =>
      _selectedFlashcardIdsForFilter;

  bool? get practiceKnownFilter => _practiceKnownFilter;
  set practiceKnownFilter(bool? value) {
    _practiceKnownFilter = value;
    notifyListeners();
  }

  Future<void> load() async {
    final data = await storage.readData();
    final projectsJson = (data['projects'] as List<dynamic>?) ?? [];
    final flashcardsJson = (data['flashcards'] as List<dynamic>?) ?? [];
    final deletedProjectsJson = (data['deletedProjects'] as List<dynamic>?) ?? [];
    final deletedFlashcardsJson = (data['deletedFlashcards'] as List<dynamic>?) ?? [];

    _projects = projectsJson
        .map((e) => Project.fromJson((e as Map<String, dynamic>)))
        .toList();
    _flashcards = flashcardsJson
        .map((e) => Flashcard.fromJson((e as Map<String, dynamic>)))
        .toList();
    _deletedProjects = deletedProjectsJson
      .map((e) => Project.fromJson((e as Map<String, dynamic>)))
      .toList();
    _deletedFlashcards = deletedFlashcardsJson
      .map((e) => Flashcard.fromJson((e as Map<String, dynamic>)))
      .toList();

    // If no project exists yet, create a default one
    if (_projects.isEmpty) {
      final defaultProject = Project(id: _uuid.v4(), name: 'Default');
      _projects.add(defaultProject);
      notifyListeners();
      await save();
    }

    notifyListeners();
  }

  Future<void> save() async {
    final data = {
      'projects': _projects.map((p) => p.toJson()).toList(),
      'flashcards': _flashcards.map((f) => f.toJson()).toList(),
      'deletedProjects': _deletedProjects.map((p) => p.toJson()).toList(),
      'deletedFlashcards':
          _deletedFlashcards.map((f) => f.toJson()).toList(),
    };
    await storage.writeData(data);
  }

  Future<Project> createProject(String name, {String? description, String? parentId}) async {
    final p = Project(id: _uuid.v4(), name: name, description: description, parentId: parentId);
    _projects.add(p);
    await save();
    notifyListeners();
    return p;
  }

  Future<void> updateProject(Project project) async {
    final idx = _projects.indexWhere((p) => p.id == project.id);
    if (idx >= 0) {
      _projects[idx] = project;
      await save();
      notifyListeners();
    }
  }

  Future<void> deleteProject(String id) async {
    // remove the project and any children recursively
    void removeRecursive(String projectId) {
      final children = _projects.where((p) => p.parentId == projectId).toList();
      for (final child in children) {
        removeRecursive(child.id);
      }
      final projIndex = _projects.indexWhere((p) => p.id == projectId);
      if (projIndex != -1) {
        _deletedProjects.add(_projects[projIndex]);
        _projects.removeAt(projIndex);
      }
      final projCards = _flashcards.where((f) => f.projectId == projectId).toList();
      for (final card in projCards) {
        _deletedFlashcards.add(card);
      }
      _flashcards.removeWhere((f) => f.projectId == projectId);
      if (_selectedProjectId == projectId) _selectedProjectId = null;
    }

    removeRecursive(id);
    await save();
    notifyListeners();
  }

  List<Project> rootProjects() =>
      _projects.where((p) => p.parentId == null).toList();

  List<Project> childrenOf(String parentId) =>
      _projects.where((p) => p.parentId == parentId).toList();

  Future<Flashcard> createFlashcard({
    required String projectId,
    required String sideA,
    required String sideB,
    List<String>? tags,
  }) async {
    final f = Flashcard(
      id: _uuid.v4(),
      projectId: projectId,
      sideA: sideA,
      sideB: sideB,
      tags: tags ?? [],
    );
    _flashcards.add(f);
    await save();
    notifyListeners();
    return f;
  }

  Future<void> updateFlashcard(Flashcard card) async {
    final idx = _flashcards.indexWhere((c) => c.id == card.id);
    if (idx >= 0) {
      _flashcards[idx] = card;
      await save();
      notifyListeners();
    }
  }

  Future<void> deleteFlashcard(String id) async {
    final idx = _flashcards.indexWhere((f) => f.id == id);
    if (idx != -1) {
      _deletedFlashcards.add(_flashcards[idx]);
      _flashcards.removeAt(idx);
    }
    _selectedFlashcardIdsForFilter.remove(id);
    await save();
    notifyListeners();
  }

  Future<void> restoreProject(String id) async {
    final idx = _deletedProjects.indexWhere((p) => p.id == id);
    if (idx != -1) {
      _projects.add(_deletedProjects[idx]);
      _deletedProjects.removeAt(idx);
      await save();
      notifyListeners();
    }
  }

  Future<void> restoreFlashcard(String id) async {
    final idx = _deletedFlashcards.indexWhere((f) => f.id == id);
    if (idx != -1) {
      _flashcards.add(_deletedFlashcards[idx]);
      _deletedFlashcards.removeAt(idx);
      await save();
      notifyListeners();
    }
  }

  List<Flashcard> flashcardsForSelectedProject() {
    if (_selectedProjectId == null) return _flashcards;
    return _flashcards.where((f) => f.projectId == _selectedProjectId).toList();
  }

  List<Flashcard> flashcardsForPractice() {
    var cards = flashcardsForSelectedProject();
    if (_selectedFlashcardIdsForFilter.isNotEmpty) {
      cards = cards
          .where((c) => _selectedFlashcardIdsForFilter.contains(c.id))
          .toList();
    }
    if (_practiceKnownFilter != null) {
      cards = cards
          .where((c) => c.known == _practiceKnownFilter)
          .toList();
    }
    return cards;
  }

  void toggleFlashcardFilterSelection(String flashcardId) {
    if (_selectedFlashcardIdsForFilter.contains(flashcardId)) {
      _selectedFlashcardIdsForFilter.remove(flashcardId);
    } else {
      _selectedFlashcardIdsForFilter.add(flashcardId);
    }
    notifyListeners();
  }

  void clearFlashcardFilterSelection() {
    _selectedFlashcardIdsForFilter.clear();
    notifyListeners();
  }
}