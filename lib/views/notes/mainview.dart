import 'package:flutter/material.dart';
import 'package:my_app/constants/routes.dart';
import 'package:my_app/enums/menu_action.dart';
import 'package:my_app/services/auth/auth_service.dart';
import 'package:my_app/services/crud/notes_service.dart';
import 'package:my_app/utils/dialogs/logoutdialog.dart';

import '../../utils/dialogs/genericdialog.dart';
import 'listview.dart';

class MainView extends StatefulWidget {
  const MainView({Key? key}) : super(key: key);

  @override
  State<MainView> createState() => _MainViewState();
}

class _MainViewState extends State<MainView> {
  late final NotesService _notesService;
  String get userEmail => AuthService.firebase().currentUser!.email!;

  @override
  void initState() {
    _notesService = NotesService();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('The Chairman - SMU'),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).pushNamed(newRoute);
            },
            icon: const Icon(Icons.add),
          ),
          PopupMenuButton<MenuAction>(onSelected: (value) async {
            if (value == MenuAction.logout) {
              final shouldLogout = await showLogOutDialog(context);
              if (shouldLogout) {
                await AuthService.firebase().logOut();
                Navigator.of(context).pushNamedAndRemoveUntil(
                  loginRoute,
                  (_) => false,
                );
              }
            }
          }, itemBuilder: (context) {
            return const [
              PopupMenuItem<MenuAction>(
                value: MenuAction.logout,
                child: Text('Log Out'),
              )
            ];
          })
        ],
      ),
      body: FutureBuilder(
        future: _notesService.getorCreateUser(email: userEmail),
        builder: (context, snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.done:
              return StreamBuilder(
                  stream: _notesService.allNotes,
                  builder: (context, snapshot) {
                    switch (snapshot.connectionState) {
                      case ConnectionState.waiting:
                      case ConnectionState.active:
                        if (snapshot.hasData) {
                          final allNotes = snapshot.data as List<DatabaseNotes>;
                          return NotesListView(
                            notes: allNotes,
                            onDeleteNote: (DatabaseNotes note) async {
                              await _notesService.deleteNote(id: note.id);
                            },
                            onTap: (note) {
                              Navigator.of(context).pushNamed(
                                newRoute,
                                arguments: note,
                              );
                            },
                          );
                        } else {
                          return const CircularProgressIndicator();
                        }
                      default:
                        return const CircularProgressIndicator();
                    }
                  });
            default:
              return const CircularProgressIndicator();
          }
        },
      ),
    );
  }
}
