import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/app_colors.dart';
import '../../../../dashboard/models/address_lookup.dart';
import '../../../orders/presentation/pages/block_picker_page.dart';
import '../../../orders/presentation/pages/building_picker_page.dart';
import '../../../orders/presentation/pages/road_picker_page.dart';
import '../../domain/entities/address_entity.dart';
import '../../domain/repositories/address_repository.dart';
import '../bloc/address_form_bloc.dart';

class AddressFormPage extends StatefulWidget {
  const AddressFormPage({
    super.key,
    required this.address,
    required this.token,
    this.isCreate = false,
    required this.repository,
    this.forcePrimary = false,
  });

  final AddressEntity address;
  final String token;
  final bool isCreate;
  final AddressRepository repository;
  final bool forcePrimary;

  @override
  State<AddressFormPage> createState() => _AddressFormPageState();
}

class _AddressFormPageState extends State<AddressFormPage> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _flatCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _customBuildingCtrl;
  bool _isPrimary = false;
  bool _initialPrimary = false;

  BlockInfo? _block;
  RoadInfo? _road;
  BuildingInfo? _building;
  int? _blockId;
  int? _roadId;
  int? _buildingId;
  String _blockDisplay = '';
  String _roadDisplay = '';
  String _buildingDisplay = '';
  String _roadName = '';
  String _buildingName = '';
  String _blockCodeValue = '';
  String _roadValue = '';
  String _buildingValue = '';
  String _countryCode = '+973';
  static const Map<String, int> _phoneCodeLengths = {
    '+973': 8, // Bahrain
    '+91': 10, // India
    '+966': 9, // Saudi Arabia
    '+971': 9, // UAE
    '+965': 8, // Kuwait
    '+974': 8, // Qatar
    '+968': 8, // Oman
    '+1': 10, // US/Canada
    '+880': 10, // Bangladesh
    '+92': 10, // Pakistan
    '+44': 10, // UK (without leading zero)
    '+20': 10, // Egypt (mobile, without leading zero)
    '+62': 10, // Indonesia (common length)
    '+60': 9, // Malaysia (common length)
    '+63': 10, // Philippines
    '+234': 10, // Nigeria (without leading zero)
    '+254': 9, // Kenya
    '+255': 9, // Tanzania
    '+256': 9, // Uganda
    '+94': 9, // Sri Lanka
    '+977': 10, // Nepal
  };

  @override
  void initState() {
    super.initState();
    final a = widget.address;
    _titleCtrl = TextEditingController(text: a.title);
    _flatCtrl = TextEditingController(text: a.line1);
    _phoneCtrl = TextEditingController(text: a.phone);
    _customBuildingCtrl = TextEditingController(text: a.buildingCode);
    _isPrimary = widget.isCreate
        ? (widget.forcePrimary ? true : false)
        : a.isPrimary;
    _initialPrimary = widget.isCreate
        ? (widget.forcePrimary ? true : false)
        : a.isPrimary;
    _blockId = int.tryParse(a.blockCode);
    _blockCodeValue = a.blockCode;
    _roadValue = a.roadCode;
    _buildingValue = a.buildingCode;
    _blockDisplay = a.blockName.isNotEmpty && a.blockCode.isNotEmpty
        ? '${a.blockName} - ${a.blockCode}'
        : (a.blockCode.isNotEmpty ? 'Block ${a.blockCode}' : '');
    _roadDisplay = a.roadCode.isNotEmpty ? 'Road ${a.roadCode}' : '';
    _buildingDisplay = a.buildingCode.isNotEmpty ? 'Building ${a.buildingCode}' : '';
    _roadName = a.roadCode;
    _buildingName = a.buildingCode;
    final existingPhone = a.phone;
    if (existingPhone.startsWith('+')) {
      final parts = existingPhone.split(' ');
      if (parts.length >= 2) {
        _countryCode = parts.first;
        _phoneCtrl.text = parts.sublist(1).join(' ');
      }
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _flatCtrl.dispose();
    _phoneCtrl.dispose();
    _customBuildingCtrl.dispose();
    super.dispose();
  }

  Map<String, dynamic> _payload() {
    final blockInput = _blockCodeValue.trim();
    final blockId = _block?.id ?? _blockId ?? int.tryParse(blockInput);
    final roadInput = _roadValue.trim();
    final buildingInput = _buildingValue.trim();
    final roadField = _road?.code ?? (_roadName.trim().isNotEmpty ? _roadName.trim() : roadInput);
    final buildingField = _building?.code ??
        (_buildingName.trim().isNotEmpty ? _buildingName.trim() : buildingInput);
    final phoneDigits = _phoneCtrl.text.trim();
    return {
      'address_title': _titleCtrl.text.trim(),
      'address_line_one': _flatCtrl.text.trim(),
      'address_line_two': '',
      'block_id': blockId ?? blockInput,
      'road_id': roadField,
      'building_id': buildingField,
      'is_primary': _isPrimary,
      'phone': '$_countryCode $phoneDigits',
    };
  }

  Widget _rectField({
    required String label,
    TextEditingController? controller,
    String initial = '',
    TextInputType keyboard = TextInputType.text,
    int maxLines = 1,
    required ValueChanged<String> onChanged,
    Key? fieldKey,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        key: fieldKey,
        controller: controller,
        initialValue: controller == null ? initial : null,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF66258E), width: 1.5),
          ),
        ),
        keyboardType: keyboard,
        onChanged: onChanged,
      ),
    );
  }

  Widget _phoneRow({
    required String title,
    required String countryCode,
    required String number,
    required TextInputType keyboard,
    required ValueChanged<String> onCodeChanged,
    required ValueChanged<String> onNumberChanged,
  }) {
    final codes = _phoneCodeLengths.keys.toList()..sort();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: const Color(0xFFE5E7EB)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: countryCode,
                  items: codes
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) => v == null ? null : onCodeChanged(v),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _rectField(
                label: '',
                initial: number,
                keyboard: keyboard,
                onChanged: onNumberChanged,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _pickBlock(BuildContext blocCtx) async {
    _dismissKeyboard(context);
    final result = await Navigator.of(context).push<BlockInfo>(
      MaterialPageRoute(
        builder: (_) => BlockPickerPage(
          token: widget.token,
          selectedBlockId: _block?.id,
          initialQuery: '',
        ),
      ),
    );
    if (result != null && mounted) {
      blocCtx.read<AddressFormBloc>().add(const AddressFormClearRoads());
      setState(() {
        _block = result;
        _blockId = result.id;
        _blockCodeValue = result.code;
        _blockDisplay = '${result.name} - ${result.code}';
        _road = null;
        _roadId = null;
        _roadName = '';
        _roadValue = '';
        _roadDisplay = '';
        _building = null;
        _buildingId = null;
        _buildingName = '';
        _buildingValue = '';
        _buildingDisplay = '';
        _customBuildingCtrl.text = '';
      });
    }
  }

  Future<void> _pickRoad(BuildContext blocCtx) async {
    if (_blockId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select block first')),
      );
      return;
    }
    _dismissKeyboard(context);
    final result = await Navigator.of(context).push<RoadPickerResult>(
      MaterialPageRoute(
        builder: (_) => RoadPickerPage(
          token: widget.token,
          blockId: _blockId!,
          selectedRoadId: _road?.id,
          initialQuery: _roadName,
        ),
      ),
    );
    if (result != null && mounted) {
      blocCtx.read<AddressFormBloc>().add(const AddressFormClearBuildings());
      setState(() {
        _road = result.road;
        _roadId = result.road?.id;
        _roadName = result.customName ?? result.road?.name ?? '';
        _roadValue = result.road?.code ?? _roadName;
        _roadDisplay = _roadName.isNotEmpty && result.road != null
            ? '$_roadName - ${result.road!.code}'
            : (_roadName.isNotEmpty ? _roadName : _roadValue);
        _building = null;
        _buildingId = null;
        _buildingName = '';
        _buildingValue = '';
        _buildingDisplay = '';
        _customBuildingCtrl.text = '';
      });
    }
  }

  Future<void> _pickBuilding(BuildContext blocCtx) async {
    if (_blockId == null || (_roadId == null && _roadName.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select block and road first')),
      );
      return;
    }
    if (_roadId == null && _roadName.isNotEmpty) {
      // Custom road -> building is text entry; do nothing here.
      return;
    }
    _dismissKeyboard(context);
    final result = await Navigator.of(context).push<BuildingPickerResult>(
      MaterialPageRoute(
        builder: (_) => BuildingPickerPage(
          token: widget.token,
          blockId: _blockId!,
          roadId: _roadId!,
          selectedBuildingId: _building?.id,
          initialQuery: _buildingName,
        ),
      ),
    );
    if (result != null && mounted) {
      setState(() {
        _building = result.building;
        _buildingId = result.building?.id;
        _buildingName = result.customName ?? result.building?.name ?? '';
        _buildingValue = result.building?.code ?? _buildingName;
        _buildingDisplay = _buildingName.isNotEmpty && result.building != null
            ? '$_buildingName - ${result.building!.code}'
            : (_buildingName.isNotEmpty ? _buildingName : _buildingValue);
        _customBuildingCtrl.text = _buildingName;
      });
    }
  }

  void _dismissKeyboard(BuildContext context) {
    FocusScope.of(context).unfocus();
    FocusManager.instance.primaryFocus?.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    Widget field({
      required String label,
      required TextEditingController controller,
      TextInputType inputType = TextInputType.text,
      int maxLines = 1,
    }) {
      return TextField(
        controller: controller,
        keyboardType: inputType,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF66258E), width: 1.5),
          ),
        ),
      );
    }

    return BlocProvider(
      create: (_) => AddressFormBloc(
        repository: widget.repository,
        token: widget.token,
      ),
      child: BlocListener<AddressFormBloc, AddressFormState>(
        listenWhen: (p, c) => p.success != c.success || p.error != c.error,
        listener: (formCtx, state) {
          if (state.success) {
            ScaffoldMessenger.of(formCtx).showSnackBar(
              const SnackBar(content: Text('Address updated')),
            );
            Navigator.of(formCtx).pop(true);
          } else if (state.error != null) {
            ScaffoldMessenger.of(formCtx).showSnackBar(
              SnackBar(content: Text(state.error!)),
            );
          }
        },
        child: Builder(
          builder: (blocCtx) => Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              title: Text(widget.isCreate ? 'Add Address' : 'Edit Address'),
            ),
          body: SingleChildScrollView(
            
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                field(label: 'Name', controller: _titleCtrl),
                const SizedBox(height: 12),
                BlocBuilder<AddressFormBloc, AddressFormState>(
                  builder: (context, formState) {
                    final blockLabel =
                        _blockDisplay.isNotEmpty ? _blockDisplay : 'Select block';
                    final roadLabel =
                        _roadDisplay.isNotEmpty ? _roadDisplay : 'Select road';
                    final buildingLabel = _buildingDisplay.isNotEmpty
                        ? _buildingDisplay
                        : (_roadId == null && _roadName.isNotEmpty
                            ? 'Enter building'
                            : 'Select building');
                    return Column(
                      children: [
                        _selectorTile(
                          label: 'Block',
                          value: blockLabel,
                          enabled: !formState.blockLoading,
                          trailing: formState.blockLoading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.chevron_right),
                          onTap: () => _pickBlock(blocCtx),
                        ),
                        const SizedBox(height: 12),
                        _selectorTile(
                          label: 'Road',
                          value: roadLabel,
                          enabled: _blockId != null && !formState.roadLoading,
                          trailing: formState.roadLoading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.chevron_right),
                          onTap: _blockId == null ? null : () => _pickRoad(blocCtx),
                        ),
                        const SizedBox(height: 12),
                        if (_roadId == null && _roadName.isNotEmpty)
                          _rectField(
                            label: 'Building',
                            controller: _customBuildingCtrl,
                            onChanged: (v) => setState(() {
                              _buildingName = v;
                              _buildingValue = v;
                              _buildingId = null;
                              _building = null;
                              _buildingDisplay = v;
                            }),
                            fieldKey: const ValueKey('custom-building'),
                          )
                        else
                          _selectorTile(
                            label: 'Building',
                            value: buildingLabel,
                            enabled: _roadId != null && !formState.buildingLoading,
                            trailing: formState.buildingLoading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.chevron_right),
                            onTap:
                                _roadId == null ? null : () => _pickBuilding(blocCtx),
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 12),
                _rectField(
                  label: 'Flat / Office No.',
                  initial: _flatCtrl.text,
                  keyboard: TextInputType.streetAddress,
                  onChanged: (v) => _flatCtrl.text = v,
                ),
                const SizedBox(height: 12),
                _phoneRow(
                  title: 'Phone',
                  countryCode: _countryCode,
                  number: _phoneCtrl.text,
                  keyboard: TextInputType.phone,
                  onCodeChanged: (v) => setState(() => _countryCode = v),
                  onNumberChanged: (v) => _phoneCtrl.text = v,
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Set as primary'),
                  value: _isPrimary,
                  onChanged: (_initialPrimary || widget.forcePrimary)
                      ? null
                      : (v) => setState(() => _isPrimary = v),
                ),
                const SizedBox(height: 18),
                BlocBuilder<AddressFormBloc, AddressFormState>(
                  builder: (context, state) {
                    return SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: state.submitting
                            ? null
                            : () {
                                final title = _titleCtrl.text.trim();
                                final flat = _flatCtrl.text.trim();
                                final validationError = _validateForm(
                                  title: title,
                                  flat: flat,
                                  phone: _phoneCtrl.text.trim(),
                                );
                                if (validationError != null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(validationError)),
                                  );
                                  return;
                                }
                                final event = widget.isCreate
                                    ? AddressFormCreate(payload: _payload())
                                    : AddressFormSubmit(
                                        id: widget.address.id,
                                        payload: _payload(),
                                      );
                                blocCtx.read<AddressFormBloc>().add(event);
                              },
                        child: Text(
                          state.submitting ? 'Saving...' : 'Save',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    ));
  }

  Widget _selectorTile({
    required String label,
    required String value,
    bool enabled = true,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: enabled ? Colors.black : Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      color: enabled ? const Color(0xFF4B5563) : Colors.grey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }

  bool _isValidPhone(String code, String number) {
    final rawDigits = number.replaceAll(RegExp(r'\D'), '');
    if (rawDigits.isEmpty) return false;
    final codeDigits = code.trim().replaceAll(RegExp(r'\D'), '');
    final digits = rawDigits.startsWith(codeDigits)
        ? rawDigits.substring(codeDigits.length)
        : rawDigits;
    final expected = _phoneCodeLengths[code.trim()];
    if (expected != null) {
      return digits.length == expected;
    }
    return digits.length >= 7 && digits.length <= 12;
  }

  String? _validateForm({
    required String title,
    required String flat,
    required String phone,
  }) {
    if (title.isEmpty) return 'Name is required';
    if (flat.isEmpty) return 'Flat/Office number is required';

    final hasBlock = _blockId != null || _blockCodeValue.trim().isNotEmpty;
    if (!hasBlock) return 'Please select block';

    final hasRoad = _roadId != null ||
        _roadName.trim().isNotEmpty ||
        _roadValue.trim().isNotEmpty;
    if (!hasRoad) return 'Please select or enter road';

    final hasBuilding = _roadId != null
        ? (_buildingId != null ||
            _buildingName.trim().isNotEmpty ||
            _buildingValue.trim().isNotEmpty ||
            _customBuildingCtrl.text.trim().isNotEmpty)
        : (_buildingName.trim().isNotEmpty ||
            _buildingValue.trim().isNotEmpty ||
            _customBuildingCtrl.text.trim().isNotEmpty);
    if (!hasBuilding) return 'Please select or enter building';

    if (phone.trim().isEmpty) return 'Phone number is required';
    if (!_isValidPhone(_countryCode, phone.trim())) {
      return 'Enter a valid phone number for $_countryCode';
    }
    return null;
  }
}
