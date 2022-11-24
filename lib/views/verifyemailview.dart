import 'package:flutter/material.dart';
import 'package:my_app/constants/routes.dart';
import 'package:my_app/services/auth/auth_service.dart';

class VerifyEmailView extends StatefulWidget {
  const VerifyEmailView({Key? key}) : super(key: key);

  @override
  State<VerifyEmailView> createState() => _VerifyEmailViewState();
}

class _VerifyEmailViewState extends State<VerifyEmailView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('The Chairman - SMU'),
      ),
      body: Column(
        children: [
          const Text("Please Verify Your Email Address"),
          const Text("Check your email for verification"),
          TextButton(
              onPressed: () async {
                await AuthService.firebase().sendEmailVerification();
              },
              child: const Text(
                  "Haven't revieved verification mail? Resend E-mail")),
          TextButton(
              onPressed: () async {
                await AuthService.firebase().logOut();
                Navigator.of(context)
                    .pushNamedAndRemoveUntil(registerRoute, (route) => false);
              },
              child: const Text("Reset")),
        ],
      ),
    );
  }
}
