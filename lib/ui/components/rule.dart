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

/// Section heading: a bold sentence-case title, optional trailing action.
class ClSectionHeader extends StatelessWidget {
  const ClSectionHeader({super.key, required this.label, this.trailing});

  final String label;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final text = context.clText;
    return Padding(
      padding: const EdgeInsets.only(top: ClSpace.s1, bottom: ClSpace.s3),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(label, style: text.bodyStrong.copyWith(fontSize: 18, height: 22 / 18)),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
