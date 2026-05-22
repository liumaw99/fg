class SearchResultModel {
  final String id;
  final String type;
  final String title;
  final String? subtitle;
  final String? content;

  SearchResultModel({
    required this.id,
    required this.type,
    required this.title,
    this.subtitle,
    this.content,
  });

  factory SearchResultModel.fromJson(Map<String, dynamic> json) {
    return SearchResultModel(
      id: json['id'] as String,
      type: json['type'] as String,
      title: json['title'] as String,
      subtitle: json['subtitle'] as String?,
      content: json['content'] as String?,
    );
  }
}

class SearchResponse {
  final List<SearchResultModel> results;
  final String? nextCursor;
  final bool hasMore;

  SearchResponse({
    required this.results,
    this.nextCursor,
    required this.hasMore,
  });

  factory SearchResponse.fromJson(Map<String, dynamic> json) {
    return SearchResponse(
      results: (json['results'] as List<dynamic>?)
              ?.map((e) => SearchResultModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      nextCursor: json['next_cursor'] as String?,
      hasMore: json['has_more'] as bool? ?? false,
    );
  }
}
