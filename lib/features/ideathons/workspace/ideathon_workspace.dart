import 'package:flutter/material.dart';

import '../../../workspace/core/workspace_host.dart';
import '../../../workspace/core/workspace_route.dart';
import 'ideathon_workspace_body.dart';
import 'ideathon_workspace_loader.dart';

abstract final class IdeathonWorkspace {
  IdeathonWorkspace._();

  static WorkspaceRoute _route(String ideathonId) {
    late IdeathonWorkspaceViewModel vm;
    return WorkspaceRoute(
      id: 'ideathon:$ideathonId',
      title: 'Ideathon',
      subtitle: WorkspaceRoute.loadingSubtitle,
      prepare: () async {
        vm = await IdeathonWorkspaceLoader.load(ideathonId);
      },
      builder: (BuildContext context) => IdeathonWorkspaceBody(vm: vm),
    );
  }

  static void open(BuildContext context, String ideathonId) {
    final String id = ideathonId.trim();
    if (id.isEmpty) return;
    HkzWorkspace.open(context, _route(id));
  }
}
