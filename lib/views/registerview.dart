import 'package:flutter/material.dart';
import 'package:my_app/constants/routes.dart';
import 'package:my_app/services/auth/auth_exceptions.dart';
import 'package:my_app/utils/errordialog.dart';
import 'package:my_app/services/auth/auth_service.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({Key? key}) : super(key: key);

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
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
                  await AuthService.firebase().createUser(
                    email: email,
                    password: pass,
                  );
                  AuthService.firebase().sendEmailVerification();
                  Navigator.of(context).pushNamed(verifyRoute);
                } on WeakPasswordAuthException {
                  await showialogError(
                      context, "Weak Password. Try a stronger password");
                } on EmailAlreadyInUseAuthException {
                  await showialogError(
                      context, "Email Already In use.Please sign in");
                } on InvaidEmailAuthException {
                  await showialogError(context, "Invalid Email. Try again");
                } on GenericAuthException {
                  await showialogError(context, "Authentication Error");
                }
              },
              child: const Text('Register'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pushNamedAndRemoveUntil(
                  loginRoute,
                  (route) => false,
                );
              },
              child: const Text('Already a user? Login Here'),
            )
          ],
        ));
  }
}
