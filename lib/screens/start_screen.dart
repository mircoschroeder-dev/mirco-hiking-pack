import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:packliste_core/conditions.dart';

import '../links.dart';
import '../state/providers.dart';
import '../texte.dart';
import '../theme.dart';
import 'packlist_screen.dart';

class StartScreen extends ConsumerStatefulWidget {
  const StartScreen({super.key});

  @override
  ConsumerState<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends ConsumerState<StartScreen> {
  TripLength? _length;
  bool? _withTent;
  Season? _season;
  Weather? _weather;

  bool get _isDay => _length == TripLength.day;

  bool get _complete =>
      _length != null &&
      (_isDay || _withTent != null) &&
      _season != null &&
      _weather != null;

  void _open() {
    ref
        .read(currentListProvider.notifier)
        .open(
          ListConditions(
            length: _length!,
            withTent: _withTent ?? false,
            season: _season!,
            weather: _weather!,
          ),
        );
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const PacklistScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final repository = ref.watch(itemRepositoryProvider);
    final appData = ref.watch(appDataProvider);
    final notice = ref.watch(noticeProvider);
    final ready = repository.hasValue && appData.hasValue;

    final Widget body;
    if (repository.hasError || appData.hasError) {
      body = Center(child: Text(Texte.ladenFehlgeschlagen));
    } else if (!ready) {
      body = const Center(child: CircularProgressIndicator());
    } else {
      body = ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        children: [
          _ChoiceGroup<TripLength>(
            title: Texte.dauer,
            values: TripLength.values,
            selected: _length,
            label: Texte.laenge,
            onSelected: (v) => setState(() => _length = v),
          ),
          if (_length != null && !_isDay)
            _ChoiceGroup<bool>(
              title: Texte.uebernachtung,
              values: const [false, true],
              selected: _withTent,
              label: (tent) => tent ? Texte.mitZelt : Texte.ohneZelt,
              onSelected: (v) => setState(() => _withTent = v),
            ),
          _ChoiceGroup<Season>(
            title: Texte.jahreszeit,
            values: Season.values,
            selected: _season,
            label: Texte.saison,
            onSelected: (v) => setState(() => _season = v),
          ),
          _ChoiceGroup<Weather>(
            title: Texte.wetter,
            values: Weather.values,
            selected: _weather,
            label: Texte.wetterName,
            onSelected: (v) => setState(() => _weather = v),
          ),
          const SizedBox(height: 24),
          const _YoutubeLink(),
          const SizedBox(height: 28),
          const _AppName(),
          const SizedBox(height: 12),
        ],
      );
    }

    return MapBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: Text(Texte.startTitel)),
        body: Column(
          children: [
            if (notice != null)
              Flexible(
                child: SingleChildScrollView(
                  child: MaterialBanner(
                    content: Text(notice),
                    actions: [
                      TextButton(
                        onPressed: () =>
                            ref.read(noticeProvider.notifier).clear(),
                        child: Text(Texte.hinweisSchliessen),
                      ),
                    ],
                  ),
                ),
              ),
            Expanded(child: body),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: ready && _complete ? _open : null,
                    child: Text(Texte.listeOeffnen),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Eine Ueberschrift und darunter grosse Auswahlfelder in zwei Spalten.
class _ChoiceGroup<T> extends StatelessWidget {
  const _ChoiceGroup({
    required this.title,
    required this.values,
    required this.selected,
    required this.label,
    required this.onSelected,
  });

  final String title;
  final List<T> values;
  final T? selected;
  final String Function(T) label;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 8),
          child: Text(title.toUpperCase(), style: mapLabelStyle(context)),
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            const gap = 8.0;
            final width = (constraints.maxWidth - gap) / 2;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (final value in values)
                  SizedBox(
                    width: width,
                    child: Card(
                      margin: EdgeInsets.zero,
                      color: value == selected ? scheme.primary : null,
                      child: ListTile(
                        minTileHeight: 60,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                        ),
                        selected: value == selected,
                        selectedColor: scheme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        title: Text(label(value), textAlign: TextAlign.center),
                        onTap: () => onSelected(value),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

/// Dezenter Hinweis auf Mircos Kanal. Oeffnet den Browser bzw. die YouTube-App;
/// die App selbst braucht dafuer keine Internet-Berechtigung.
class _YoutubeLink extends StatelessWidget {
  const _YoutubeLink();

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      onPressed: openYoutubeChannel,
      icon: const Icon(Icons.play_circle_outline),
      label: Text(Texte.youtubeUnterstuetzen, textAlign: TextAlign.center),
    );
  }
}

/// App-Name als Abschluss der Startseite, wie der Titel unten auf einer Karte.
class _AppName extends StatelessWidget {
  const _AppName();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          Texte.appName,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(Texte.untertitel.toUpperCase(), style: mapLabelStyle(context)),
      ],
    );
  }
}
