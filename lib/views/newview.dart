import 'package:flutter/material.dart';

class NewView extends StatefulWidget {
  const NewView({Key? key}) : super(key: key);

  @override
  State<NewView> createState() => _NewViewState();
}

class _NewViewState extends State<NewView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Note'),
      ),
      body: const Text('Write your note'),
    );
  }
}
