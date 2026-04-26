import re

with open('lib/signup/view/sign_up_page.dart', 'r') as f:
    content = f.read()

# Fix listener
new_listener = """if (state.status == SignUpStatus.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                state.signUpType == SignUpType.corporate 
                ? 'Corporate Enquiry request sent successfully!\\nOur representative will contact you soon.'
                : 'Account created successfully.'
              ),
            ),
          );
          Future.delayed(const Duration(milliseconds: 800), () {
            if (context.mounted) Navigator.of(context).pop();
          });
        }"""

content = re.sub(r"if \(state.status == SignUpStatus.success\) \{.*?\}\);[\s\n]*\}", new_listener, content, flags=re.DOTALL)

# Add conditional builder for the type specific fields
# The original has:
# 261:             const SizedBox(height: 20),
# 262:             BlocBuilder<SignUpBloc, SignUpState>(
# ... down to 326
# 327:             const SizedBox(height: 28),
# 328:             BlocBuilder<SignUpBloc, SignUpState>(

# We'll replace the block from "const SizedBox(height: 20)," after Phone Number, up to the submit button
password_section_regex = r"const SizedBox\(height: 20\);\s*BlocBuilder<SignUpBloc, SignUpState>\(\s*buildWhen: \(previous, current\) =>\s*previous\.isPasswordVisible != current\.isPasswordVisible,.*?const SizedBox\(height: 28\);"

new_fields = """const SizedBox(height: 20),
            BlocBuilder<SignUpBloc, SignUpState>(
              buildWhen: (previous, current) =>
                  previous.signUpType != current.signUpType ||
                  previous.isPasswordVisible != current.isPasswordVisible ||
                  previous.isConfirmPasswordVisible != current.isConfirmPasswordVisible,
              builder: (context, state) {
                if (state.signUpType == SignUpType.corporate) {
                  return Column(
                    children: [
                      TextFormField(
                        decoration: const InputDecoration(labelText: 'Organization Name', prefixIcon: Icon(Icons.business_outlined)),
                        onChanged: (value) => context.read<SignUpBloc>().add(SignUpOrganizationNameChanged(value)),
                        validator: (value) => (value == null || value.isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              decoration: const InputDecoration(labelText: 'Organization Reg No (Optional)'),
                              onChanged: (value) => context.read<SignUpBloc>().add(SignUpOrganizationRegNoChanged(value)),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              decoration: const InputDecoration(labelText: 'VAT Number (Optional)'),
                              onChanged: (value) => context.read<SignUpBloc>().add(SignUpVatNumberChanged(value)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              decoration: const InputDecoration(labelText: 'First Name (Arabic) (Optional)'),
                              onChanged: (value) => context.read<SignUpBloc>().add(SignUpFirstNameArChanged(value)),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              decoration: const InputDecoration(labelText: 'Last Name (Arabic) (Optional)'),
                              onChanged: (value) => context.read<SignUpBloc>().add(SignUpLastNameArChanged(value)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              decoration: const InputDecoration(labelText: 'Nationality (Optional)'),
                              onChanged: (value) => context.read<SignUpBloc>().add(SignUpNationalityChanged(value)),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              decoration: const InputDecoration(labelText: 'City (Optional)'),
                              onChanged: (value) => context.read<SignUpBloc>().add(SignUpCityChanged(value)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              decoration: const InputDecoration(labelText: 'Road (Optional)'),
                              onChanged: (value) => context.read<SignUpBloc>().add(SignUpRoadChanged(value)),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              decoration: const InputDecoration(labelText: 'Block (Optional)'),
                              onChanged: (value) => context.read<SignUpBloc>().add(SignUpBlockChanged(value)),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              decoration: const InputDecoration(labelText: 'Building (Optional)'),
                              onChanged: (value) => context.read<SignUpBloc>().add(SignUpBuildingChanged(value)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        decoration: const InputDecoration(labelText: 'Address Line 1 (Optional)'),
                        onChanged: (value) => context.read<SignUpBloc>().add(SignUpAddressLine1Changed(value)),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        decoration: const InputDecoration(labelText: 'Address Line 2 (Optional)'),
                        onChanged: (value) => context.read<SignUpBloc>().add(SignUpAddressLine2Changed(value)),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        decoration: const InputDecoration(labelText: 'Description (Optional)'),
                        maxLines: 3,
                        onChanged: (value) => context.read<SignUpBloc>().add(SignUpDescriptionChanged(value)),
                      ),
                    ],
                  );
                }

                return Column(
                  children: [
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          onPressed: () => context
                              .read<SignUpBloc>()
                              .add(const SignUpPasswordVisibilityToggled()),
                          icon: Icon(
                            state.isPasswordVisible
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                        ),
                      ),
                      obscureText: !state.isPasswordVisible,
                      onChanged: (value) => context
                          .read<SignUpBloc>()
                          .add(SignUpPasswordChanged(value)),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Required';
                        if (value.length < 6) {
                          return 'Use at least 6 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Confirm Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          onPressed: () => context.read<SignUpBloc>().add(
                                const SignUpConfirmPasswordVisibilityToggled(),
                              ),
                          icon: Icon(
                            state.isConfirmPasswordVisible
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                        ),
                      ),
                      obscureText: !state.isConfirmPasswordVisible,
                      onChanged: (value) => context
                          .read<SignUpBloc>()
                          .add(SignUpConfirmPasswordChanged(value)),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Required';
                        return null;
                      },
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 28);"""

content = re.sub(password_section_regex, new_fields, content, flags=re.DOTALL)

with open('lib/signup/view/sign_up_page.dart', 'w') as f:
    f.write(content)

