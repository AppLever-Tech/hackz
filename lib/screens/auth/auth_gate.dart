import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/enums/user_status.dart';
import '../../models/user_model.dart';
import '../../utils/common_helpers.dart';
import '../../utils/firestore_utils.dart';
import '../../utils/role_utils.dart';
import 'landing_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  Future<UserModel?> _resolveSignedInUser(User firebaseUser) async {
    final byUid = await FirestoreUtils.fetchUser(firebaseUser.uid);
    if (byUid != null) return byUid;

    final phone = firebaseUser.phoneNumber;
    if (phone == null || phone.trim().isEmpty) return null;
    return FirestoreUtils.fetchUserByPhone(normalizePhoneE164(phone));
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (BuildContext context, AsyncSnapshot<User?> authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final firebaseUser = authSnapshot.data;
        if (firebaseUser == null) {
          return const LandingScreen();
        }

        return FutureBuilder<UserModel?>(
          future: _resolveSignedInUser(firebaseUser),
          builder: (BuildContext context, AsyncSnapshot<UserModel?> userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (userSnapshot.hasError) {
              return Scaffold(
                body: Center(
                  child: Text('Failed to restore session: ${userSnapshot.error}'),
                ),
              );
            }

            final appUser = userSnapshot.data;
            if (appUser == null) {
              return Scaffold(
                body: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      const Text('No profile found for signed-in user.'),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: () async {
                          await FirebaseAuth.instance.signOut();
                        },
                        child: const Text('Go to Sign In'),
                      ),
                    ],
                  ),
                ),
              );
            }

            FirestoreUtils.syncAuthUserMirror(
              firebaseAuthUid: firebaseUser.uid,
              profile: appUser,
            );

            if (appUser.status != UserStatus.active) {
              final message = appUser.status == UserStatus.pending
                  ? 'Your account is pending approval.'
                  : 'Your account has been rejected.';
              return Scaffold(
                body: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(message),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: () async {
                          await FirebaseAuth.instance.signOut();
                        },
                        child: const Text('Back to Landing'),
                      ),
                    ],
                  ),
                ),
              );
            }

            return RoleUtils.routeForRole(appUser);
          },
        );
      },
    );
  }
}
