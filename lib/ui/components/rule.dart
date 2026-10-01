import 'package:flutter/widgets.dart';

import '../theme.dart';
import '../tokens/spacing.dart';

/// Quiet separator above a data block.
class ClRule extends StatelessWidget {
  const ClRule({super.key});

  @override
  Widget build(BuildContext context) => Container(height: ClSize.hairline, color: context.clColors.border);
}

/// 1px `border` between rows.
class ClDivider extends StatelessWidget {
  const ClDivider({super.key, this.vertical = false});

  final bool vertical;

  @override
  Widget build(BuildContext context) => Container(
    width: vertical ? ClSize.hairline : null,
    height: vertical ? null : ClSize.hairline,
    color: context.clColors.border,
  );
}

/// Section heading: a 22px display title, one step below the screen title
/// and clearly above row text. Optional trailing action.
class ClSectionHeader extends StatelessWidget {
  const ClSectionHeader({super.key, required this.label, this.trailing});

  final String label;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final text = context.clText;
    return Padding(
      padding: const EdgeInsets.only(top: ClSpace.s2, bottom: ClSpace.s3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                label,
                style: text.displayM.copyWith(fontSize: 22, height: 26 / 22, letterSpacing: -0.5),
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
