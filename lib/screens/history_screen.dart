import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/history_item.dart';
import '../services/history_service.dart';
import '../services/code_action_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _selectedFilter = 'All';
  final TextEditingController _searchController = TextEditingController();
  final HistoryService _historyService = HistoryService();
  List<HistoryItem> _allHistoryItems = [];
  List<HistoryItem> _filteredHistoryItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _filterHistory();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
    });

    final history = await _historyService.getHistory();
    
    setState(() {
      _allHistoryItems = history;
      _isLoading = false;
    });
    
    _filterHistory();
  }

  void _filterHistory() {
    setState(() {
      _filteredHistoryItems = _historyService.filterHistory(
        _allHistoryItems,
        _selectedFilter,
        _searchController.text,
      );
    });
  }

  Future<void> _toggleFavorite(HistoryItem item) async {
    await _historyService.toggleFavorite(item.id);
    await _loadHistory();
  }

  Future<void> _deleteItem(HistoryItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Item'),
        content: const Text('Are you sure you want to delete this item?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _historyService.deleteHistoryItem(item.id);
      await _loadHistory();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Item deleted'),
            backgroundColor: Theme.of(context).colorScheme.primary,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _copyToClipboard(HistoryItem item) async {
    await Clipboard.setData(ClipboardData(text: item.data));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Copied to clipboard'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _clearAllHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All History'),
        content: const Text('Are you sure you want to delete all history items?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear All', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _historyService.clearHistory();
      await _loadHistory();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('All history cleared'),
            backgroundColor: Theme.of(context).colorScheme.primary,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _showItemDetails(HistoryItem item) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: item.iconColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(item.icon, color: item.iconColor, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.displayTitle,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          item.displayType,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SelectableText(
                  item.data,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
              const SizedBox(height: 20),
              // Smart action buttons based on code type
              _buildSmartActionButtons(item),
              const SizedBox(height: 12),
              // Standard action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildDetailActionButton(
                    icon: item.isFavorite ? Icons.star : Icons.star_border,
                    label: item.isFavorite ? 'Unfavorite' : 'Favorite',
                    onTap: () {
                      Navigator.pop(context);
                      _toggleFavorite(item);
                    },
                  ),
                  _buildDetailActionButton(
                    icon: Icons.delete,
                    label: 'Delete',
                    onTap: () {
                      Navigator.pop(context);
                      _deleteItem(item);
                    },
                    color: Colors.red,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSmartActionButtons(HistoryItem item) {
    final category = CodeActionService.detectCategory(item.data);
    final actions = CodeActionService.getAvailableActions(item.data, category);
    
    // Filter out copy, share, and save actions for the main buttons
    final smartActions = actions.where((action) => 
      action.type != ActionType.copy && 
      action.type != ActionType.share &&
      action.type != ActionType.save
    ).toList();
    
    // Always include copy
    smartActions.add(CodeAction(
      type: ActionType.copy,
      label: 'Copy',
      icon: 'content_copy',
    ));

    if (smartActions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: smartActions.map((action) {
        return _buildSmartActionButton(action, item);
      }).toList(),
    );
  }

  Widget _buildSmartActionButton(CodeAction action, HistoryItem item) {
    IconData iconData;
    Color buttonColor;

    switch (action.type) {
      case ActionType.open:
        iconData = Icons.open_in_browser;
        buttonColor = Colors.blue;
        break;
      case ActionType.email:
        iconData = Icons.email;
        buttonColor = Colors.red;
        break;
      case ActionType.call:
        iconData = Icons.call;
        buttonColor = Colors.green;
        break;
      case ActionType.message:
        iconData = Icons.message;
        buttonColor = Colors.orange;
        break;
      case ActionType.pay:
        iconData = Icons.payment;
        buttonColor = Colors.purple;
        break;
      case ActionType.connect:
        iconData = Icons.wifi;
        buttonColor = Colors.indigo;
        break;
      case ActionType.copy:
        iconData = Icons.copy;
        buttonColor = Theme.of(context).colorScheme.primary;
        break;
      default:
        iconData = Icons.more_horiz;
        buttonColor = Colors.grey;
    }

    return ElevatedButton.icon(
      onPressed: () async {
        if (action.type == ActionType.copy) {
          Navigator.pop(context);
          _copyToClipboard(item);
        } else {
          final success = await CodeActionService.executeAction(action, item.data);
          if (mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  success
                      ? '${action.label} executed successfully'
                      : 'Failed to ${action.label.toLowerCase()}',
                ),
                backgroundColor: success
                    ? Colors.green
                    : Theme.of(context).colorScheme.error,
              ),
            );
          }
        }
      },
      icon: Icon(iconData, size: 18),
      label: Text(action.label),
      style: ElevatedButton.styleFrom(
        backgroundColor: buttonColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Widget _buildDetailActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color ?? Theme.of(context).colorScheme.primary, size: 28),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color ?? Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'History',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
        actions: [
          if (_allHistoryItems.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep, color: Colors.black87),
              onPressed: _clearAllHistory,
              tooltip: 'Clear All',
            ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.search, color: Colors.grey),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText: 'Search history...',
                        border: InputBorder.none,
                        hintStyle: TextStyle(color: Colors.grey),
                      ),
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                  if (_searchController.text.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.clear, size: 20),
                      onPressed: () {
                        _searchController.clear();
                      },
                    ),
                ],
              ),
            ),
          ),
          // Filter Tabs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                _buildFilterTab('All', Icons.check),
                const SizedBox(width: 8),
                _buildFilterTab('Scanned', null),
                const SizedBox(width: 8),
                _buildFilterTab('Generated', null),
                const SizedBox(width: 8),
                _buildFilterTab('Favc', null),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // History List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredHistoryItems.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.history,
                              size: 64,
                              color: Colors.grey.shade300,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _allHistoryItems.isEmpty
                                  ? 'No history yet'
                                  : 'No items found',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadHistory,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _filteredHistoryItems.length,
                          itemBuilder: (context, index) {
                            final item = _filteredHistoryItems[index];
                            return _buildHistoryItem(item);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTab(String label, IconData? icon) {
    final bool isSelected = _selectedFilter == label;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedFilter = label;
          });
          _filterHistory();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          decoration: BoxDecoration(
            color: isSelected ? Theme.of(context).colorScheme.primary : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: isSelected ? null : Border.all(color: Colors.black26),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null && isSelected)
                Icon(icon, color: Colors.white, size: 16),
              if (icon != null && isSelected) const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryItem(HistoryItem item) {
    return GestureDetector(
      onTap: () => _showItemDetails(item),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: item.iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                item.icon,
                color: item.iconColor,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.displayTitle,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.displayType,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.timeAgo,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(
                item.isFavorite ? Icons.star : Icons.star_border,
                color: item.isFavorite ? Colors.amber : Colors.grey,
              ),
              onPressed: () => _toggleFavorite(item),
            ),
            IconButton(
              icon: const Icon(Icons.more_vert, color: Colors.grey),
              onPressed: () => _showItemDetails(item),
            ),
          ],
        ),
      ),
    );
  }
}
