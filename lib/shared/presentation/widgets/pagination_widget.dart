import 'package:flutter/material.dart';
import 'package:homecare_mobile/shared/domain/models/pagination_meta.dart';

class PaginationWidget extends StatelessWidget {
  final PaginationMeta pagination;
  final Function(int) onPageChanged;

  const PaginationWidget({
    super.key,
    required this.pagination,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final pages = _generateVisiblePages();

    // Check if there's a gap between visible pages and first/last
    final firstVisiblePage = pages.isNotEmpty ? pages.first : 1;
    final lastVisiblePage = pages.isNotEmpty ? pages.last : pagination.lastPage;

    // Only show first page if there's a gap (at least 2 pages between)
    final showFirstPage = firstVisiblePage > 2;
    final showFirstEllipsis = firstVisiblePage > 2;

    // Only show last page if there's a gap (at least 2 pages between)
    final showLastPage = lastVisiblePage < pagination.lastPage - 1;
    final showLastEllipsis = lastVisiblePage < pagination.lastPage - 1;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(color: colorScheme.outlineVariant, width: 1),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Page info text
          Text(
            'Page ${pagination.currentPage} of ${pagination.lastPage}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          // Navigation buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Previous Button (Icon only)
              IconButton.outlined(
                onPressed: pagination.currentPage > 1
                    ? () => onPageChanged(pagination.currentPage - 1)
                    : null,
                icon: const Icon(Icons.chevron_left),
                iconSize: 20,
                tooltip: 'Previous',
              ),

              const SizedBox(width: 4),

              // First Page (only if there's a gap)
              if (showFirstPage) ...[
                _buildPageButton(1, colorScheme),
                if (showFirstEllipsis) _buildEllipsis(colorScheme),
              ],

              // Page Numbers (max 3 buttons)
              ...pages.map((page) => _buildPageButton(page, colorScheme)),

              // Last Page (only if there's a gap)
              if (showLastPage) ...[
                if (showLastEllipsis) _buildEllipsis(colorScheme),
                _buildPageButton(pagination.lastPage, colorScheme),
              ],

              const SizedBox(width: 4),

              // Next Button (Icon only)
              IconButton.outlined(
                onPressed: pagination.currentPage < pagination.lastPage
                    ? () => onPageChanged(pagination.currentPage + 1)
                    : null,
                icon: const Icon(Icons.chevron_right),
                iconSize: 20,
                tooltip: 'Next',
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Generate visible page numbers
  /// Shows maximum 3 pages centered around current page
  List<int> _generateVisiblePages() {
    final List<int> pages = [];
    final int current = pagination.currentPage;
    final int last = pagination.lastPage;

    // Show only 3 pages max (1 before, current, 1 after)
    int start = current - 1;
    int end = current + 1;

    // Adjust if at the beginning
    if (start < 1) {
      end += 1 - start;
      start = 1;
    }

    // Adjust if at the end
    if (end > last) {
      start -= end - last;
      end = last;
    }

    // Clamp to valid range
    start = start.clamp(1, last);
    end = end.clamp(1, last);

    for (int i = start; i <= end; i++) {
      pages.add(i);
    }

    return pages;
  }

  Widget _buildPageButton(int page, ColorScheme colorScheme) {
    final isActive = page == pagination.currentPage;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: SizedBox(
        width: 40, // Fixed width for consistency
        height: 40,
        child: FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: isActive
                ? colorScheme.primary
                : colorScheme.surfaceContainerHigh,
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: () => onPageChanged(page),
          child: Text(
            page.toString(),
            style: TextStyle(
              color: isActive ? colorScheme.onPrimary : colorScheme.onSurface,
              fontSize: 14,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEllipsis(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        '⋯',
        style: TextStyle(
          color: colorScheme.onSurfaceVariant,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// Alternative: Extra compact version with page jump dialog
/// Use this if even the compact version is too wide
class ExtraCompactPaginationWidget extends StatelessWidget {
  final PaginationMeta pagination;
  final Function(int) onPageChanged;

  const ExtraCompactPaginationWidget({
    super.key,
    required this.pagination,
    required this.onPageChanged,
  });

  void _showPageJumpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _PageJumpDialog(
        pagination: pagination,
        onPageSelected: (page) {
          Navigator.pop(context);
          onPageChanged(page);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(color: colorScheme.outlineVariant, width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // First Page
          IconButton.outlined(
            onPressed: pagination.currentPage > 1
                ? () => onPageChanged(1)
                : null,
            icon: const Icon(Icons.first_page),
            iconSize: 20,
            tooltip: 'First',
          ),

          // Previous
          IconButton.outlined(
            onPressed: pagination.currentPage > 1
                ? () => onPageChanged(pagination.currentPage - 1)
                : null,
            icon: const Icon(Icons.chevron_left),
            iconSize: 20,
            tooltip: 'Previous',
          ),

          // Page selector
          Expanded(
            child: InkWell(
              onTap: () => _showPageJumpDialog(context),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Page ${pagination.currentPage}',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'of ${pagination.lastPage}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Next
          IconButton.outlined(
            onPressed: pagination.currentPage < pagination.lastPage
                ? () => onPageChanged(pagination.currentPage + 1)
                : null,
            icon: const Icon(Icons.chevron_right),
            iconSize: 20,
            tooltip: 'Next',
          ),

          // Last Page
          IconButton.outlined(
            onPressed: pagination.currentPage < pagination.lastPage
                ? () => onPageChanged(pagination.lastPage)
                : null,
            icon: const Icon(Icons.last_page),
            iconSize: 20,
            tooltip: 'Last',
          ),
        ],
      ),
    );
  }
}

/// Dialog for jumping to specific page
class _PageJumpDialog extends StatefulWidget {
  final PaginationMeta pagination;
  final Function(int) onPageSelected;

  const _PageJumpDialog({
    required this.pagination,
    required this.onPageSelected,
  });

  @override
  State<_PageJumpDialog> createState() => _PageJumpDialogState();
}

class _PageJumpDialogState extends State<_PageJumpDialog> {
  late final TextEditingController _controller;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.pagination.currentPage.toString(),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    final page = int.tryParse(_controller.text);

    if (page == null) {
      setState(() => _errorText = 'Please enter a valid number');
      return;
    }

    if (page < 1 || page > widget.pagination.lastPage) {
      setState(
        () => _errorText =
            'Page must be between 1 and ${widget.pagination.lastPage}',
      );
      return;
    }

    widget.onPageSelected(page);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Jump to Page'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Enter page number (1-${widget.pagination.lastPage})',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Page',
              errorText: _errorText,
              border: const OutlineInputBorder(),
            ),
            onSubmitted: (_) => _handleSubmit(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _handleSubmit, child: const Text('Go')),
      ],
    );
  }
}
