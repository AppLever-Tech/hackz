import 'package:flutter/material.dart';

import '../../../core/responsive/mobile_toolbar_button_styles.dart';
import '../../../core/responsive/responsive_helper.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/ui/common/page_header_context_pill.dart';
import '../../../core/ui/data_view/data_table_view.dart';
import '../../../core/ui/feedback/feedback.dart';
import '../../../core/ui/inputs/hackz_input_decoration.dart';
import '../../../core/ui/inputs/icon_only_filter_button.dart';
import '../../../core/ui/loading/hkz_progress_indicator.dart';
import '../../dashboard/chrome/dashboard_chrome_controller.dart';
import '../../dashboard/chrome/dashboard_chrome_scope.dart';
import '../../dashboard/chrome/empty_search_state.dart';
import '../../ideathons/models/ideathon_type.dart';
import '../../imports/imports.dart';
import '../../user/models/enums/user_role.dart';
import '../../user/models/user_model.dart';
import '../services/coordinator_team_registration_service.dart';
import '../widgets/team_registration_table_columns.dart';

/// Coordinator workspace for Team Registration CSV import.
class TeamRegistrationScreen extends StatefulWidget {
  const TeamRegistrationScreen({super.key, required this.user});

  final UserModel user;

  @override
  State<TeamRegistrationScreen> createState() => _TeamRegistrationScreenState();
}

class _TeamRegistrationScreenState extends State<TeamRegistrationScreen> {
  final TextEditingController _searchController = TextEditingController();

  Future<CoordinatorTeamRegistrationSnapshot>? _future;
  CoordinatorTeamRegistrationSnapshot? _last;
  TeamRegistrationOriginFilter _originFilter = TeamRegistrationOriginFilter.all;
  DashboardChromeController? _chrome;
  String _orgName = '';

  static const Color _filterAll = Color(0xFF4A67FF);
  static const Color _internalColor = Color(0xFF0369A1);
  static const Color _externalColor = Color(0xFF6A38FF);

  @override
  void initState() {
    super.initState();
    _orgName = widget.user.orgId;
    _load();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _chrome ??= DashboardChromeScope.maybeOf(context);
    _syncHeaderContext();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String get _orgLabel {
    final String org = _orgName.trim().isEmpty ? widget.user.orgId : _orgName.trim();
    return org.isEmpty ? '—' : org;
  }

  void _syncHeaderContext() {
    _chrome?.setHeaderContextPills(<PageHeaderContextItem>[
      PageHeaderContextItem.organization(_orgLabel),
    ]);
  }

  void _load() {
    setState(() {
      _future = CoordinatorTeamRegistrationService.load(widget.user);
    });
  }

  Future<void> _openImport(String orgName) async {
    if (!ImportPlatformSupport.isSupported(context)) {
      FeedbackService.showInfo(
        context,
        title: 'Use a larger screen',
        message: 'Team Registration import is available on tablet and desktop.',
      );
      return;
    }
    final bool? imported = await showTeamRegistrationImportWorkflow(
      context: context,
      actor: widget.user,
      orgName: orgName,
    );
    if (imported == true && mounted) _load();
  }

  void _clearSearchAndFilters() {
    _searchController.clear();
    setState(() => _originFilter = TeamRegistrationOriginFilter.all);
  }

  @override
  Widget build(BuildContext context) {
    if (UserRole.fromCode(widget.user.role) != UserRole.coordinator) {
      return const Center(child: Text('Access denied: Coordinator only'));
    }

    return FutureBuilder<CoordinatorTeamRegistrationSnapshot>(
      future: _future,
      builder: (BuildContext context, AsyncSnapshot<CoordinatorTeamRegistrationSnapshot> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && _last == null) {
          return const Center(child: HkzProgressIndicator(size: 36));
        }
        if (snapshot.hasError && _last == null) {
          return Center(
            child: Text(
              'Unable to load teams: ${snapshot.error}',
              style: const TextStyle(color: Color(0xFF64748B)),
            ),
          );
        }
        final CoordinatorTeamRegistrationSnapshot data = snapshot.data ??
            _last ??
            const CoordinatorTeamRegistrationSnapshot(orgName: '', rows: <CoordinatorTeamRegistrationRow>[]);
        _last = data;
        final String loadedOrg = data.orgName.trim();
        if (loadedOrg.isNotEmpty && loadedOrg != _orgName) {
          _orgName = loadedOrg;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _syncHeaderContext();
          });
        }
        final List<CoordinatorTeamRegistrationRow> visible = CoordinatorTeamRegistrationService.filter(
          rows: data.rows,
          search: _searchController.text,
          origin: _originFilter,
        );
        final bool searching =
            _searchController.text.trim().isNotEmpty || _originFilter != TeamRegistrationOriginFilter.all;

        return Padding(
          padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _toolbar(data.orgName),
              const SizedBox(height: 12),
              Expanded(
                child: visible.isEmpty
                    ? EmptySearchState.teams(
                        title: searching || data.rows.isNotEmpty
                            ? 'No teams found'
                            : 'No teams registered yet',
                        message: searching || data.rows.isNotEmpty
                            ? 'Try adjusting your search or filters.'
                            : 'Import a CSV to register teams for this college.',
                        clearLabel: searching ? 'Clear search' : 'Refresh',
                        onClearSearch: searching ? _clearSearchAndFilters : _load,
                      )
                    : DataTableView<CoordinatorTeamRegistrationRow>(
                        items: visible,
                        columns: TeamRegistrationTableColumns.build(),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _toolbar(String orgName) {
    final bool mobile = ResponsiveHelper.isMobile(context);
    final bool canImport = !mobile && ImportPlatformSupport.isSupported(context);
    final String college = orgName.trim().isEmpty ? widget.user.orgId : orgName.trim();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        const Text(
          'Registered Teams',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextField(
            controller: _searchController,
            style: HackzInputDecoration.fieldTextStyle,
            decoration: HackzInputDecoration.decorate(
              hintText: 'Search team names',
              prefixIcon: const Icon(AppIcons.search, size: 18),
              contentPaddingOverride: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
        ),
        const SizedBox(width: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerRight,
          child: _originFilters(),
        ),
        if (canImport) ...<Widget>[
          MobileToolbarButtonStyles.verticalSeparator(),
          OutlinedButton.icon(
            onPressed: college.isEmpty ? null : () => _openImport(college),
            icon: const Icon(AppIcons.submissions, size: 16),
            label: const Text('Import CSV'),
            style: MobileToolbarButtonStyles.outlined(compact: true),
          ),
        ],
      ],
    );
  }

  Widget _originFilters() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        IconOnlyFilterButton(
          icon: AppIcons.teams,
          tooltip: 'All',
          selected: _originFilter == TeamRegistrationOriginFilter.all,
          color: _filterAll,
          onTap: () => setState(() => _originFilter = TeamRegistrationOriginFilter.all),
        ),
        IconOnlyFilterButton(
          icon: AppIcons.organizations,
          tooltip: IdeathonType.internal.label,
          selected: _originFilter == TeamRegistrationOriginFilter.internal,
          color: _internalColor,
          onTap: () => setState(() => _originFilter = TeamRegistrationOriginFilter.internal),
        ),
        IconOnlyFilterButton(
          icon: AppIcons.openInNew,
          tooltip: IdeathonType.external.label,
          selected: _originFilter == TeamRegistrationOriginFilter.external,
          color: _externalColor,
          onTap: () => setState(() => _originFilter = TeamRegistrationOriginFilter.external),
        ),
      ],
    );
  }
}
