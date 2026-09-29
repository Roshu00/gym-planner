import 'package:flutter/material.dart';

import '../ui/chalkline_ui.dart';
import 'common.dart';
import 'creator_profile.dart';
import 'discover.dart';
import 'library.dart';
import 'profile.dart';
import 'progress.dart';
import 'today.dart';

enum AppTab { today, library, discover, progress, profile }

/// Bottom-nav shell. Each tab renders in its DESIGN.md theme: Today, Library
/// and Discover dark; Progress and Profile light, like a magazine page.
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

  static final _themes = [ClTheme.dark, ClTheme.dark, ClTheme.dark, ClTheme.light, ClTheme.light];

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
    const tabs = [TodayScreen(), LibraryScreen(), DiscoverScreen(), ProgressScreen(), ProfileScreen()];
    return ClThemeScope(
      theme: _themes[_index],
      child: Scaffold(
        body: Column(
          children: [
            Expanded(
              child: IndexedStack(
                index: _index,
                children: [
                  for (var i = 0; i < tabs.length; i++)
                    ClThemeScope(
                      theme: _themes[i],
                      child: TickerMode(enabled: i == _index, child: tabs[i]),
                    ),
                ],
              ),
            ),
            ClBottomNav(selected: _index, onChanged: _select),
          ],
        ),
      ),
    );
  }
}
