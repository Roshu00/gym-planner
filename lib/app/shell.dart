import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../ui/chalkline_ui.dart';
import 'common.dart';
import 'creator_profile.dart';
import 'discover.dart';
import 'plan_tab.dart';
import 'profile.dart';
import 'library.dart';
import 'today.dart';

enum AppTab { today, plan, discover, library, profile }

/// Bottom-nav shell. All tabs use the light theme.
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

  void _select(int i) {
    if (i == _index) return;
    HapticFeedback.selectionClick();
    HomeShell.tab.value = AppTab.values[i];
  }

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
    const tabs = [TodayScreen(), PlanTabScreen(), DiscoverScreen(), LibraryScreen(), ProfileScreen()];
    return ClThemeScope(
      theme: ClTheme.light,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark,
        child: Scaffold(
          body: Column(
            children: [
              Expanded(
                // The nav bar below already keeps clear of the home indicator,
                // so the tabs must not add that inset again above it.
                child: MediaQuery.removePadding(
                  context: context,
                  removeBottom: true,
                  child: _TabStack(index: _index, tabs: tabs),
                ),
              ),
              const _SyncBanner(),
              ClBottomNav(selected: _index, onChanged: _select),
            ],
          ),
        ),
      ),
    );
  }
}

/// Keeps every tab alive (like an [IndexedStack]) but moves between them:
/// the new tab fades in while sliding a little from the side of its nav item,
/// the old one fades out towards the other side.
class _TabStack extends StatefulWidget {
  const _TabStack({required this.index, required this.tabs});

  final int index;
  final List<Widget> tabs;

  @override
  State<_TabStack> createState() => _TabStackState();
}

class _TabStackState extends State<_TabStack> {
  /// The tab animating out; it stays on stage until its fade ends.
  int? _leaving;

  @override
  void didUpdateWidget(_TabStack old) {
    super.didUpdateWidget(old);
    if (old.index != widget.index) _leaving = old.index;
  }

  @override
  Widget build(BuildContext context) {
    final index = widget.index;
    final duration = context.motion(ClMotion.tab);
    return Stack(
      fit: StackFit.expand,
      children: [
        for (var i = 0; i < widget.tabs.length; i++)
          Offstage(
            offstage: i != index && i != _leaving,
            child: IgnorePointer(
              ignoring: i != index,
              child: ExcludeSemantics(
                excluding: i != index,
                child: AnimatedSlide(
                  duration: duration,
                  curve: ClMotion.tabCurve,
                  offset: Offset(i == index ? 0 : (i < index ? -0.06 : 0.06), 0),
                  child: AnimatedOpacity(
                    duration: duration,
                    curve: ClMotion.tabCurve,
                    opacity: i == index ? 1 : 0,
                    onEnd: () {
                      if (i == _leaving && mounted) setState(() => _leaving = null);
                    },
                    child: ClThemeScope(
                      theme: ClTheme.light,
                      child: TickerMode(enabled: i == index, child: widget.tabs[i]),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
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
