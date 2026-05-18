class Badge {
  final String id;
  final String title;
  final String description;
  final String icon;
  final bool isUnlocked;

  const Badge({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    this.isUnlocked = false,
  });
}

const List<Badge> dummyBadges = [
  Badge(
    id: '1',
    title: 'THE VOW',
    description: 'Held your first vow.',
    icon: '📜',
    isUnlocked: true,
  ),
  Badge(
    id: '2',
    title: 'STREAK 7',
    description: '7 days of pure consistency.',
    icon: '🔥',
    isUnlocked: true,
  ),
  Badge(
    id: '3',
    title: 'NIGHT OWL',
    description: 'Held a vow after midnight.',
    icon: '🦉',
    isUnlocked: true,
  ),
  Badge(
    id: '4',
    title: 'GLADIATOR',
    description: '30 days of accountability.',
    icon: '🛡️',
    isUnlocked: false,
  ),
  Badge(
    id: '5',
    title: 'IMMORTAL',
    description: '365 days streak.',
    icon: '👑',
    isUnlocked: false,
  ),
  Badge(
    id: '6',
    title: 'BROTHERS KEEPER',
    description: 'Nudged 50 brothers.',
    icon: '🤝',
    isUnlocked: true,
  ),
];
