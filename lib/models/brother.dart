class Brother {
  final String id;
  final String name;
  final String username;
  final String avatarUrl;
  final bool isOnline;
  final int streak;

  const Brother({
    required this.id,
    required this.name,
    required this.username,
    required this.avatarUrl,
    required this.isOnline,
    required this.streak,
  });
}

const List<Brother> dummyBrothers = [
  Brother(
    id: '1',
    name: 'David Goggins',
    username: 'goggins_official',
    avatarUrl: 'https://i.pravatar.cc/150?u=1',
    isOnline: true,
    streak: 45,
  ),
  Brother(
    id: '2',
    name: 'Jocko Willink',
    username: 'jocko_zero',
    avatarUrl: 'https://i.pravatar.cc/150?u=2',
    isOnline: true,
    streak: 120,
  ),
  Brother(
    id: '3',
    name: 'Marcus Aurelius',
    username: 'stoic_king',
    avatarUrl: 'https://i.pravatar.cc/150?u=3',
    isOnline: false,
    streak: 365,
  ),
  Brother(
    id: '4',
    name: 'Lex Fridman',
    username: 'lex_love',
    avatarUrl: 'https://i.pravatar.cc/150?u=4',
    isOnline: true,
    streak: 12,
  ),
];
