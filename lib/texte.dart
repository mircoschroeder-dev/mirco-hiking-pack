import 'package:packliste_core/conditions.dart';
import 'package:packliste_core/models.dart';
import 'package:packliste_core/weights.dart';

/// Alle Texte der App, deutsch und englisch. Die Sprache folgt der
/// Handysprache: Deutsch bei deutschem Handy, sonst Englisch.
abstract final class Texte {
  static bool english = false;

  static String _t(String de, String en) => english ? en : de;

  static String get appName =>
      _t('Mircos Wanderrucksack', "Mirco's Hiking Pack");
  static String get untertitel =>
      _t('Packliste für Wanderungen', 'Packing list for hikers');

  // Startbildschirm
  static String get startTitel =>
      _t('Welche Packliste?', 'Which packing list?');
  static String get dauer => _t('Dauer', 'Duration');
  static String get uebernachtung => _t('Übernachtung', 'Overnight');
  static String get jahreszeit => _t('Jahreszeit', 'Season');
  static String get wetter => _t('Wetter', 'Weather');
  static String get listeOeffnen => _t('Liste öffnen', 'Open list');
  static String get ohneZelt => _t('Ohne Zelt', 'No tent');
  static String get mitZelt => _t('Mit Zelt', 'With tent');
  static String get hinweisSchliessen => _t('Schließen', 'Close');
  static String get dateiDefekt => _t(
    'Deine gespeicherten Daten konnten nicht gelesen werden. Die App startet '
        'deshalb leer. Die alte Datei bleibt als Sicherung erhalten.',
    'Your saved data could not be read, so the app starts empty. '
        'The old file is kept as a backup.',
  );
  static String get speichernFehlgeschlagen => _t(
    'Speichern hat nicht geklappt. Die letzte Änderung ist eventuell nicht gesichert.',
    'Saving failed. Your last change may not have been stored.',
  );
  static String get youtubeUnterstuetzen => _t(
    'Unterstütze mich: Abonniere meinen YouTube-Kanal',
    'Support me: subscribe to my YouTube channel',
  );
  static String get ladenFehlgeschlagen =>
      _t('Die App konnte nicht starten.', 'The app could not start.');

  static String laenge(TripLength l) => switch (l) {
    TripLength.day => _t('Tageswanderung', 'Day hike'),
    TripLength.short => _t('2–3 Tage', '2–3 days'),
    TripLength.week => _t('4–7 Tage', '4–7 days'),
    TripLength.long => _t('Länger als eine Woche', 'More than a week'),
  };

  static String saison(Season s) => switch (s) {
    Season.spring => _t('Frühling', 'Spring'),
    Season.summer => _t('Sommer', 'Summer'),
    Season.autumn => _t('Herbst', 'Autumn'),
    Season.winter => _t('Winter', 'Winter'),
  };

  static String wetterName(Weather w) => switch (w) {
    Weather.dry => _t('Trocken', 'Dry'),
    Weather.rainRisk => _t('Regengefahr', 'Chance of rain'),
  };

  static String listenTitel(ListConditions c) => [
    laenge(c.length),
    if (c.length != TripLength.day) c.withTent ? mitZelt : ohneZelt,
    saison(c.season),
    wetterName(c.weather),
  ].join(' · ');

  static String extra(TripOption o) => switch (o) {
    TripOption.rain => _t('Regen', 'Rain'),
    TripOption.photo => _t('Foto & Video', 'Photo & video'),
    TripOption.cooking => _t('Kochen', 'Cooking'),
    TripOption.dog => _t('Hund', 'Dog'),
    TripOption.nopower => _t('Ohne Strom', 'No power'),
  };

  // Packliste
  static String get allesAbhaken => _t('Alles abhaken', 'Check everything');
  static String get allesZuruecksetzen =>
      _t('Alles zurücksetzen', 'Uncheck everything');
  static String get listeNeuAufbauen =>
      _t('Liste neu aufbauen', 'Rebuild list');
  static String get listeNeuTitel =>
      _t('Liste neu aufbauen?', 'Rebuild this list?');
  static String get listeNeuText => _t(
    'Alle Änderungen an dieser Liste gehen verloren, auch selbst '
        'hinzugefügte Gegenstände. Deine eigenen Gewichte bleiben erhalten.',
    'All changes to this list will be lost, including items you added. '
        'Your own weights are kept.',
  );
  static String get abbrechen => _t('Abbrechen', 'Cancel');
  static String get neuAufbauen => _t('Neu aufbauen', 'Rebuild');
  static String get speichern => _t('Speichern', 'Save');
  static String get loeschen => _t('Löschen', 'Delete');
  static String get rueckgaengig => _t('Rückgängig', 'Undo');
  static String get gegenstandHinzufuegen => _t('Gegenstand', 'Item');
  static String get bearbeiten => _t('Bearbeiten', 'Edit');
  static String get aktionen => _t('Aktionen', 'Actions');
  static String get statusGepackt => _t('Gepackt', 'Packed');
  static String get statusVorhanden => _t('Vorhanden', 'Owned');
  static String get statusKaufen => _t('Kaufen', 'To buy');
  static String get nochKaufen => _t('noch kaufen', 'still to buy');
  static String get mussGekauftWerden =>
      _t('Muss noch gekauft werden', 'Still needs buying');
  static String get istVorhanden => _t('Ist vorhanden', 'Already owned');
  static String get nichtMitnehmen => _t('Nicht mitnehmen', 'Leave at home');
  static String get dochMitnehmen => _t('Doch mitnehmen', 'Take it after all');
  static String get vonListeLoeschen =>
      _t('Von der Liste löschen', 'Remove from list');
  static String gegenstandGeloescht(String name) =>
      _t('„$name“ gelöscht', '“$name” removed');
  static String get basisgewicht => _t('Basisgewicht', 'Base weight');
  static String get verbrauch => _t('Verbrauch', 'Consumables');
  static String get getragen => _t('getragen', 'worn');
  static String get getragenLabel => _t('Getragen', 'Worn');
  static String get rucksackStart =>
      _t('Rucksack beim Start', 'Pack weight at start');
  static String get ohneGewichtZeile => _t('ohne Gewicht', 'no weight');
  static String gepackt(int von, int gesamt) =>
      _t('$von von $gesamt gepackt', '$von of $gesamt packed');
  static String kg(int grams) =>
      formatKg(grams, decimalSeparator: english ? '.' : ',');

  static String ohneGewicht(int n) => english
      ? (n == 1 ? '1 item without weight' : '$n items without weight')
      : (n == 1 ? '1 Gegenstand ohne Gewicht' : '$n Gegenstände ohne Gewicht');

  // Gegenstand bearbeiten
  static String get gegenstandBearbeiten =>
      _t('Gegenstand bearbeiten', 'Edit item');
  static String get gegenstandNeu => _t('Gegenstand hinzufügen', 'Add item');
  static String get feldName => _t('Name', 'Name');
  static String get feldMenge => _t('Menge', 'Quantity');
  static String get feldGewicht =>
      _t('Gewicht je Stück in Gramm', 'Weight per piece in grams');
  static String get feldGewichtHinweis =>
      _t('Leer lassen, wenn unbekannt', 'Leave empty if unknown');
  static String get feldTyp => _t('Typ', 'Type');
  static String get feldKategorie => _t('Kategorie', 'Category');
  static String get feldNotiz => _t('Notiz', 'Note');
  static String get fehlerName =>
      _t('Bitte einen Namen eingeben', 'Please enter a name');
  static String get fehlerMenge =>
      _t('Bitte eine Zahl ab 1 eingeben', 'Please enter a number of 1 or more');
  static String get fehlerGewicht =>
      _t('Bitte eine ganze Zahl eingeben', 'Please enter a whole number');

  static String gewichtTyp(WeightType t) => switch (t) {
    WeightType.base => _t('Basis', 'Base'),
    WeightType.consumable => _t('Verbrauch', 'Consumable'),
    WeightType.worn => _t('Getragen', 'Worn'),
  };
}
