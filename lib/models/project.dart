class Project {
  String id;
  String name;
  String? description;
  String? parentId; // null means root-level project/folder

  Project({
    required this.id,
    required this.name,
    this.description,
    this.parentId,
  });

  factory Project.fromJson(Map<String, dynamic> json) => Project(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String?,
        parentId: json['parentId'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'parentId': parentId,
      };
}