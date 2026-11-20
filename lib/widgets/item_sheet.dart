import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:packliste_core/models.dart';

import '../state/providers.dart';
import '../texte.dart';

class ItemSheetResult {
  const ItemSheetResult.saved(TripItem this.item) : deleted = false;
  const ItemSheetResult.deleted() : item = null, deleted = true;

  final TripItem? item;
  final bool deleted;
}

/// Mit [item] wird bearbeitet, ohne [item] ein neuer Gegenstand angelegt;
/// dann muss [categories] gesetzt sein.
Future<ItemSheetResult?> showItemSheet(
  BuildContext context, {
  TripItem? item,
  List<String> categories = const [],
}) {
  return showModalBottomSheet<ItemSheetResult>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _ItemSheet(item: item, categories: categories),
  );
}

class _ItemSheet extends StatefulWidget {
  const _ItemSheet({required this.item, required this.categories});

  final TripItem? item;
  final List<String> categories;

  @override
  State<_ItemSheet> createState() => _ItemSheetState();
}

class _ItemSheetState extends State<_ItemSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.item?.name);
  late final _quantity = TextEditingController(
    text: '${widget.item?.quantity ?? 1}',
  );
  late final _weight = TextEditingController(
    text: widget.item?.weightG?.toString(),
  );
  late final _note = TextEditingController(text: widget.item?.note);
  late WeightType _type = widget.item?.weightType ?? WeightType.base;
  late String? _category = widget.categories.isEmpty
      ? null
      : widget.categories.last;

  @override
  void dispose() {
    _name.dispose();
    _quantity.dispose();
    _weight.dispose();
    _note.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final weightText = _weight.text.trim();
    final weight = weightText.isEmpty ? null : int.parse(weightText);
    final existing = widget.item;
    final item = existing != null
        ? existing.copyWith(
            name: _name.text.trim(),
            quantity: int.parse(_quantity.text.trim()),
            weightG: () => weight,
            weightType: _type,
            note: _note.text.trim(),
          )
        : TripItem(
            id: newId('eigen'),
            name: _name.text.trim(),
            category: _category!,
            quantity: int.parse(_quantity.text.trim()),
            weightG: weight,
            weightType: _type,
            note: _note.text.trim(),
          );
    Navigator.pop(context, ItemSheetResult.saved(item));
  }

  @override
  Widget build(BuildContext context) {
    const gap = SizedBox(height: 16);
    final isNew = widget.item == null;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isNew ? Texte.gegenstandNeu : Texte.gegenstandBearbeiten,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              gap,
              TextFormField(
                controller: _name,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(labelText: Texte.feldName),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? Texte.fehlerName : null,
              ),
              gap,
              TextFormField(
                controller: _quantity,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(labelText: Texte.feldMenge),
                validator: (v) => ((int.tryParse(v?.trim() ?? '') ?? 0) < 1)
                    ? Texte.fehlerMenge
                    : null,
              ),
              gap,
              TextFormField(
                controller: _weight,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: Texte.feldGewicht,
                  helperText: Texte.feldGewichtHinweis,
                ),
                validator: (v) {
                  final text = v?.trim() ?? '';
                  return text.isNotEmpty && int.tryParse(text) == null
                      ? Texte.fehlerGewicht
                      : null;
                },
              ),
              gap,
              Text(
                Texte.feldTyp,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              SegmentedButton<WeightType>(
                showSelectedIcon: false,
                style: SegmentedButton.styleFrom(
                  minimumSize: const Size(0, 52),
                ),
                segments: [
                  for (final type in WeightType.values)
                    ButtonSegment(
                      value: type,
                      label: Text(Texte.gewichtTyp(type)),
                    ),
                ],
                selected: {_type},
                onSelectionChanged: (s) => setState(() => _type = s.first),
              ),
              if (isNew) ...[
                gap,
                DropdownButtonFormField<String>(
                  initialValue: _category,
                  isExpanded: true,
                  decoration: InputDecoration(labelText: Texte.feldKategorie),
                  items: [
                    for (final c in widget.categories)
                      DropdownMenuItem(value: c, child: Text(c)),
                  ],
                  onChanged: (c) => setState(() => _category = c),
                ),
              ],
              gap,
              TextFormField(
                controller: _note,
                textCapitalization: TextCapitalization.sentences,
                maxLines: 2,
                decoration: InputDecoration(labelText: Texte.feldNotiz),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  if (!isNew) ...[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(
                          context,
                          const ItemSheetResult.deleted(),
                        ),
                        child: Text(Texte.loeschen),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: _save,
                      child: Text(Texte.speichern),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
