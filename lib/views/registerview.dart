import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:my_app/constants/routes.dart';
import 'package:my_app/utils/errordialog.dart';
import '../firebase_options.dart';

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
      body: FutureBuilder(
          future: Firebase.initializeApp(
            options: DefaultFirebaseOptions.currentPlatform,
          ),
          builder: (context, snapshot) {
            switch (snapshot.connectionState) {
              case ConnectionState.done:
                return Column(
                  children: [
                    TextField(
                      controller: _email,
                      autocorrect: false,
                      keyboardType: TextInputType.emailAddress,
                      enableSuggestions: false,
                      decoration: const InputDecoration(
                          hintText: 'Enter your email here'),
                    ),
                    TextField(
                      controller: _pass,
                      obscureText: true,
                      autocorrect: false,
                      enableSuggestions: false,
                      decoration: const InputDecoration(
                          hintText: 'Enter your password here'),
                    ),
                    TextButton(
                      onPressed: () async {
                        final email = _email.text;
                        final pass = _pass.text;
                        try {
                          await FirebaseAuth.instance
                              .createUserWithEmailAndPassword(
                                  email: email, password: pass);
                          final user = FirebaseAuth.instance.currentUser;
                          user?.sendEmailVerification();
                          Navigator.of(context).pushNamed(verifyRoute);
                        } on FirebaseAuthException catch (e) {
                          await showialogError(context, e.code);
                        } catch (e) {
                          await showialogError(context, e.toString());
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
                );
              default:
                return const Text('Loading ...');
            }
          }),
    );
  }
}
