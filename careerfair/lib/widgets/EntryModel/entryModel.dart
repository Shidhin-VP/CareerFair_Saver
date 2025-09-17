// lib/models/entry_model.dart

class EntryModel {
  final String employerName;
  final String head;
  final String? note;
  final String? imagePath; // Path from camera/photo; optional

  EntryModel({
    required this.employerName,
    required this.head,
    this.note,
    this.imagePath,
  });

  Map<String, dynamic> toMap() {
    return {
      'employerName': employerName,
      'head': head,
      'note': note,
      'imagePath': imagePath,
    };
  }

  factory EntryModel.fromMap(Map<String, dynamic> map) {
    return EntryModel(
      employerName: map['employerName'],
      head: map['head'],
      note: map['note'],
      imagePath: map['imagePath'],
    );
  }
}
