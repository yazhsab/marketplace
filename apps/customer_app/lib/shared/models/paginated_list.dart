class PaginatedList<T> {
  final List<T> items;
  final int total;
  final int page;
  final int perPage;

  const PaginatedList({
    required this.items,
    required this.total,
    required this.page,
    required this.perPage,
  });

  bool get hasMore => page * perPage < total;

  int get nextPage => page + 1;

  PaginatedList<T> copyWith({
    List<T>? items,
    int? total,
    int? page,
    int? perPage,
  }) {
    return PaginatedList<T>(
      items: items ?? this.items,
      total: total ?? this.total,
      page: page ?? this.page,
      perPage: perPage ?? this.perPage,
    );
  }

  PaginatedList<T> appendPage(PaginatedList<T> nextPageData) {
    return PaginatedList<T>(
      items: [...items, ...nextPageData.items],
      total: nextPageData.total,
      page: nextPageData.page,
      perPage: nextPageData.perPage,
    );
  }

  factory PaginatedList.empty() {
    return const PaginatedList(items: [], total: 0, page: 1, perPage: 20);
  }
}
