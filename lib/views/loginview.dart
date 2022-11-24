import 'package:flutter/material.dart';
import 'package:my_app/constants/routes.dart';
import 'package:my_app/services/auth/auth_exceptions.dart';
import 'package:my_app/utils/errordialog.dart';
import 'package:my_app/services/auth/auth_service.dart';

class LoginView extends StatefulWidget {
  const LoginView({Key? key}) : super(key: key);

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  late final TextEditingController _email;
  late final TextEditingController _pass;

  @override
  void initState() {
    _email = TextEditingController();
    _pass = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('The Chairman - SMU'),
        ),
        body: Column(
          children: [
            TextField(
              controller: _email,
              autocorrect: false,
              keyboardType: TextInputType.emailAddress,
              enableSuggestions: false,
              decoration:
                  const InputDecoration(hintText: 'Enter your email here'),
            ),
            TextField(
              controller: _pass,
              obscureText: true,
              autocorrect: false,
              enableSuggestions: false,
              decoration:
                  const InputDecoration(hintText: 'Enter your password here'),
            ),
            TextButton(
              onPressed: () async {
                final email = _email.text;
                final pass = _pass.text;
                try {
                  await AuthService.firebase().logIn(
                    email: email,
                    password: pass,
                  );
                  final user = AuthService.firebase().currentUser;
                  if (user?.isEmailVerified ?? false) {
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      mainRoute,
                      (route) => false,
                    );
                  } else {
                    await showialogError(context, "Please Verify Email First");
                  }
                } on WrongPasswordAuthException {
                  await showialogError(context, 'Invalid Password. Try Again');
                } on UserNotFoundAuthException {
                  await showialogError(
                      context, 'User Not Found. Register First');
                } on GenericAuthException {
                  await showialogError(context, 'Authentication Error');
                }
              },
              child: const Text('Login'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pushNamedAndRemoveUntil(
                  registerRoute,
                  (route) => false,
                );
              },
              child: const Text('Not Registered Yet? Register Here'),
            )
          ],
        ));
  }
}
