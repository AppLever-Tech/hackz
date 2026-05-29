import '../../user/models/user_model.dart';

/// Cached per-organization facts loaded alongside the org list.
class OrgOperationalData {
  const OrgOperationalData({
    this.collegeAdmin,
    this.departmentCount = 0,
  });

  final UserModel? collegeAdmin;
  final int departmentCount;
}
