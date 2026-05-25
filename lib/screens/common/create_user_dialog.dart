import 'package:flutter/material.dart';

import '../../models/user_model.dart';
import '../../models/enums/user_status.dart';
import '../../models/department_model.dart';
import '../../models/organization_model.dart';
import '../../models/enums/organization_type.dart';
import '../../utils/common_helpers.dart';
import '../../utils/firestore_utils.dart';
import 'app_dialog_template.dart';
import '../../widgets/responsive/responsive_dialog_actions.dart';
import 'email_field.dart';
import 'phone_number_field.dart';
import 'read_only_field.dart';

Future<bool> showCreateUserDialog({
  required BuildContext context,
  String? roleCode,
  List<String>? roleOptions,
  String? initialRoleCode,
  required OrganizationModel organization,
  String department = '',
  UserModel? initialUser,
  Future<void> Function(UserModel user)? onUserSaved,
}) async {
  final firstNameController = TextEditingController(text: initialUser?.firstName ?? '');
  final lastNameController = TextEditingController(text: initialUser?.lastName ?? '');
  final emailController = TextEditingController(text: initialUser?.email ?? '');
  final phoneController = TextEditingController(
    text: (initialUser?.phone ?? '').replaceFirst('+91', '').replaceAll(RegExp(r'\D'), ''),
  );
  bool isSubmitting = false;
  final isEdit = initialUser != null;
  var selectedRoleCode = (roleCode ?? initialRoleCode ?? 'STU').trim();
  final normalizedRoleOptions = (roleOptions ?? const <String>[])
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toSet()
      .toList(growable: false);
  final roleLocked = roleCode != null && roleCode.trim().isNotEmpty;
  if (!roleLocked && normalizedRoleOptions.isNotEmpty && !normalizedRoleOptions.contains(selectedRoleCode)) {
    selectedRoleCode = normalizedRoleOptions.first;
  }

  final result = await showAppDialog<bool>(
    context: context,
    width: DialogWidthPreset.standard,
    child: StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          InputDecoration fieldDecoration(String hint, {bool readOnly = false}) {
            return InputDecoration(
              hintText: hint,
              filled: true,
              fillColor: readOnly ? const Color(0xFFF2F0F8) : Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: readOnly ? const Color(0xFFD2C8EC) : Colors.grey.shade300,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF6A38FF), width: 1.6),
              ),
            );
          }

          ButtonStyle compactButtonStyle() {
            return FilledButton.styleFrom(
              minimumSize: const Size(90, 40),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            );
          }

          ButtonStyle compactOutlineButtonStyle() {
            return OutlinedButton.styleFrom(
              minimumSize: const Size(90, 40),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            );
          }

          Future<void> saveUser() async {
            if (firstNameController.text.trim().isEmpty ||
                lastNameController.text.trim().isEmpty ||
                !isValidEmailInput(emailController.text) ||
                !isValidPhoneInput(phoneController.text)) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please fill valid user details')),
              );
              return;
            }

            setState(() => isSubmitting = true);
            try {
              final normalizedPhone = normalizePhoneE164(phoneController.text);
              final existing = await FirestoreUtils.fetchUserByPhone(normalizedPhone);
              if (existing != null &&
                  (!isEdit || existing.userId.trim() != initialUser.userId.trim())) {
                throw StateError('User already exists for this phone.');
              }

              if (isEdit) {
                final updatedUser = initialUser.copyWith(
                  firstName: firstNameController.text.trim(),
                  lastName: lastNameController.text.trim(),
                  email: emailController.text.trim(),
                );
                await FirestoreUtils.updateUser(
                  initialUser.userId,
                  <String, dynamic>{
                    'firstName': updatedUser.firstName,
                    'lastName': updatedUser.lastName,
                    'email': updatedUser.email,
                  },
                );
                if (onUserSaved != null) {
                  await onUserSaved(updatedUser);
                }
              } else {
                final departmentCode = DepartmentModel.resolveCode(department);
                final newUser = UserModel(
                  userId: '',
                  phone: normalizedPhone,
                  firstName: firstNameController.text.trim(),
                  lastName: lastNameController.text.trim(),
                  email: emailController.text.trim(),
                  role: selectedRoleCode,
                  orgType: organization.type,
                  orgId: organization.id,
                  department: department,
                  departmentCode: departmentCode,
                  status: UserStatus.active,
                  createdAt: DateTime.now(),
                  approvedAt: DateTime.now(),
                );
                final createdId = await FirestoreUtils.createUser(newUser);
                final createdUser = newUser.copyWith(userId: createdId);
                if (onUserSaved != null) {
                  await onUserSaved(createdUser);
                }
              }
              if (context.mounted) Navigator.of(context).pop(true);
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Unable to save user: $e')),
                );
              }
            } finally {
              if (context.mounted) {
                setState(() => isSubmitting = false);
              }
            }
          }

          return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      const Icon(Icons.person_add_alt_1_rounded, color: Color(0xFF6A38FF), size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          isEdit ? 'Edit User' : 'Create User',
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Role - ${_roleDisplayLabel(selectedRoleCode)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF595E80),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (!roleLocked && !isEdit && normalizedRoleOptions.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedRoleCode,
                      decoration: fieldDecoration('Select role'),
                      items: normalizedRoleOptions
                          .map(
                            (code) => DropdownMenuItem<String>(
                              value: code,
                              child: Text(_roleDisplayLabel(code)),
                            ),
                          )
                          .toList(growable: false),
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() => selectedRoleCode = value);
                      },
                    ),
                  ],
                  const SizedBox(height: 20),
                  const Text('First Name', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: firstNameController,
                    decoration: fieldDecoration('Enter first name'),
                  ),
                  const SizedBox(height: 12),
                  const Text('Last Name', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: lastNameController,
                    decoration: fieldDecoration('Enter last name'),
                  ),
                  const SizedBox(height: 12),
                  const Text('Email', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  EmailField(
                    controller: emailController,
                    decoration: fieldDecoration('Enter email'),
                  ),
                  const SizedBox(height: 12),
                  const Text('Phone', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  isEdit
                      ? ReadOnlyField(
                          value: normalizePhoneE164(phoneController.text),
                          hintText: 'Enter phone number',
                        )
                      : PhoneNumberField(
                          controller: phoneController,
                          decoration: fieldDecoration('Enter phone number'),
                        ),
                  const SizedBox(height: 14),
                  ResponsiveDialogActions(
                    children: <Widget>[
                      FilledButton(
                        onPressed: isSubmitting ? null : saveUser,
                        style: compactButtonStyle(),
                        child: isSubmitting
                            ? const SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text(isEdit ? 'Save' : 'Create'),
                      ),
                      OutlinedButton(
                        onPressed: isSubmitting ? null : () => Navigator.of(context).pop(false),
                        style: compactOutlineButtonStyle(),
                        child: const Text('Cancel'),
                      ),
                    ],
                  ),
                ],
          );
        },
      ),
  );
  return result ?? false;
}

String _roleDisplayLabel(String roleCode) {
  switch (roleCode) {
    case 'SADM':
      return 'System Admin';
    case 'CADM':
      return 'College Admin';
    case 'DADM':
      return 'Department Admin';
    case 'FAC':
      return 'Faculty';
    case 'JUD':
      return 'Judge';
    case 'COO':
      return 'Coordinator';
    case 'STU':
      return 'Student';
    default:
      return 'User';
  }
}
