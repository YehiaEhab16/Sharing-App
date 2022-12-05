import 'package:my_app/services/auth/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:my_app/constants/routes.dart';
import 'package:my_app/views/mainview.dart';
import 'package:my_app/views/newview.dart';
import 'package:my_app/views/verifyemailview.dart';
import 'package:my_app/views/loginview.dart';
import 'package:my_app/views/registerview.dart';

void main() {
  runApp(
    MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HomePage(),
      routes: {
        loginRoute: (context) => const LoginView(),
        registerRoute: (context) => const RegisterView(),
        mainRoute: (context) => const MainView(),
        verifyRoute: (context) => const VerifyEmailView(),
        newRoute: (context) => const NewView(),
      },
    ),
  );
}

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: AuthService.firebase().init(),
        builder: (context, snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.done:
              final user = AuthService.firebase().currentUser;
              if (user != null) {
                if (!user.isEmailVerified) {
                  return const VerifyEmailView();
                } else {
                  return const MainView();
                }
              } else {
                return const LoginView();
              }
            default:
              return const CircularProgressIndicator();
          }
        });
  }
}
