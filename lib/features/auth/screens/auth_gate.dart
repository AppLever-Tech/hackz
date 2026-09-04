import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/enums/account_workspace_phase.dart';
import '../../user/models/enums/user_status.dart';
import '../../user/models/enums/user_role.dart';
import '../../user/models/user_model.dart';
import '../services/auth_status_resolver.dart';
import '../../../utils/firestore_utils.dart';
import '../../user/services/role_utils.dart';
import '../../app_metadata/services/app_metadata_service.dart';
import '../../org_settings/services/org_settings_service.dart';
import 'landing_screen.dart';
import '../widgets/signup/account_status_workspace.dart';
import 'package:hackz/core/workspace/workspace_controller.dart';
import 'package:hackz/core/firebase/hackz_firebase.dart';
import 'package:hackz/core/firebase/last_organisation_code_store.dart';
import 'package:hackz/core/firebase/tenant_firebase.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  StreamSubscription<User?>? _authSub;
  bool _sessionReady = false;
  bool _listening = false;

  @override
  void initState() {
    super.initState();
    unawaited(_prepareSession());
  }

  Future<void> _prepareSession() async {
    final String? lastCode = await LastOrganisationCodeStore.read();
    if (lastCode != null && !HackzFirebase.isTenantBound) {
      try {
        await TenantFirebase.connect(lastCode);
      } catch (_) {
        // Last code is a convenience. Failed restore still shows landing.
      }
    }
    if (!mounted) return;
    HackzFirebase.generation.addListener(_onFirebaseGeneration);
    _listening = true;
    _listenAuth();
    setState(() => _sessionReady = true);
  }

  void _onFirebaseGeneration() {
    _listenAuth();
  }

  void _listenAuth() {
    _authSub?.cancel();
    _authSub = HackzFirebase.current.auth.authStateChanges().listen((User? user) {
      if (user == null) {
        WorkspaceController.instance.close();
        OrgSettingsService.instance.clearCache();
      }
    });
  }

  @override
  void dispose() {
    if (_listening) {
      HackzFirebase.generation.removeListener(_onFirebaseGeneration);
    }
    _authSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_sessionReady) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return ValueListenableBuilder<int>(
      valueListenable: HackzFirebase.generation,
      builder: (BuildContext context, int _, Widget? __) {
        return StreamBuilder<User?>(
          stream: HackzFirebase.current.auth.authStateChanges(),
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
              future: AuthStatusResolver.resolveSignedInUser(firebaseUser),
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
                              await TenantFirebase.releaseSession();
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
                  return AccountStatusWorkspace(
                    user: appUser,
                    phase: appUser.status.toWorkspacePhase,
                    onSignOut: () async {
                      await TenantFirebase.releaseSession();
                    },
                  );
                }

                // Returning SysAdmin sessions: seed App Metadata if Firestore was wiped
                // or docs were never written (idempotent after success).
                if (UserRole.fromCode(appUser.role) == UserRole.sysAdmin) {
                  unawaited(AppMetadataService.ensureSeeded());
                }

                return RoleUtils.routeForRole(appUser);
              },
            );
          },
        );
      },
    );
  }
}
