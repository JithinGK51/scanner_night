import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/history_item.dart';

class HistoryService {
  static const String _historyKey = 'scan_history';
  static const int _maxHistoryItems = 1000;
  static const int _pageSize = 50; // Items per page for pagination
  
  // Cache for parsed history
  List<HistoryItem>? _cachedHistory;
  DateTime? _cacheTimestamp;

  /// Get all history items (with caching)
  Future<List<HistoryItem>> getHistory({bool forceRefresh = false}) async {
    // Return cached data if available and not forcing refresh
    if (!forceRefresh && _cachedHistory != null && _cacheTimestamp != null) {
      final cacheAge = DateTime.now().difference(_cacheTimestamp!);
      if (cacheAge.inSeconds < 5) { // Cache valid for 5 seconds
        return List.from(_cachedHistory!);
      }
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString(_historyKey);
      
      if (historyJson == null) {
        _cachedHistory = [];
        _cacheTimestamp = DateTime.now();
        return [];
      }

      // Optimized JSON parsing with error handling
      List<dynamic> historyList;
      try {
        historyList = json.decode(historyJson) as List<dynamic>;
      } catch (e) {
        // If JSON is corrupted, return empty list
        _cachedHistory = [];
        _cacheTimestamp = DateTime.now();
        return [];
      }

      final history = historyList
          .map((item) {
            try {
              return HistoryItem.fromJson(item as Map<String, dynamic>);
            } catch (e) {
              return null;
            }
          })
          .whereType<HistoryItem>()
          .toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

      // Update cache
      _cachedHistory = history;
      _cacheTimestamp = DateTime.now();
      
      return history;
    } catch (e) {
      _cachedHistory = [];
      _cacheTimestamp = DateTime.now();
      return [];
    }
  }

  /// Get paginated history items
  Future<HistoryPage> getHistoryPaginated({
    int page = 0,
    int pageSize = _pageSize,
    String filter = 'All',
    String searchQuery = '',
  }) async {
    final allHistory = await getHistory();
    var filtered = filterHistory(allHistory, filter, searchQuery);
    
    final totalItems = filtered.length;
    final totalPages = (totalItems / pageSize).ceil();
    final startIndex = page * pageSize;
    final endIndex = (startIndex + pageSize).clamp(0, totalItems);
    
    final items = filtered.sublist(
      startIndex.clamp(0, totalItems),
      endIndex,
    );
    
    return HistoryPage(
      items: items,
      currentPage: page,
      totalPages: totalPages,
      totalItems: totalItems,
      hasNextPage: page < totalPages - 1,
      hasPreviousPage: page > 0,
    );
  }

  Future<void> addHistoryItem(HistoryItem item) async {
    try {
      final history = await getHistory(forceRefresh: true);
      
      // Remove duplicate if exists (same data and type)
      history.removeWhere((h) => h.data == item.data && h.type == item.type);
      
      // Add new item at the beginning
      history.insert(0, item);
      
      // Limit history size
      if (history.length > _maxHistoryItems) {
        history.removeRange(_maxHistoryItems, history.length);
      }

      await _saveHistory(history);
      // Invalidate cache
      _cachedHistory = history;
      _cacheTimestamp = DateTime.now();
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> deleteHistoryItem(String id) async {
    try {
      final history = await getHistory(forceRefresh: true);
      history.removeWhere((item) => item.id == id);
      await _saveHistory(history);
      // Invalidate cache
      _cachedHistory = history;
      _cacheTimestamp = DateTime.now();
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> toggleFavorite(String id) async {
    try {
      final history = await getHistory(forceRefresh: true);
      final index = history.indexWhere((item) => item.id == id);
      
      if (index != -1) {
        history[index] = history[index].copyWith(
          isFavorite: !history[index].isFavorite,
        );
        await _saveHistory(history);
        // Invalidate cache
        _cachedHistory = history;
        _cacheTimestamp = DateTime.now();
      }
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> clearHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_historyKey);
      // Invalidate cache
      _cachedHistory = [];
      _cacheTimestamp = DateTime.now();
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _saveHistory(List<HistoryItem> history) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Optimized JSON encoding
      final historyJson = json.encode(
        history.map((item) => item.toJson()).toList(),
      );
      await prefs.setString(_historyKey, historyJson);
    } catch (e) {
      // Handle error silently
    }
  }

  /// Clear cache (useful for testing or memory management)
  void clearCache() {
    _cachedHistory = null;
    _cacheTimestamp = null;
  }

  List<HistoryItem> filterHistory(
    List<HistoryItem> history,
    String filter,
    String searchQuery,
  ) {
    var filtered = history;

    // Apply filter
    if (filter == 'Scanned') {
      filtered = filtered.where((item) => item.type == 'Scanned').toList();
    } else if (filter == 'Generated') {
      filtered = filtered.where((item) => item.type == 'Generated').toList();
    } else if (filter == 'Favorites' || filter == 'Favc') {
      filtered = filtered.where((item) => item.isFavorite).toList();
    }

    // Apply search
    if (searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      filtered = filtered.where((item) {
        return item.data.toLowerCase().contains(query) ||
            item.displayTitle.toLowerCase().contains(query) ||
            item.category.toLowerCase().contains(query);
      }).toList();
    }

    return filtered;
  }
}

/// Represents a paginated page of history items
class HistoryPage {
  final List<HistoryItem> items;
  final int currentPage;
  final int totalPages;
  final int totalItems;
  final bool hasNextPage;
  final bool hasPreviousPage;

  HistoryPage({
    required this.items,
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
    required this.hasNextPage,
    required this.hasPreviousPage,
  });
}

