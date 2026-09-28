class IdeathonIdeaSnapshot {
  const IdeathonIdeaSnapshot({
    required this.ideaId,
    required this.ideaTitle,
    required this.problemTitle,
    required this.teamName,
    required this.addedAt,
  });

  final String ideaId;
  final String ideaTitle;
  final String problemTitle;
  final String teamName;
  final DateTime addedAt;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'ideaId': ideaId,
      'ideaTitle': ideaTitle,
      'problemTitle': problemTitle,
      'teamName': teamName,
      'addedAt': addedAt.toIso8601String(),
    };
  }

  factory IdeathonIdeaSnapshot.fromMap(Map<String, dynamic> map) {
    return IdeathonIdeaSnapshot(
      ideaId: (map['ideaId'] as String? ?? '').trim(),
      ideaTitle: (map['ideaTitle'] as String? ?? '').trim(),
      problemTitle: (map['problemTitle'] as String? ?? '').trim(),
      teamName: (map['teamName'] as String? ?? '').trim(),
      addedAt: DateTime.tryParse((map['addedAt'] as String?) ?? '') ?? DateTime.now(),
    );
  }
}
