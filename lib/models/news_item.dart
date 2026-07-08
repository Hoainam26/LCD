import 'dart:convert';

class NewsItem {
  final int id;
  final String title;
  final String date;
  final DateTime? publishedAtValue;
  final DateTime? updatedAtValue;
  final String image;
  final List<String> galleryImages;
  final String description;
  final String content;
  final String category;
  final String status;
  final bool pinned;

  NewsItem({
    required this.id,
    required this.title,
    required this.date,
    this.publishedAtValue,
    this.updatedAtValue,
    required this.image,
    this.galleryImages = const [],
    required this.description,
    required this.content,
    required this.category,
    required this.status,
    this.pinned = false,
  });

  factory NewsItem.fromApi(Map<String, dynamic> json) {
    final publishedAt = json['published_at'] ?? json['publishedAt'];
    final parsedPublishedAt = publishedAt != null
        ? DateTime.tryParse(publishedAt.toString())
        : null;
    final updatedAt = json['updated_at'] ?? json['updatedAt'];
    final parsedUpdatedAt = updatedAt != null
      ? DateTime.tryParse(updatedAt.toString())
      : null;
    final date = parsedPublishedAt ?? DateTime.now();
    final content = json['content'] ?? '';
    final description = content.length > 120
        ? '${content.substring(0, 120)}...'
        : content;
    final galleryRaw = json['gallery_image_urls'] ?? json['galleryImageUrls'];
    final galleryImages = galleryRaw is List
        ? galleryRaw
            .map((item) => item.toString())
            .where((item) => item.isNotEmpty)
            .toList()
        : galleryRaw is String && galleryRaw.trim().isNotEmpty
            ? (() {
                try {
                  final decoded = jsonDecode(galleryRaw);
                  if (decoded is List) {
                    return decoded
                        .map((item) => item.toString())
                        .where((item) => item.isNotEmpty)
                        .toList();
                  }
                } catch (_) {
                  // Fall back to a single URL below.
                }
                return <String>[galleryRaw];
              })()
            : <String>[];
    final coverImage = (json['cover_image_url'] ?? json['image'] ?? '').toString();
    final status = (json['status'] ?? 'draft').toString();
    final pinned = json['pinned'] == true || json['pinned'] == 1 || json['pinned'] == 'true';

    return NewsItem(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      date: '${date.day}/${date.month}/${date.year}',
      publishedAtValue: parsedPublishedAt,
        updatedAtValue: parsedUpdatedAt,
      image: coverImage.isNotEmpty
          ? coverImage
          : (galleryImages.isNotEmpty ? galleryImages.first : 'assets/images/logo.jpg'),
      galleryImages: galleryImages,
      description: description,
      content: content,
      category: (json['type'] ?? 'news').toString(),
      status: status,
      pinned: pinned,
    );
  }
  
  DateTime get publishedAt {
    if (publishedAtValue != null) return publishedAtValue!;
    final normalized = date.trim();
    final slashParts = normalized.split('/');
    if (slashParts.length == 3) {
      final day = int.tryParse(slashParts[0]) ?? 1;
      final month = int.tryParse(slashParts[1]) ?? 1;
      final year = int.tryParse(slashParts[2]) ?? DateTime.now().year;
      return DateTime(year, month, day);
    }
    return DateTime.tryParse(normalized) ?? DateTime.now();
  }

  DateTime get sortTimestamp => updatedAtValue ?? publishedAt;

  bool get isArchived => status == 'archived';

  String get publishedAtString => date;
}

int compareNewsItems(NewsItem a, NewsItem b) {
  // Sort by timestamp desc (newest first)
  return b.sortTimestamp.compareTo(a.sortTimestamp);
}
