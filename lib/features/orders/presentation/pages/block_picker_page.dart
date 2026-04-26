import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/app_colors.dart';
import '../../../../dashboard/data/domestic_order_repository.dart';
import '../../../../dashboard/models/address_lookup.dart';

class BlockPickerPage extends StatefulWidget {
 BlockPickerPage({
    super.key,
    required this.token,
    this.selectedBlockId,
    this.initialQuery = '',
    DomesticOrderRepository? repository,
  }) : repository = repository ?? DomesticOrderRepository();

  final String token;
  final int? selectedBlockId;
  final String initialQuery;
  final DomesticOrderRepository repository;

  @override
  State<BlockPickerPage> createState() => _BlockPickerPageState();
}

class _BlockPickerPageState extends State<BlockPickerPage> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  List<BlockInfo> _items = [];
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.initialQuery;
    _fetch();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    setState(() {});
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () => _fetch(search: value.trim()));
  }

  Future<void> _fetch({String search = ''}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final blocks = await widget.repository.fetchBlocks(
        token: widget.token,
        search: search,
      );
      setState(() {
        _items = blocks;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _items = [];
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>() ??
        const AppColors(
          primary: Color(0xFF66258E),
          primarySoft: Color(0xFFEDE7F6),
          border: Color(0xFFE5E7EB),
          surface: Colors.white,
          mutedText: Color(0xFF6B7280),
          danger: Colors.red,
          success: Colors.green,
        );

    return Scaffold(
      appBar: AppBar(title: const Text('Select Block')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _onSearchChanged('');
                          },
                        ),
                  hintText: 'Search block',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: colors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: colors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: colors.primary),
                  ),
                ),
                textInputAction: TextInputAction.search,
                onChanged: _onSearchChanged,
                onSubmitted: _onSearchChanged,
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => _fetch(search: _searchController.text.trim()),
                child: Stack(
                  children: [
                    if (_error != null && _items.isEmpty)
                      ListView(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              children: [
                                Text(_error!, textAlign: TextAlign.center),
                                const SizedBox(height: 12),
                                ElevatedButton(
                                  onPressed: () => _fetch(search: _searchController.text.trim()),
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      )
                    else if (_items.isEmpty)
                      ListView(
                        children: const [
                          Padding(
                            padding: EdgeInsets.all(24),
                            child: Center(child: Text('No blocks found')),
                          ),
                        ],
                      )
                    else
                      ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        itemCount: _items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 6),
                        itemBuilder: (context, index) {
                          final block = _items[index];
                          final isSelected =
                              widget.selectedBlockId != null && widget.selectedBlockId == block.id;
                          return Card(
                            elevation: 0,
                            color: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: isSelected ? colors.primary : colors.border,
                              ),
                            ),
                            child: ListTile(
                              title: Text(
                                block.name,
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                              subtitle: block.code.isEmpty
                                  ? null
                                  : Text(
                                      block.code,
                                      style: TextStyle(color: colors.mutedText),
                                    ),
                              trailing: isSelected
                                  ? Icon(Icons.check_circle, color: colors.primary)
                                  : const Icon(Icons.chevron_right),
                              onTap: () => Navigator.of(context).pop(block),
                            ),
                          );
                        },
                      ),
                    if (_loading)
                      const Positioned(
                        left: 0,
                        right: 0,
                        top: 0,
                        child: LinearProgressIndicator(minHeight: 2),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
