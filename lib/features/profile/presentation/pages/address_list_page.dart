import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/app_colors.dart';
import '../../data/address_repository_impl.dart';
import '../../domain/entities/address_entity.dart';
import '../bloc/address_list_bloc.dart';
import 'address_add_page.dart';
import 'address_form_page.dart';

class AddressListPage extends StatelessWidget {
  const AddressListPage({super.key, required this.token});

  final String token;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final repo = AddressRepositoryImpl();

    return BlocProvider(
      create: (_) =>
          AddressListBloc(repository: repo, token: token)..add(const AddressListRequested()),
      child: BlocListener<AddressListBloc, AddressListState>(
        listenWhen: (p, c) => c.message != null || c.error != null,
        listener: (context, state) {
          if (state.message != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message!)),
            );
          }
          if (state.error != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.error!)),
            );
          }
        },
        child: Builder(
          builder: (scaffoldCtx) => Scaffold(
            appBar: AppBar(
              title: const Text(
                'Pickup Addresses',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            floatingActionButton: FloatingActionButton.extended(
              backgroundColor: colors.primary,
              onPressed: () {
                Navigator.of(scaffoldCtx)
                    .push<bool>(
                  MaterialPageRoute(
                    builder: (_) => AddressAddPage(
                      token: token,
                      repository: repo,
                      forcePrimary:
                          scaffoldCtx.read<AddressListBloc>().state.addresses.isEmpty,
                    ),
                  ),
                )
                    .then((created) {
                  if (created == true && scaffoldCtx.mounted) {
                    scaffoldCtx
                        .read<AddressListBloc>()
                        .add(const AddressListRequested());
                  }
                });
              },
              label: const Text(
                'Add Address',
                style: TextStyle(color: Colors.white),
              ),
              icon: const Icon(Icons.add, color: Colors.white),
            ),
            body: SafeArea(
              child: Builder(
                builder: (blocCtx) => RefreshIndicator(
                  onRefresh: () async {
                    blocCtx.read<AddressListBloc>().add(const AddressListRequested());
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: BlocBuilder<AddressListBloc, AddressListState>(
                      builder: (context, state) {
                        if (state.loading) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (state.error != null) {
                          return ListView(
                            children: [
                              SizedBox(
                                height: MediaQuery.of(context).size.height * 0.4,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      state.error!,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(elevation: 0),
                                      onPressed: () => blocCtx
                                          .read<AddressListBloc>()
                                          .add(const AddressListRequested()),
                                      icon: const Icon(Icons.refresh),
                                      label: const Text('Reload'),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }
                        if (state.addresses.isEmpty) {
                          return ListView(
                            children: const [
                              SizedBox(
                                height: 200,
                                child: Center(child: Text('No addresses found')),
                              ),
                            ],
                          );
                        }
                        return ListView.builder(
                          itemCount: state.addresses.length,
                          itemBuilder: (context, index) {
                            final address = state.addresses[index];
                            return _AddressCard(
                              address: address,
                              onActions: (action) {
                            switch (action) {
                              case _AddressAction.edit:
                                final route = MaterialPageRoute<bool>(
                                  builder: (_) => AddressFormPage(
                                    address: address,
                                    token: token,
                                    repository: repo,
                                  ),
                                );
                                Navigator.of(context).push<bool>(route).then(
                                  (changed) {
                                    if (changed == true && blocCtx.mounted) {
                                      blocCtx
                                          .read<AddressListBloc>()
                                          .add(const AddressListRequested());
                                    }
                                  },
                                );
                                break;
                              case _AddressAction.delete:
                                context.read<AddressListBloc>().add(
                                      AddressDeleteRequested(address.id),
                                    );
                                break;
                              case _AddressAction.primary:
                                context.read<AddressListBloc>().add(
                                      AddressMarkPrimaryRequested(address.id),
                                    );
                                // after marking, also refresh list for accuracy
                                context
                                    .read<AddressListBloc>()
                                    .add(const AddressListRequested());
                                break;
                            }
                          },
                        );
                      },
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum _AddressAction { edit, delete, primary }

class _AddressCard extends StatelessWidget {
  const _AddressCard({required this.address, required this.onActions});

  final AddressEntity address;
  final ValueChanged<_AddressAction> onActions;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    String subtitle() {
      String blockPart() {
        if (address.blockName.isNotEmpty && address.blockCode.isNotEmpty) {
          return '${address.blockName} - ${address.blockCode}';
        }
        if (address.blockName.isNotEmpty) return address.blockName;
        if (address.blockCode.isNotEmpty) return 'Block ${address.blockCode}';
        return '';
      }

      final detailParts = <String>[
        if (address.buildingCode.isNotEmpty) 'Building ${address.buildingCode}',
        if (address.roadCode.isNotEmpty) 'Road ${address.roadCode}',
        blockPart(),
      ].where((e) => e.isNotEmpty).join(', ');

      final lines = <String>[
        if (address.line1.isNotEmpty) address.line1,
        if (address.line2.isNotEmpty) address.line2,
        if (detailParts.isNotEmpty) detailParts,
      ];

      return lines.where((p) => p.isNotEmpty).join('\n');
    }

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: colors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                InkWell(
                  onTap: address.isPrimary
                      ? null
                      : () => onActions(_AddressAction.primary),
                  customBorder: const CircleBorder(),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      address.isPrimary
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      color: address.isPrimary ? colors.primary : colors.mutedText,
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    address.title.isEmpty ? 'Address' : address.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ),
                PopupMenuButton<_AddressAction>(
                  onSelected: onActions,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: _AddressAction.edit,
                      child: Text('Edit'),
                    ),
                    const PopupMenuItem(
                      value: _AddressAction.delete,
                      child: Text('Delete'),
                    ),
                    if (!address.isPrimary)
                      const PopupMenuItem(
                        value: _AddressAction.primary,
                        child: Text('Mark as primary'),
                      ),
                  ],
                ),
              ],
            ),
            if (address.isPrimary)
              Container(
                margin: const EdgeInsets.only(top: 6),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Primary',
                  style: TextStyle(
                    color: colors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            const SizedBox(height: 10),
            Text(
              subtitle(),
              style: TextStyle(
                color: colors.mutedText,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (address.phone.isNotEmpty) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.phone_in_talk_outlined, size: 16, color: Colors.black54),
                  const SizedBox(width: 6),
                  Text(
                    address.phone,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
