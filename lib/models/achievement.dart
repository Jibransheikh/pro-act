class Achievement {
  final String id;
  final String brotherName;
  final String brotherAvatar;
  final String achievementTitle;
  final String achievementDescription;
  final DateTime timestamp;
  final String icon;

  const Achievement({
    required this.id,
    required this.brotherName,
    required this.brotherAvatar,
    required this.achievementTitle,
    required this.achievementDescription,
    required this.timestamp,
    required this.icon,
  });
}

final List<Achievement> dummyAchievements = [
  Achievement(
    id: '1',
    brotherName: 'David Goggins',
    brotherAvatar: 'https://i.pravatar.cc/150?u=1',
    achievementTitle: 'STAY HARD',
    achievementDescription: 'Completed a 100-mile ultra marathon.',
    timestamp: DateTime.now().subtract(const Duration(hours: 2)),
    icon: '🏃‍♂️',
  ),
  Achievement(
    id: '2',
    brotherName: 'Jocko Willink',
    brotherAvatar: 'https://i.pravatar.cc/150?u=2',
    achievementTitle: 'EARLY RISER',
    achievementDescription: '800 days of waking up at 4:30 AM.',
    timestamp: DateTime.now().subtract(const Duration(hours: 5)),
    icon: '⏰',
  ),
  Achievement(
    id: '3',
    brotherName: 'Lex Fridman',
    brotherAvatar: 'https://i.pravatar.cc/150?u=4',
    achievementTitle: 'DEEP WORK',
    achievementDescription: 'Finished a 12-hour coding session.',
    timestamp: DateTime.now().subtract(const Duration(days: 1)),
    icon: '💻',
  ),
];
