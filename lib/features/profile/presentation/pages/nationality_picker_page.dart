import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/app_colors.dart';
import '../../data/nationality_repository_impl.dart';
import '../../domain/repositories/nationality_repository.dart';
import '../bloc/nationality_bloc.dart';

class NationalityPickerPage extends StatefulWidget {
 NationalityPickerPage({
    super.key,
    required this.token,
    this.selectedId,
    NationalityRepository? repository,
  }) : repository = repository ?? NationalityRepositoryImpl();

  final String token;
  final int? selectedId;
  final NationalityRepository repository;

  @override
  State<NationalityPickerPage> createState() => _NationalityPickerPageState();
}

class _NationalityPickerPageState extends State<NationalityPickerPage> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(BuildContext context, String value) {
    setState(() {});
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      context.read<NationalityBloc>().add(
            NationalitiesRequested(search: value.trim()),
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return BlocProvider(
      create: (_) => NationalityBloc(
        repository: widget.repository,
        token: widget.token,
      )..add(const NationalitiesRequested()),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Select Nationality'),
        ),
        body: SafeArea(
          child: Builder(
            builder: (blocCtx) => Column(
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
                                _onSearchChanged(blocCtx, '');
                              },
                            ),
                      hintText: 'Search nationality',
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
                    onChanged: (value) => _onSearchChanged(blocCtx, value),
                    onSubmitted: (value) => _onSearchChanged(blocCtx, value),
                  ),
                ),
                Expanded(
                  child: BlocBuilder<NationalityBloc, NationalityState>(
                    builder: (context, state) {
                      if (state.loading && state.items.isEmpty) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (state.error != null && state.items.isEmpty) {
                        return _ErrorView(
                          message: state.error!,
                          onRetry: () => blocCtx
                              .read<NationalityBloc>()
                              .add(NationalitiesRequested(search: state.search)),
                        );
                      }

                      if (state.items.isEmpty) {
                        return const Center(child: Text('No nationalities found'));
                      }

                      return Stack(
                        children: [
                          RefreshIndicator(
                            onRefresh: () async {
                              blocCtx
                                  .read<NationalityBloc>()
                                  .add(NationalitiesRequested(search: state.search));
                            },
                            child: ListView.separated(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                              itemCount: state.items.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 6),
                              itemBuilder: (context, index) {
                                final nationality = state.items[index];
                                final isSelected = widget.selectedId != null &&
                                    nationality.id == widget.selectedId;
                                return Card(
                                  elevation: 0,
                                  color: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(
                                      color: isSelected
                                          ? colors.primary
                                          : colors.border,
                                    ),
                                  ),
                                  child: ListTile(
                                    title: Text(
                                      nationality.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    subtitle: nationality.shortCode.isEmpty
                                        ? null
                                        : Text(
                                            nationality.shortCode,
                                            style: TextStyle(color: colors.mutedText),
                                          ),
                                    trailing: isSelected
                                        ? Icon(Icons.check_circle, color: colors.primary)
                                        : const Icon(Icons.chevron_right),
                                    onTap: () => Navigator.of(context).pop(nationality),
                                  ),
                                );
                              },
                            ),
                          ),
                          if (state.loading)
                            const Positioned(
                              left: 0,
                              right: 0,
                              top: 0,
                              child: LinearProgressIndicator(minHeight: 2),
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
