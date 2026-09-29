import 'package:flutter/material.dart';

import '../domain/models.dart';
import '../ui/chalkline_ui.dart';
import 'common.dart';

/// Monthly subscription to a creator. Returns true when subscribed.
/// Payment is not connected in the MVP; the sheet says so plainly.
Future<bool> showSubscribeSheet(BuildContext context, Creator creator) async {
  final store = context.readStore;
  final cl = context.cl;
  final ok = await showClSheet<bool>(
    context,
    title: 'Pretplata.',
    label: creator.name,
    builder: (context) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClStatBar(
          large: true,
          stats: [
            ClStat(
              label: 'Mesečno',
              value: formatPrice(creator.priceMonthly).replaceAll(' €', ''),
              unit: '€',
            ),
            ClStat(label: 'Programi', value: '${store.programsOf(creator.id).length}'),
          ],
        ),
        gapS,
        for (final line in [
          'Svi programi, treninzi i vežbe trenera',
          'Napomene trenera uz svaku vežbu',
          'Otkazuješ kad hoćeš, istorija ostaje tvoja',
        ])
          Padding(
            padding: const EdgeInsets.only(bottom: ClSpace.s2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(ClIcons.check, size: 16, color: cl.colors.ink),
                const SizedBox(width: ClSpace.s2),
                Expanded(child: Text(line, style: cl.text.body)),
              ],
            ),
          ),
        gapS,
        const ClNotice('Plaćanje još nije povezano. U ovoj verziji pretplata se aktivira bez naplate.'),
        const SizedBox(height: ClSpace.s6),
        ClButton(label: 'Pretplati se', expand: true, onPressed: () => Navigator.of(context).pop(true)),
      ],
    ),
  );
  if (ok == true) store.subscribe(creator.id);
  return ok == true;
}
