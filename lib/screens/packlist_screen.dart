import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:packliste_core/conditions.dart';
import 'package:packliste_core/models.dart';
import 'package:packliste_core/weights.dart';

import '../state/providers.dart';
import '../texte.dart';
import '../theme.dart';
import '../widgets/item_sheet.dart';

enum _MenuAction { packAll, resetAll, rebuild }

enum _ItemAction { edit, toBuy, available, leave, delete }

class PacklistScreen extends ConsumerWidget {
  const PacklistScreen({super.key});

  Future<void> _confirmRebuild(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(Texte.listeNeuTitel),
        content: Text(Texte.listeNeuText),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(Texte.abbrechen),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(Texte.neuAufbauen),
          ),
        ],
      ),
    );
    if (confirmed ?? false) {
      await ref.read(currentListProvider.notifier).rebuild();
    }
  }

  Future<void> _editItem(
    BuildContext context,
    WidgetRef ref,
    TripItem item,
  ) async {
    final result = await showItemSheet(context, item: item);
    if (result == null) return;
    final notifier = ref.read(currentListProvider.notifier);
    if (result.deleted) {
      await notifier.removeItem(item.id);
    } else {
      await notifier.putItem(result.item!);
    }
  }

  void _deleteItem(BuildContext context, WidgetRef ref, TripItem item) {
    final notifier = ref.read(currentListProvider.notifier);
    notifier.removeItem(item.id);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(Texte.gegenstandGeloescht(item.name)),
          duration: const Duration(seconds: 8),
          persist: false,
          action: SnackBarAction(
            label: Texte.rueckgaengig,
            onPressed: () => notifier.putItem(item),
          ),
        ),
      );
  }

  Widget _row(BuildContext context, WidgetRef ref, TripItem item) {
    final notifier = ref.read(currentListProvider.notifier);
    return _ItemRow(
      item: item,
      onToggle: () => notifier.togglePacked(item.id),
      onAction: (action) {
        switch (action) {
          case _ItemAction.edit:
            _editItem(context, ref, item);
          case _ItemAction.toBuy:
            notifier.setStatus(item.id, ItemStatus.toBuy);
          case _ItemAction.available:
            notifier.setStatus(item.id, ItemStatus.available);
          case _ItemAction.leave:
            notifier.setStatus(item.id, ItemStatus.left);
          case _ItemAction.delete:
            _deleteItem(context, ref, item);
        }
      },
    );
  }

  Future<void> _addItem(BuildContext context, WidgetRef ref) async {
    final result = await showItemSheet(
      context,
      categories: ref.read(itemRepositoryProvider).requireValue.categories,
    );
    if (result?.item != null) {
      await ref.read(currentListProvider.notifier).putItem(result!.item!);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(currentListProvider)!;
    final notifier = ref.read(currentListProvider.notifier);
    final repository = ref.watch(itemRepositoryProvider).requireValue;
    final visible = visibleItems(list.items, list.extras, repository);
    final offered = availableExtras(list.items, repository);

    final rows = <Widget>[
      if (offered.isNotEmpty)
        _ExtrasSection(
          offered: offered,
          enabled: list.extras,
          onChanged: notifier.setExtra,
        ),
    ];
    String? category;
    for (final item in visible.where((i) => !i.isLeft)) {
      if (item.category != category) {
        category = item.category;
        rows.add(_CategoryHeader(category));
      }
      rows.add(_row(context, ref, item));
    }
    final left = visible.where((i) => i.isLeft).toList();
    if (left.isNotEmpty) {
      rows.add(_CategoryHeader(Texte.nichtMitnehmen));
      rows.addAll(left.map((item) => _row(context, ref, item)));
    }

    return MapBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(
            Texte.listenTitel(list.conditions),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          actions: [
            PopupMenuButton<_MenuAction>(
              iconSize: 28,
              onSelected: (action) => switch (action) {
                _MenuAction.packAll => notifier.packAll(),
                _MenuAction.resetAll => notifier.resetPacked(),
                _MenuAction.rebuild => _confirmRebuild(context, ref),
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: _MenuAction.packAll,
                  height: 56,
                  child: Text(Texte.allesAbhaken),
                ),
                PopupMenuItem(
                  value: _MenuAction.resetAll,
                  height: 56,
                  child: Text(Texte.allesZuruecksetzen),
                ),
                PopupMenuItem(
                  value: _MenuAction.rebuild,
                  height: 56,
                  child: Text(Texte.listeNeuAufbauen),
                ),
              ],
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _addItem(context, ref),
          icon: const Icon(Icons.add),
          label: Text(Texte.gegenstandHinzufuegen),
        ),
        body: Column(
          children: [
            _WeightHeader(items: visible),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: 96),
                children: rows,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExtrasSection extends StatelessWidget {
  const _ExtrasSection({
    required this.offered,
    required this.enabled,
    required this.onChanged,
  });

  final Set<TripOption> offered;
  final Set<TripOption> enabled;
  final void Function(TripOption, bool) onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          for (final extra in allExtras.where(offered.contains))
            FilterChip(
              label: Text(Texte.extra(extra)),
              labelStyle: const TextStyle(fontSize: 16),
              padding: const EdgeInsets.all(8),
              selected: enabled.contains(extra),
              onSelected: (on) => onChanged(extra, on),
            ),
        ],
      ),
    );
  }
}

class _WeightHeader extends StatelessWidget {
  const _WeightHeader({required this.items});

  final List<TripItem> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final summary = summarizeWeights(items);
    int count(ItemStatus status) =>
        items.where((i) => i.status == status).length;
    final packed = count(ItemStatus.packed);
    final total = items.where((i) => !i.isLeft).length;
    return Material(
      color: theme.colorScheme.surface,
      shape: Border(
        top: BorderSide(color: theme.colorScheme.outline),
        bottom: BorderSide(color: theme.colorScheme.outline),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Flexible(
                  child: Text(
                    Texte.rucksackStart,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  Texte.kg(summary.packStartG),
                  style: weightStyle(context, 28),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _Figure(Texte.basisgewicht, Texte.kg(summary.baseG)),
                _Figure(Texte.verbrauch, Texte.kg(summary.consumableG)),
                _Figure(Texte.getragenLabel, Texte.kg(summary.wornG)),
              ],
            ),
            if (summary.itemsWithoutWeight > 0)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(Texte.ohneGewicht(summary.itemsWithoutWeight)),
              ),
            const SizedBox(height: 12),
            ScaleBar(value: total == 0 ? 0 : packed / total),
            const SizedBox(height: 6),
            Text(Texte.gepackt(packed, total)),
            const SizedBox(height: 6),
            Row(
              children: [
                _Legend(ItemStatus.packed, Texte.statusGepackt, packed),
                _Legend(
                  ItemStatus.available,
                  Texte.statusVorhanden,
                  count(ItemStatus.available),
                ),
                _Legend(
                  ItemStatus.toBuy,
                  Texte.statusKaufen,
                  count(ItemStatus.toBuy),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend(this.status, this.label, this.count);

  final ItemStatus status;
  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Row(
        children: [
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: statusColor(status, theme.brightness),
              border: Border.all(color: theme.colorScheme.outline),
            ),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text('$label $count', style: theme.textTheme.bodySmall),
          ),
        ],
      ),
    );
  }
}

class _Figure extends StatelessWidget {
  const _Figure(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.bodySmall),
          Text(value, style: theme.textTheme.bodyLarge),
        ],
      ),
    );
  }
}

class _CategoryHeader extends StatelessWidget {
  const _CategoryHeader(this.category);

  final String category;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 22, 16, 6),
      child: Row(
        children: [
          // Die Beschriftung bekommt den meisten Platz, die Linie den Rest.
          Flexible(
            flex: 5,
            child: Text(category.toUpperCase(), style: mapLabelStyle(context)),
          ),
          const SizedBox(width: 10),
          Expanded(child: Divider(color: theme.colorScheme.outline)),
        ],
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({
    required this.item,
    required this.onToggle,
    required this.onAction,
  });

  final TripItem item;
  final VoidCallback onToggle;
  final ValueChanged<_ItemAction> onAction;

  String get _weightLine {
    final String weight;
    if (!item.hasWeight) {
      weight = Texte.ohneGewichtZeile;
    } else if (item.quantity == 1) {
      weight = '${item.weightG} g';
    } else {
      weight = '${item.quantity} × ${item.weightG} g = ${item.totalWeightG} g';
    }
    final line = switch (item.weightType) {
      WeightType.base => weight,
      WeightType.consumable => '$weight · ${Texte.verbrauch}',
      WeightType.worn => '$weight · ${Texte.getragen}',
    };
    return item.status == ItemStatus.toBuy
        ? '$line · ${Texte.nochKaufen}'
        : line;
  }

  List<PopupMenuEntry<_ItemAction>> _menu(BuildContext context) {
    PopupMenuItem<_ItemAction> entry(_ItemAction action, String label) =>
        PopupMenuItem(value: action, height: 56, child: Text(label));
    return [
      if (item.isLeft)
        entry(_ItemAction.available, Texte.dochMitnehmen)
      else ...[
        if (item.status == ItemStatus.toBuy)
          entry(_ItemAction.available, Texte.istVorhanden)
        else
          entry(_ItemAction.toBuy, Texte.mussGekauftWerden),
        entry(_ItemAction.leave, Texte.nichtMitnehmen),
      ],
      entry(_ItemAction.edit, Texte.bearbeiten),
      entry(_ItemAction.delete, Texte.vonListeLoeschen),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = item.isLeft
        ? theme.colorScheme.onSurfaceVariant
        : theme.colorScheme.onSurface;
    final title = item.quantity > 1
        ? '${item.quantity} × ${item.name}'
        : item.name;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      // Eigene Flaeche, damit die Zeilenfarbe beim Scrollen nicht ueber den
      // Rand der Liste hinaus gemalt wird.
      child: Material(
        type: MaterialType.transparency,
        child: ListTile(
          contentPadding: const EdgeInsets.only(left: 8, right: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
            side: item.isLeft
                ? BorderSide.none
                : BorderSide(color: theme.colorScheme.outline),
          ),
          tileColor: statusColor(item.status, theme.brightness),
          onTap: item.isLeft ? null : onToggle,
          leading: item.isLeft
              ? const SizedBox(width: 48)
              : Checkbox(value: item.isPacked, onChanged: (_) => onToggle()),
          title: Text(
            title,
            style: TextStyle(
              fontWeight: item.essential ? FontWeight.w600 : FontWeight.w400,
              color: textColor,
              decoration: item.isPacked ? TextDecoration.lineThrough : null,
            ),
          ),
          subtitle: Text(
            item.note.isEmpty ? _weightLine : '$_weightLine\n${item.note}',
            style: TextStyle(color: textColor),
          ),
          trailing: PopupMenuButton<_ItemAction>(
            iconSize: 28,
            icon: Icon(Icons.more_horiz, color: textColor),
            tooltip: Texte.aktionen,
            onSelected: onAction,
            itemBuilder: _menu,
          ),
        ),
      ),
    );
  }
}
