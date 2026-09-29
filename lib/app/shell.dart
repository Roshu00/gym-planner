import 'package:flutter/material.dart';

import '../ui/chalkline_ui.dart';
import 'common.dart';
import 'creator_profile.dart';
import 'discover.dart';
import 'plan_tab.dart';
import 'profile.dart';
import 'progress.dart';
import 'today.dart';

enum AppTab { today, plan, discover, progress, profile }

/// Bottom-nav shell. All tabs use the dark theme.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key, this.openCreatorId});

  final String? openCreatorId;

  /// Selected tab. Any screen can switch it, including pushed routes.
  static final tab = ValueNotifier(AppTab.today);

  /// Switches tab and closes pushed screens so the tab is visible.
  static void goTo(BuildContext context, AppTab to) {
    Navigator.of(context).popUntil((r) => r.isFirst);
    tab.value = to;
  }

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int get _index => HomeShell.tab.value.index;

  void _select(int i) => HomeShell.tab.value = AppTab.values[i];

  void _onTab() => setState(() {});

  @override
  void dispose() {
    HomeShell.tab.removeListener(_onTab);
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    HomeShell.tab.value = AppTab.today;
    HomeShell.tab.addListener(_onTab);
    final id = widget.openCreatorId;
    if (id != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) pushScreen(context, CreatorProfileScreen(creatorId: id), theme: ClTheme.light);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const tabs = [TodayScreen(), PlanTabScreen(), DiscoverScreen(), ProgressScreen(), ProfileScreen()];
    return ClThemeScope(
      theme: ClTheme.dark,
      child: Scaffold(
        body: Column(
          children: [
            Expanded(
              child: IndexedStack(
                index: _index,
                children: [
                  for (var i = 0; i < tabs.length; i++)
                    ClThemeScope(
                      theme: ClTheme.dark,
                      child: TickerMode(enabled: i == _index, child: tabs[i]),
                    ),
                ],
              ),
            ),
            const _SyncBanner(),
            ClBottomNav(selected: _index, onChanged: _select),
          ],
        ),
      ),
    );
  }
}

/// Shown on every tab while a change could not reach the server.
class _SyncBanner extends StatelessWidget {
  const _SyncBanner();

  @override
  Widget build(BuildContext context) {
    final store = context.store;
    final error = store.syncError;
    if (error == null) return const SizedBox.shrink();
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: context.clColors.border)),
      ),
      child: Padding(
        padding: const EdgeInsets.only(left: ClSpace.s4),
        child: Row(
          children: [
            Expanded(child: ClNotice(error, danger: true)),
            ClButton(label: 'Ponovo', variant: ClButtonVariant.text, onPressed: store.retrySync),
            ClIconButton(
              icon: ClIcons.close,
              semanticLabel: 'Sakrij poruku',
              onPressed: store.dismissSyncError,
            ),
          ],
        ),
      ),
    );
  }
}
