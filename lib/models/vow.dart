enum VowStatus { pending, completed, failed }

class Vow {
  final String id;
  final String title;
  final VowStatus status;

  const Vow({
    required this.id,
    required this.title,
    this.status = VowStatus.pending,
  });

  Vow copyWith({VowStatus? status}) {
    return Vow(
      id: id,
      title: title,
      status: status ?? this.status,
    );
  }
}

const List<Vow> dummyVows = [
  Vow(id: '1', title: 'Wake up at 5:00 AM', status: VowStatus.completed),
  Vow(id: '2', title: 'Cold Shower', status: VowStatus.completed),
  Vow(id: '3', title: '45 min Workout', status: VowStatus.pending),
  Vow(id: '4', title: 'Read 10 pages', status: VowStatus.pending),
];
