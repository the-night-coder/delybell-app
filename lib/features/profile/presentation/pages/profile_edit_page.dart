import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/app_colors.dart';
import '../../../../core/session_manager.dart';
import '../../data/profile_repository_impl.dart';
import '../../domain/entities/nationality.dart';
import '../bloc/profile_edit_bloc.dart';
import 'nationality_picker_page.dart';

class ProfileEditPage extends StatefulWidget {
  const ProfileEditPage({
    super.key,
    required this.token,
    required this.userType,
    this.initialFirstName = '',
    this.initialLastName = '',
    this.initialEmail = '',
    this.initialPhone = '',
    this.initialCompanyName = '',
    this.initialCompanyReg = '',
    this.initialVatNumber = '',
    this.initialAddressLine = '',
    this.initialFirstNameAr = '',
    this.initialLastNameAr = '',
    this.initialNationalityId = 0,
    this.initialNationalityName = '',
    this.initialPackageDescription = '',
  });

  final String token;
  final int userType;
  final String initialFirstName;
  final String initialLastName;
  final String initialEmail;
  final String initialPhone;
  final String initialCompanyName;
  final String initialCompanyReg;
  final String initialVatNumber;
  final String initialAddressLine;
  final String initialFirstNameAr;
  final String initialLastNameAr;
  final int initialNationalityId;
  final String initialNationalityName;
  final String initialPackageDescription;

  @override
  State<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> {
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _company = TextEditingController();
  final _companyReg = TextEditingController();
  final _addressLine = TextEditingController();
  final _vat = TextEditingController();
  final _firstNameAr = TextEditingController();
  final _lastNameAr = TextEditingController();
  final _packageDescription = TextEditingController();
  Nationality? _selectedNationality;
  bool _submitting = false;
  String _countryCode = '+973';

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _phone.dispose();
    _company.dispose();
    _companyReg.dispose();
    _addressLine.dispose();
    _vat.dispose();
    _firstNameAr.dispose();
    _lastNameAr.dispose();
    _packageDescription.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    String parseCountryCode(String raw) {
      final digits = raw.replaceAll(' ', '');
      final match = RegExp(r'^\+?(\d{1,3})(.*)$').firstMatch(digits);
      if (match != null) {
        return '+${match.group(1)}';
      }
      return _countryCode;
    }

    String parseNumber(String raw) {
      final digits = raw.replaceAll(' ', '');
      final match = RegExp(r'^\+?(\d{1,3})(.*)$').firstMatch(digits);
      if (match != null) {
        return match.group(2) ?? '';
      }
      return raw;
    }

    _firstName.text = widget.initialFirstName;
    _lastName.text = widget.initialLastName;
    _email.text = widget.initialEmail;
    if (widget.initialPhone.isNotEmpty) {
      _countryCode = parseCountryCode(widget.initialPhone);
      _phone.text = parseNumber(widget.initialPhone);
    }
    _company.text = widget.initialCompanyName;
    _companyReg.text = widget.initialCompanyReg;
    _vat.text = widget.initialVatNumber;
    _addressLine.text = widget.initialAddressLine;
    _firstNameAr.text = widget.initialFirstNameAr;
    _lastNameAr.text = widget.initialLastNameAr;
    _packageDescription.text = widget.initialPackageDescription;
    if (widget.initialNationalityId != 0 ||
        widget.initialNationalityName.isNotEmpty) {
      _selectedNationality = Nationality(
        id: widget.initialNationalityId,
        name: widget.initialNationalityName.isNotEmpty
            ? widget.initialNationalityName
            : 'Saved (#${widget.initialNationalityId})',
        shortCode: '',
      );
    }
  }

  Map<String, dynamic> _payload() {
    String formattedPhone() {
      final digits = _phone.text.replaceAll(RegExp(r'\D'), '');
      final codeDigits = _countryCode.replaceAll(RegExp(r'\D'), '');
      final stripped =
          digits.startsWith(codeDigits) ? digits.substring(codeDigits.length) : digits;
      return '$_countryCode $stripped';
    }

    return {
      'first_name': _firstName.text.trim(),
      'last_name': _lastName.text.trim(),
      'email': _email.text.trim(),
      'phone': formattedPhone(),
      'company_name': _company.text.trim(),
      'company_registration_number': _companyReg.text.trim(),
      'blockNo': _addressLine.text.trim(),
      'roadNo': '',
      'user_type': widget.userType,
      'nationality_id': _selectedNationality?.id ?? 0,
      'first_name_ar': _firstNameAr.text.trim(),
      'last_name_ar': _lastNameAr.text.trim(),
      'vat_number': _vat.text.trim(),
      'package_description': _packageDescription.text.trim(),
    };
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final profileRepo = ProfileRepositoryImpl();

    Widget field({
      required String label,
      required TextEditingController controller,
      TextInputType inputType = TextInputType.text,
    }) {
      return TextField(
        controller: controller,
        keyboardType: inputType,
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

    Widget phoneRow() {
      const codes = [
        '+973',
        '+91',
        '+966',
        '+971',
        '+965',
        '+974',
        '+968',
        '+1',
      ];
      return Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _countryCode,
                items: codes
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) =>
                    setState(() => _countryCode = v ?? _countryCode),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: field(
              label: 'Mobile Number',
              controller: _phone,
              inputType: TextInputType.phone,
            ),
          ),
        ],
      );
    }

    Widget nationalityPicker() {
      final label =
          _selectedNationality?.name ??
          (widget.initialNationalityName.isNotEmpty
              ? widget.initialNationalityName
              : (widget.initialNationalityId != 0
                    ? 'Saved (#${widget.initialNationalityId})'
                    : 'Select nationality'));
      final hasValue =
          _selectedNationality != null ||
          widget.initialNationalityId != 0 ||
          widget.initialNationalityName.isNotEmpty;

      return Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () async {
            final selected = await Navigator.of(context).push<Nationality>(
              MaterialPageRoute(
                builder: (_) => NationalityPickerPage(
                  token: widget.token,
                  selectedId:
                      _selectedNationality?.id ?? widget.initialNationalityId,
                ),
              ),
            );
            if (selected != null && mounted) {
              setState(() => _selectedNationality = selected);
            }
          },
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: 'Nationality',
              filled: true,
              fillColor: Colors.white,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF66258E),
                  width: 1.5,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: hasValue
                          ? const Color(0xFF111827)
                          : Colors.grey.shade600,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Icon(Icons.expand_more, color: Color(0xFF4B5563)),
              ],
            ),
          ),
        ),
      );
    }

    return BlocProvider(
      create: (_) =>
          ProfileEditBloc(repository: profileRepo, token: widget.token),
      child: BlocListener<ProfileEditBloc, ProfileEditState>(
        listenWhen: (p, c) =>
            p.success != c.success ||
            p.error != c.error ||
            p.submitting != c.submitting,
        listener: (context, state) async {
          setState(() => _submitting = state.submitting);
          if (state.success) {
            if (state.loginResponse != null) {
              await SessionManager().saveLogin(state.loginResponse!);
            }
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Profile updated')),
              );
              Navigator.of(context).pop(state.loginResponse ?? true);
            }
          } else if (state.error != null) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.error!)),
              );
            }
          }
        },
        child: Builder(
          builder: (formCtx) => Scaffold(
            backgroundColor: const Color(0xFFF6F7FB),
            appBar: AppBar(title: const Text('Edit Profile')),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: field(
                          label: 'First Name',
                          controller: _firstName,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: field(label: 'Last Name', controller: _lastName),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  field(
                    label: 'Email',
                    controller: _email,
                    inputType: TextInputType.emailAddress,
                  ),

                  const SizedBox(height: 12),
                  phoneRow(),
                  const SizedBox(height: 12),
                  field(label: 'Company Name', controller: _company),
                  const SizedBox(height: 12),
                  field(
                    label: 'Company Registration Number',
                    controller: _companyReg,
                  ),
                  const SizedBox(height: 12),
                  nationalityPicker(),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: field(
                          label: 'First Name (Arabic)',
                          controller: _firstNameAr,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: field(
                          label: 'Last Name (Arabic)',
                          controller: _lastNameAr,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  field(label: 'VAT Number', controller: _vat),
                  const SizedBox(height: 12),
                  field(label: 'Address', controller: _addressLine),
                  const SizedBox(height: 16),
                  Text(' Preferences', style: TextStyle(fontWeight: FontWeight.bold, color: colors.mutedText)),
                  const SizedBox(height: 12),
                  field(
                    label: 'Package Description',
                    controller: _packageDescription,
                    inputType: TextInputType.text,
                  ),
                  const SizedBox(height: 10),
                  Text('Default package details for order placement, aiding efficient multi-package management.', style: TextStyle(fontWeight: FontWeight.normal, color: colors.mutedText)),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: BlocBuilder<ProfileEditBloc, ProfileEditState>(
                      buildWhen: (p, c) => p.submitting != c.submitting,
                      builder: (context, state) {
                        final isSubmitting = state.submitting || _submitting;
                        return ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: isSubmitting
                              ? null
                              : () {
                                  final payload = _payload();
                                  if ((payload['first_name'] as String)
                                          .isEmpty ||
                                      (payload['last_name'] as String)
                                          .isEmpty ||
                                      (payload['email'] as String).isEmpty ||
                                      (payload['phone'] as String).isEmpty ||
                                      (payload['blockNo'] as String).isEmpty) {
                                    ScaffoldMessenger.of(formCtx).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Please fill all required fields',
                                        ),
                                      ),
                                    );
                                    return;
                                  }
                                  final rawDigits =
                                      _phone.text.replaceAll(RegExp(r'\D'), '');
                                  final codeDigits =
                                      _countryCode.replaceAll(RegExp(r'\D'), '');
                                  final digits = rawDigits.startsWith(codeDigits)
                                      ? rawDigits.substring(codeDigits.length)
                                      : rawDigits;
                                  if (digits.length < 6 ||
                                      digits.length > 15 ||
                                      !RegExp(r'^[0-9]+$').hasMatch(digits)) {
                                    ScaffoldMessenger.of(formCtx).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Enter a valid phone number',
                                        ),
                                      ),
                                    );
                                    return;
                                  }
                                  formCtx.read<ProfileEditBloc>().add(
                                    ProfileEditEvent(payload: payload),
                                  );
                                },
                          child: Text(
                            isSubmitting ? 'Saving...' : 'Save Profile',
                            style: const TextStyle(color: Colors.white),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
