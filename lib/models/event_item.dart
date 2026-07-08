class EventItem {
  final int id;
  final String title;
  final DateTime date;
  final String location;
  final String description;
  final String image;
  final int attendees;
  bool isJoined;

  EventItem({
    required this.id,
    required this.title,
    required this.date,
    required this.location,
    required this.description,
    required this.image,
    required this.attendees,
    this.isJoined = false,
  });
}
