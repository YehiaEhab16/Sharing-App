import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:my_app/extensions/list/filter.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' show join;

import 'crud_exceptions.dart';

class NotesService {
  Database? _db;

  List<DatabaseNotes> _notes = [];

  DatabaseUser? _user;

  static final NotesService _shared = NotesService._sharedInstance();
  NotesService._sharedInstance() {
    _notesStreamController = StreamController<List<DatabaseNotes>>.broadcast(
      onListen: () {
        _notesStreamController.sink.add(_notes);
      },
    );
  }
  factory NotesService() => _shared;

  late final StreamController<List<DatabaseNotes>> _notesStreamController;

  Stream<List<DatabaseNotes>> get allNotes =>
      _notesStreamController.stream.filter((note) {
        final currentUser = _user;
        if (currentUser != null) {
          return note.userId == currentUser.id;
        } else {
          throw UserShouldBeSetBeforeReadingNotes();
        }
      });

  Future<void> _cacheNotes() async {
    final allNotes = await getAllNotes();
    _notes = allNotes.toList();
    _notesStreamController.add(_notes);
  }

  Future<DatabaseUser> getorCreateUser({
    required String email,
    bool setAsCurrentUser = true,
  }) async {
    try {
      final user = await getUser(email: email);
      if (setAsCurrentUser) {
        _user = user;
      }
      return user;
    } on CouldNotFindUser {
      final createdUser = await createUser(email: email);
      if (setAsCurrentUser) {
        _user = createdUser;
      }
      return createdUser;
    } catch (e) {
      rethrow;
    }
  }

  Database _getDatabaseorThrow() {
    final db = _db;
    if (db == null) {
      throw DatabaseIsNotOpen();
    } else {
      return db;
    }
  }

  Future<DatabaseNotes> createNote({required DatabaseUser owner}) async {
    await _ensureDbisOpen();
    final db = _getDatabaseorThrow();
    final dbUser = await getUser(email: owner.email);
    if (dbUser != owner) {
      throw CouldNotFindUser();
    }
    const text = '';

    final noteId = await db.insert(notesTable, {
      userIdColumn: owner.id,
      textColumn: text,
      syncedColumn: 1,
    });

    final note = DatabaseNotes(
      id: noteId,
      userId: owner.id,
      text: text,
      isSyncedWithServer: true,
    );

    _notes.add(note);
    _notesStreamController.add(_notes);

    return note;
  }

  Future<void> deleteNote({required int id}) async {
    await _ensureDbisOpen();
    final db = _getDatabaseorThrow();

    final deletedCount = await db.delete(
      notesTable,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (deletedCount == 0) {
      throw CouldNotDeleteNote();
    } else {
      _notes.removeWhere((note) => note.id == id);
      _notesStreamController.add(_notes);
    }
  }

  Future<int> deleteNotes() async {
    await _ensureDbisOpen();
    final db = _getDatabaseorThrow();
    final numberOfDeletions = await db.delete(notesTable);
    _notes = [];
    _notesStreamController.add(_notes);
    return numberOfDeletions;
  }

  Future<DatabaseNotes> getNote({required int id}) async {
    await _ensureDbisOpen();
    final db = _getDatabaseorThrow();
    final notes = await db.query(
      notesTable,
      limit: 1,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (notes.isEmpty) {
      throw CouldNotFindNote();
    } else {
      final note = DatabaseNotes.fromRow(notes.first);
      _notes.removeWhere((note) => note.id == id);
      _notes.add(note);
      _notesStreamController.add(_notes);
      return note;
    }
  }

  Future<Iterable<DatabaseNotes>> getAllNotes() async {
    await _ensureDbisOpen();
    final db = _getDatabaseorThrow();
    final notes = await db.query(notesTable);

    return notes.map((notesRow) => DatabaseNotes.fromRow(notesRow));
  }

  Future<DatabaseNotes> updateNote({
    required DatabaseNotes note,
    required String text,
  }) async {
    await _ensureDbisOpen();
    final db = _getDatabaseorThrow();

    await getNote(id: note.id);

    final updatesCount = await db.update(
      notesTable,
      {
        textColumn: text,
        syncedColumn: 0,
      },
      where: 'id = ?',
      whereArgs: [note.id],
    );

    if (updatesCount == 0) {
      throw CouldNotUpdateNote();
    } else {
      final updatedNote = await getNote(id: note.id);
      _notes.removeWhere((note) => note.id == updatedNote.id);
      _notes.add(updatedNote);
      _notesStreamController.add(_notes);
      return updatedNote;
    }
  }

  Future<void> deleteUser({required String email}) async {
    await _ensureDbisOpen();
    final db = _getDatabaseorThrow();
    final deletedCounted = await db.delete(
      userTable,
      where: 'email = ?',
      whereArgs: [email.toLowerCase()],
    );
    if (deletedCounted != 1) {
      throw CouldNotDeleteUser();
    }
  }

  Future<DatabaseUser> createUser({required String email}) async {
    await _ensureDbisOpen();
    final db = _getDatabaseorThrow();
    final results = await db.query(
      userTable,
      limit: 1,
      where: 'email = ?',
      whereArgs: [email.toLowerCase()],
    );
    if (results.isNotEmpty) {
      throw UserAlreadyExists();
    }

    final userId = await db.insert(userTable, {
      emailColumn: email.toLowerCase(),
    });

    return DatabaseUser(
      id: userId,
      email: email,
    );
  }

  Future<DatabaseUser> getUser({required String email}) async {
    await _ensureDbisOpen();
    final db = _getDatabaseorThrow();
    final results = await db.query(
      userTable,
      limit: 1,
      where: 'email = ?',
      whereArgs: [email.toLowerCase()],
    );
    if (results.isEmpty) {
      throw CouldNotFindUser();
    } else {
      return DatabaseUser.fromRow(results.first);
    }
  }

  Future<void> open() async {
    if (_db != null) throw DatabaseAlreadyOpenError();
    try {
      final docsPath = await getApplicationDocumentsDirectory();
      final dbPath = join(docsPath.path, dbName);
      final db = await openDatabase(dbPath);
      _db = db;

      await db.execute(createUserTable);

      await db.execute(createNotesTable);
      await _cacheNotes();
    } on MissingPlatformDirectoryException {
      throw UnableToGetDocumentDirectory();
    }
  }

  Future<void> _ensureDbisOpen() async {
    try {
      await open();
    } on DatabaseAlreadyOpenError {
      //Empty
    }
  }

  Future<void> close() async {
    final db = _db;
    if (db == null) {
      throw DatabaseIsNotOpen();
    } else {
      await db.close();
      _db = null;
    }
  }
}

@immutable
class DatabaseUser {
  final int id;
  final String email;

  const DatabaseUser({
    required this.id,
    required this.email,
  });

  DatabaseUser.fromRow(Map<String, Object?> map)
      : id = map[idColumn] as int,
        email = map[emailColumn] as String;

  @override
  String toString() => 'Person, ID = $id, email = $email';

  @override
  bool operator ==(covariant DatabaseUser other) => id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class DatabaseNotes {
  final int id;
  final int userId;
  final String text;
  final bool isSyncedWithServer;

  DatabaseNotes({
    required this.id,
    required this.userId,
    required this.text,
    required this.isSyncedWithServer,
  });

  DatabaseNotes.fromRow(Map<String, Object?> map)
      : id = map[idColumn] as int,
        userId = map[userIdColumn] as int,
        text = map[textColumn] as String,
        isSyncedWithServer = (map[syncedColumn] as int) == 1 ? true : false;

  @override
  String toString() =>
      'Note, ID = $id, userId = $userId, isSynced = $isSyncedWithServer';

  @override
  bool operator ==(covariant DatabaseNotes other) => id == other.id;

  @override
  int get hashCode => id.hashCode;
}

const dbName = 'testing.db';
const userTable = 'user';
const notesTable = 'notes';
const idColumn = 'id';
const emailColumn = 'email';
const userIdColumn = 'user_id';
const textColumn = 'text';
const syncedColumn = 'isSynced';
const createUserTable = ''' CREATE TABLE IF NOT EXISTS "user" (
        "id"	INTEGER NOT NULL,
        "email"	TEXT NOT NULL UNIQUE,
        PRIMARY KEY("id" AUTOINCREMENT)
        );''';
const createNotesTable = ''' CREATE TABLE IF NOT EXISTS "notes" (
        "id"	INTEGER NOT NULL,
        "user_id"	INTEGER NOT NULL,
        "text"	TEXT,
        "isSynced"	INTEGER DEFAULT 0,
        FOREIGN KEY("user_id") REFERENCES "user"("id"),
        PRIMARY KEY("id" AUTOINCREMENT)
        );''';
