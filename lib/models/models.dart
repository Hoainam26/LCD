// News Item Model
class NewsItem {
  final int id;
  final String title;
  final String date;
  final String image;
  final String description;
  final String content;
  final String category;

  NewsItem({
    required this.id,
    required this.title,
    required this.date,
    required this.image,
    required this.description,
    required this.content,
    required this.category,
  });

  factory NewsItem.fromApi(Map<String, dynamic> json) {
    final publishedAt = json['published_at'] ?? json['publishedAt'];
    final date = publishedAt != null
        ? DateTime.parse(publishedAt)
        : DateTime.now();
    final content = json['content'] ?? '';
    final description = content.length > 120
        ? '${content.substring(0, 120)}...'
        : content;

    return NewsItem(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      date: '${date.day}/${date.month}/${date.year}',
      image: json['cover_image_url'] ?? json['image'] ?? 'assets/images/logo.jpg',
      description: description,
      content: content,
      category: (json['type'] ?? 'news').toString(),
    );
  }
}

// Event Item Model
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

  factory EventItem.fromApi(Map<String, dynamic> json) {
    final startTime = json['start_time'] ?? json['startTime'] ?? json['dateTime'];
    final date = startTime != null ? DateTime.parse(startTime) : DateTime.now();
    return EventItem(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      date: date,
      location: json['location'] ?? '',
      description: json['description'] ?? '',
      image: json['cover_image_url'] ?? json['image'] ?? 'assets/images/event1.jpg',
      attendees: json['attendees'] ?? 0,
      isJoined: false,
    );
  }
}
