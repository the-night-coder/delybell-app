import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/sign_up_bloc.dart';
import '../data/sign_up_repository.dart';
import '../models/sign_up_type.dart';

class SignUpPage extends StatelessWidget {
  const SignUpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SignUpBloc(context.read<SignUpRepository>()),
      child: const _SignUpView(),
    );
  }
}

class _SignUpView extends StatelessWidget {
  const _SignUpView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SignUpSegmentedControl(),
                  SizedBox(height: 32),
                  Text(
                    "Let's start",
                    style: TextStyle(
                      color: Color(0xFF5B21B6),
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Sign Up',
                    style: TextStyle(fontSize: 36, fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Enter your details below to create a new account.',
                    style: TextStyle(color: Color(0xFF4B5563), fontSize: 15),
                  ),
                  SizedBox(height: 32),
                  _SignUpForm(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SignUpSegmentedControl extends StatelessWidget {
  const _SignUpSegmentedControl();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SignUpBloc, SignUpState>(
      buildWhen: (previous, current) =>
          previous.signUpType != current.signUpType,
      builder: (context, state) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFDDDEEA)),
          ),
          child: Row(
            children: SignUpType.values.map((type) {
              final isActive = type == state.signUpType;
              return Expanded(
                child: GestureDetector(
                  onTap: () =>
                      context.read<SignUpBloc>().add(SignUpTypeChanged(type)),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: isActive ? const Color(0xFF5B21B6) : Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: type == SignUpType.user
                            ? const Radius.circular(16)
                            : Radius.zero,
                        bottomLeft: type == SignUpType.user
                            ? const Radius.circular(16)
                            : Radius.zero,
                        topRight: type == SignUpType.corporate
                            ? const Radius.circular(16)
                            : Radius.zero,
                        bottomRight: type == SignUpType.corporate
                            ? const Radius.circular(16)
                            : Radius.zero,
                      ),
                    ),
                    child: Text(
                      type.title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isActive
                            ? Colors.white
                            : const Color(0xFF374151),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}

class _SignUpForm extends StatefulWidget {
  const _SignUpForm();

  @override
  State<_SignUpForm> createState() => _SignUpFormState();
}

class _SignUpFormState extends State<_SignUpForm> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return BlocListener<SignUpBloc, SignUpState>(
      listener: (context, state) {
        if (state.status == SignUpStatus.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                state.signUpType == SignUpType.corporate
                    ? 'Corporate Enquiry request sent successfully!\\nOur representative will contact you soon.'
                    : 'Account created successfully.',
              ),
            ),
          );
          Future.delayed(const Duration(milliseconds: 800), () {
            if (context.mounted) Navigator.of(context).pop();
          });
        } else if (state.status == SignUpStatus.failure &&
            state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: Colors.red.shade600,
            ),
          );
        }
      },
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'First Name',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    onChanged: (value) => context.read<SignUpBloc>().add(
                      SignUpFirstNameChanged(value),
                    ),
                    validator: (value) =>
                        (value == null || value.isEmpty) ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Last Name',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    onChanged: (value) => context.read<SignUpBloc>().add(
                      SignUpLastNameChanged(value),
                    ),
                    validator: (value) =>
                        (value == null || value.isEmpty) ? 'Required' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.mail_outline),
              ),
              keyboardType: TextInputType.emailAddress,
              onChanged: (value) =>
                  context.read<SignUpBloc>().add(SignUpEmailChanged(value)),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Required';
                if (!value.contains('@')) return 'Enter a valid email';
                return null;
              },
            ),
            const SizedBox(height: 20),
            BlocBuilder<SignUpBloc, SignUpState>(
              buildWhen: (previous, current) =>
                  previous.countryCode != current.countryCode,
              builder: (context, state) {
                return Row(
                  children: [
                    SizedBox(
                      width: 110,
                      child: DropdownButtonFormField<String>(
                        value: state.countryCode,
                        decoration: const InputDecoration(labelText: 'Code'),
                        items: const [
                          DropdownMenuItem(
                            value: '+973',
                            child: Text('BH +973'),
                          ),
                          DropdownMenuItem(
                            value: '+971',
                            child: Text('AE +971'),
                          ),
                          DropdownMenuItem(
                            value: '+966',
                            child: Text('SA +966'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          context.read<SignUpBloc>().add(
                            SignUpCountryCodeChanged(value),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Phone Number',
                          prefixIcon: Icon(Icons.phone_outlined),
                        ),
                        keyboardType: TextInputType.phone,
                        onChanged: (value) => context.read<SignUpBloc>().add(
                          SignUpPhoneChanged(value),
                        ),
                        validator: (value) => (value == null || value.isEmpty)
                            ? 'Required'
                            : null,
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),
            BlocBuilder<SignUpBloc, SignUpState>(
              buildWhen: (previous, current) =>
                  previous.signUpType != current.signUpType,
              builder: (context, state) {
                if (state.signUpType == SignUpType.user) {
                  return const SizedBox.shrink();
                }
                return Column(
                  children: [
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Organization Name',
                        prefixIcon: Icon(Icons.business_outlined),
                      ),
                      onChanged: (value) => context.read<SignUpBloc>().add(
                        SignUpOrganizationNameChanged(value),
                      ),
                      validator: (value) =>
                          (value == null || value.isEmpty) ? 'Required' : null,
                    ),

                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Description (Optional)',
                      ),
                      maxLines: 3,
                      onChanged: (value) => context.read<SignUpBloc>().add(
                        SignUpDescriptionChanged(value),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 28),
            BlocBuilder<SignUpBloc, SignUpState>(
              buildWhen: (previous, current) =>
                  previous.signUpType != current.signUpType ||
                  previous.status != current.status,
              builder: (context, state) {
                final isLoading = state.status == SignUpStatus.loading;
                return SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: isLoading
                        ? null
                        : () {
                            if (_formKey.currentState?.validate() ?? false) {
                              context.read<SignUpBloc>().add(
                                const SignUpSubmitted(),
                              );
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0A26D8),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : Text(state.signUpType.ctaLabel),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                TextButton(
                  onPressed: () {},
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF0F52BA),
                  ),
                  child: const Text('Forgot Password?'),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF0F52BA),
                  ),
                  child: const Text('Sign In here'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
