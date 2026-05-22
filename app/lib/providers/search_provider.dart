import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../core/utils/debounce.dart';
import '../data/api/search_api.dart';
import '../data/models/search_result_model.dart';

part 'search_provider.g.dart';

final searchApiProvider = Provider<SearchApi>((ref) => SearchApi());

@riverpod
class Search extends _$Search {
  final _debounce = Debounce(delay: const Duration(milliseconds: 300));

  @override
  Future<SearchResponse> build() async {
    return SearchResponse(results: [], hasMore: false);
  }

  void search(String query, {String type = 'all'}) {
    if (query.trim().isEmpty) {
      state = AsyncValue.data(SearchResponse(results: [], hasMore: false));
      return;
    }

    _debounce.call(() async {
      state = const AsyncValue.loading();
      try {
        final api = ref.read(searchApiProvider);
        final data = await api.search(query.trim(), type: type);
        final response = SearchResponse.fromJson(data);
        state = AsyncValue.data(response);
      } catch (e, st) {
        state = AsyncValue.error(e, st);
      }
    });
  }

  void clear() {
    state = AsyncValue.data(SearchResponse(results: [], hasMore: false));
  }

  void disposeDebounce() {
    _debounce.dispose();
  }
}
