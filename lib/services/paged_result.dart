                                 
  
                                              
import 'package:flutter/foundation.dart';

           
class PagedResult<T> {
  final List<T> items;
  final bool hasMore;
  const PagedResult(this.items, this.hasMore);
}

                                     
class PagedListController<T> extends ChangeNotifier {
  final Future<PagedResult<T>> Function(int page) fetcher;
  final int firstPage;

  List<T> items = const [];
  int page;
  bool loading = false;
  bool hasMore = true;
  bool initiallyLoaded = false;
  String? error;

                                         
                                       
  bool refreshing = false;

  PagedListController(this.fetcher, {this.firstPage = 1}) : page = firstPage;

                         
                                     
                                              
                                           
                                         
                             
  Future<void> refresh() async {
    if (loading) return;
    page = firstPage;
    hasMore = true;
    error = null;
    refreshing = true;
    if (!initiallyLoaded) {
      items = const [];
      initiallyLoaded = false;
      notifyListeners();
    }
    try {
      await _fetch(page);
    } finally {
      refreshing = false;
      notifyListeners();
    }
  }

  Future<void> loadMore() async {
    if (loading || !hasMore || !initiallyLoaded) return;
    await _fetch(page + 1);
  }

  Future<void> _fetch(int p) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final r = await fetcher(p);
      items = p == firstPage ? r.items : [...items, ...r.items];
      page = p;
      hasMore = r.hasMore;
      initiallyLoaded = true;
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}
