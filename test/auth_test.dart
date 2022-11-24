import 'package:my_app/services/auth/auth_exceptions.dart';
import 'package:my_app/services/auth/auth_provider.dart';
import 'package:my_app/services/auth/auth_user.dart';
import 'package:test/test.dart';

void main() {
  group("Mock Authentication", () {
    final mockProvider = MockAuthProvider();
    test('Should not be initialized to begin with', () {
      expect(mockProvider.isInitialized, false);
    });

    test('Can not logout if not initialized', () {
      expect(
        mockProvider.logOut(),
        throwsA(const TypeMatcher<NotInitializedException>()),
      );
    });

    test('Should be initialized', () async {
      await mockProvider.init();
      expect(mockProvider.isInitialized, true);
    });

    test('User should not be null after init', () {
      expect(mockProvider.currentUser, null);
    });

    test(
      'Should be initialized',
      () async {
        await mockProvider.init();
        expect(mockProvider.isInitialized, true);
      },
      timeout: const Timeout(Duration(seconds: 2)),
    );

    test('Should user delegate to login', () async {
      final badEmailUser = mockProvider.createUser(
        email: 'yehia',
        password: 'password',
      );
      expect(badEmailUser,
          throwsA(const TypeMatcher<UserNotFoundAuthException>()));

      final badPassUser = mockProvider.createUser(
        email: 'email',
        password: 'ehab',
      );
      expect(badPassUser,
          throwsA(const TypeMatcher<WrongPasswordAuthException>()));

      final normalUser = await mockProvider.createUser(
        email: 'email',
        password: 'password',
      );
      expect(mockProvider.currentUser, normalUser);
      expect(normalUser.isEmailVerified, false);
    });

    test('Logged in user should be able to get verified', () {
      mockProvider.sendEmailVerification();
      final user = mockProvider.currentUser;
      expect(user, isNotNull);
      expect(user!.isEmailVerified, true);
    });

    test('Should be able to logout and log in again', () async {
      await mockProvider.logOut();
      await mockProvider.logIn(
        email: 'email',
        password: 'password',
      );
      final user = mockProvider.currentUser;
      expect(user, isNotNull);
    });
  });
}

class NotInitializedException implements Exception {}

class MockAuthProvider implements AuthProvider {
  AuthUser? _user;
  var _isInitialized = false;
  bool get isInitialized => _isInitialized;

  @override
  Future<AuthUser> createUser({
    required String email,
    required String password,
  }) async {
    if (!isInitialized) throw NotInitializedException();
    await Future.delayed(const Duration(seconds: 1));
    return logIn(
      email: email,
      password: password,
    );
  }

  @override
  AuthUser? get currentUser => _user;

  @override
  Future<void> init() async {
    await Future.delayed(const Duration(seconds: 1));
    _isInitialized = true;
  }

  @override
  Future<AuthUser> logIn({
    required String email,
    required String password,
  }) {
    if (!isInitialized) throw NotInitializedException();
    if (email == 'yehia') throw UserNotFoundAuthException();
    if (password == 'ehab') throw WrongPasswordAuthException();
    const user = AuthUser(isEmailVerified: false);
    _user = user;
    return Future.value(user);
  }

  @override
  Future<void> logOut() async {
    if (!isInitialized) throw NotInitializedException();
    if (_user == null) throw UserNotFoundAuthException();
    await Future.delayed(const Duration(seconds: 1));
    _user = null;
  }

  @override
  Future<void> sendEmailVerification() async {
    if (!isInitialized) throw NotInitializedException();
    if (_user == null) throw UserNotFoundAuthException();
    const user = AuthUser(isEmailVerified: true);
    _user = user;
  }
}
