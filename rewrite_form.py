import re

with open('lib/signup/view/sign_up_page.dart', 'r') as f:
    content = f.read()

# Replace listener success message
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

# Find the start of password fields:
password_start = content.find("BlocBuilder<SignUpBloc, SignUpState>(")
password_start = content.find("BlocBuilder<SignUpBloc, SignUpState>(", password_start + 1)
password_start = content.find("BlocBuilder<SignUpBloc, SignUpState>(", password_start + 1)
# 3rd BlocBuilder is password visibility

# Instead of regex, let's just generate the whole file since we know it.
