import 'package:flutter/material.dart';

import '../../../../core/app_colors.dart';
import '../../../../login/models/login_response.dart';
import 'address_list_page.dart';
import 'profile_edit_page.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({
    super.key,
    this.name = '',
    this.email = '',
    this.phone = '',
    this.customerId = '',
    this.avatarUrl,
    this.onLogout,
    required this.token,
    required this.userType,
    this.initialFirstName = '',
    this.initialLastName = '',
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

  final String name;
  final String email;
  final String phone;
  final String customerId;
  final String? avatarUrl;
  final String token;
  final int userType;
  final Future<void> Function(BuildContext context)? onLogout;
  final String initialFirstName;
  final String initialLastName;
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
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late String _name;
  late String _email;
  late String _phone;
  late String _firstName;
  late String _lastName;
  late String _companyName;
  late String _companyReg;
  late String _vatNumber;
  late String _addressLine;
  late String _firstNameAr;
  late String _lastNameAr;
  late int _nationalityId;
  late String _nationalityName;
  late String _packageDescription;

  @override
  void initState() {
    super.initState();
    _name = widget.name;
    _email = widget.email;
    _phone = widget.phone;
    _firstName = widget.initialFirstName;
    _lastName = widget.initialLastName;
    _companyName = widget.initialCompanyName;
    _companyReg = widget.initialCompanyReg;
    _vatNumber = widget.initialVatNumber;
    _addressLine = widget.initialAddressLine;
    _firstNameAr = widget.initialFirstNameAr;
    _lastNameAr = widget.initialLastNameAr;
    _nationalityId = widget.initialNationalityId;
    _nationalityName = widget.initialNationalityName;
    _packageDescription = widget.initialPackageDescription;
  }

  void _applyLoginResponse(LoginResponse response) {
    final user = response.user;
    setState(() {
      _firstName = user.firstName;
      _lastName = user.lastName;
      _name = user.fullName.isEmpty ? 'Delybell user' : user.fullName;
      _email = user.email;
      _phone = user.phone;
      _companyName = user.companyName;
      _companyReg = user.companyRegistrationNumber;
      _vatNumber = user.vatNumber;
      _addressLine = user.addressLineOne;
      _firstNameAr = user.firstNameAr;
      _lastNameAr = user.lastNameAr;
      _nationalityId = user.nationalityId;
      _nationalityName = user.nationalityName;
      _packageDescription =
          (response.user as dynamic).packageDescription ?? _packageDescription;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final scheme = Theme.of(context).colorScheme;

    Widget menuTile({
      required IconData icon,
      required String title,
      String? subtitle,
      VoidCallback? onTap,
      Color? tint,
    }) {
      return Card(
        elevation: 0,
        margin: const EdgeInsets.symmetric(vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: colors.border),
        ),
        color: Colors.white,
        child: ListTile(
          leading: CircleAvatar(
            radius: 20,
            backgroundColor: (tint ?? colors.primary).withValues(alpha: 0.12),
            child: Icon(icon, color: tint ?? colors.primary),
          ),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          subtitle: subtitle != null
              ? Text(subtitle, style: TextStyle(color: colors.mutedText))
              : null,
          trailing: const Icon(Icons.chevron_right),
          onTap: onTap,
        ),
      );
    }

    void handleTap(String label) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$label coming soon')));
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SafeArea(child: Text('Profile',style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),)),
            SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colors.primary.withValues(alpha: 0.9),
                    colors.primary.withValues(alpha: 0.7),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: colors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 12,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back,',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _name,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Icon(Icons.mail_outline, color: Colors.white),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _email,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(Icons.phone_outlined, color: Colors.white),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _phone,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Quick Actions',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: scheme.onSurface,
                ),
              ),
            ),
            const SizedBox(height: 10),
            menuTile(
              icon: Icons.home_work_outlined,
              title: 'Pickup Address',
              subtitle: 'Manage saved pickup points',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => AddressListPage(token: widget.token),
                  ),
                );
              },
            ),
            // menuTile(
            //   icon: Icons.inventory_2_outlined,
            //   title: 'Package Description',
            //   subtitle: 'Default package notes & values',
            //   onTap: () => handleTap('Package Description'),
            // ),
            menuTile(
              icon: Icons.edit_outlined,
              title: 'Edit Details',
              subtitle: 'Profile, contacts, preferences',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ProfileEditPage(
                      token: widget.token,
                      initialFirstName: _firstName,
                      initialLastName: _lastName,
                      userType: widget.userType,
                      initialEmail: _email,
                      initialPhone: _phone,
                      initialCompanyName: _companyName,
                      initialCompanyReg: _companyReg,
                      initialVatNumber: _vatNumber,
                      initialAddressLine: _addressLine,
                      initialFirstNameAr: _firstNameAr,
                      initialLastNameAr: _lastNameAr,
                      initialNationalityId: _nationalityId,
                      initialNationalityName: _nationalityName,
                      initialPackageDescription: _packageDescription,
                    ),
                  ),
                ).then((result) {
                  if (result != null) {
                    _applyLoginResponse(result);
                  }
                });
              },
            ),
            menuTile(
              icon: Icons.privacy_tip_outlined,
              title: 'Privacy Policy',
              subtitle: 'Understand how we keep data safe',
              onTap: () => handleTap('Privacy Policy'),
            ),
            menuTile(
              icon: Icons.rule_folder_outlined,
              title: 'Terms & Conditions',
              subtitle: 'Service terms and obligations',
              onTap: () {
                launchUrl(Uri.parse(
                    'https://www.delybell.com/home/pagesView/terms-and-conditions'));
              },
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.logout),
                label: const Text('Sign out'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: BorderSide(color: colors.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: widget.onLogout == null
                    ? null
                    : () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Sign out?'),
                            content: const Text(
                              'You will be logged out of this device. Continue?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(ctx).pop(false),
                                child: const Text('Cancel'),
                              ),
                              FilledButton(
                                onPressed: () => Navigator.of(ctx).pop(true),
                                child: const Text('Sign out'),
                              ),
                            ],
                          ),
                        );
                        if (confirmed == true) {
                          await widget.onLogout!(context);
                        }
                      },
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: Icon(Icons.delete_outline, color: colors.danger),
                label: Text('Delete Account', style: TextStyle(color: colors.danger),),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: BorderSide(color: colors.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: widget.onLogout == null
                    ? null
                    : () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Delete Account?'),
                            content: const Text(
                              'You will be logged out of this device. and your delete request will process soon. Continue?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(ctx).pop(false),
                                child: const Text('Cancel'),
                              ),
                              FilledButton(
                                onPressed: () => Navigator.of(ctx).pop(true),
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        );
                        if (confirmed == true) {
                          await widget.onLogout!(context);
                        }
                      },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
