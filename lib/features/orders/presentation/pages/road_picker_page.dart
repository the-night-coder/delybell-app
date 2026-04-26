import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/app_colors.dart';
import '../../../../dashboard/data/domestic_order_repository.dart';
import '../../../../dashboard/models/address_lookup.dart';

class RoadPickerResult {
  RoadPickerResult({this.road, this.customName});

  final RoadInfo? road;
  final String? customName;
}

class RoadPickerPage extends StatefulWidget {
 RoadPickerPage({
    super.key,
    required this.token,
    required this.blockId,
    this.selectedRoadId,
    this.initialQuery = '',
    DomesticOrderRepository? repository,
  }) : repository = repository ?? DomesticOrderRepository();

  final String token;
  final int blockId;
  final int? selectedRoadId;
  final String initialQuery;
  final DomesticOrderRepository repository;

  @override
  State<RoadPickerPage> createState() => _RoadPickerPageState();
}

class _RoadPickerPageState extends State<RoadPickerPage> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  List<RoadInfo> _items = [];
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
      final roads = await widget.repository.fetchRoads(
        token: widget.token,
        blockId: widget.blockId,
        search: search,
      );
      if (!mounted) return;
      setState(() {
        _items = roads;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _items = [];
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
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
    final canAddCustom = _searchController.text.trim().isNotEmpty &&
        !_items.any((r) => r.name.toLowerCase() == _searchController.text.trim().toLowerCase());

    return Scaffold(
      appBar: AppBar(title: const Text('Select Road')),
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
                  hintText: 'Search road',
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
            if (canAddCustom)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                  ),
                  onPressed: () {
                    Navigator.of(context).pop(
                      RoadPickerResult(customName: _searchController.text.trim()),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: Text("Use \"${_searchController.text.trim()}\""),
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
                            child: Center(child: Text('No roads found')),
                          ),
                        ],
                      )
                    else
                      ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        itemCount: _items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 6),
                        itemBuilder: (context, index) {
                          final road = _items[index];
                          final isSelected = widget.selectedRoadId != null &&
                              widget.selectedRoadId == road.id;
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
                                road.name,
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                              subtitle: road.code.isEmpty
                                  ? null
                                  : Text(
                                      road.code,
                                      style: TextStyle(color: colors.mutedText),
                                    ),
                              trailing: isSelected
                                  ? Icon(Icons.check_circle, color: colors.primary)
                                  : const Icon(Icons.chevron_right),
                              onTap: () => Navigator.of(context).pop(
                                RoadPickerResult(road: road),
                              ),
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
