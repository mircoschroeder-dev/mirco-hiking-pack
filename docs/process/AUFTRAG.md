# AUFTRAG.md — Mirco Wanderrucksack V0

**An Claude Code.** Arbeite diesen Auftrag von oben nach unten ab.

Lies **zuerst** `FORTSCHRITT.md` im selben Ordner. Existiert sie nicht, lege sie nach der
Vorlage in Abschnitt 8 an. Existiert sie, mache dort weiter, wo das letzte Häkchen fehlt,
und baue nichts neu, was schon abgenommen ist.

---

## 0. Rahmen

Gebaut wird eine Android-App, die aus Tourtyp, Dauer, Jahreszeit und Zusatzoptionen eine
Wander-Packliste mit Gewichtsübersicht erzeugt. Nutzer ist allein Mirco selbst, auf seinem
eigenen Handy. **Keine Veröffentlichung, kein Play Store, kein Nutzerkonto, kein Server,
keine Werbung, keine Affiliate-Links, keine Analytics, keine Netzwerkberechtigung.**

Mirco arbeitet unregelmäßig an dem Projekt und ist kein Entwickler von Beruf. Daraus folgt
für dich:

- **Entscheide selbst und frage nicht nach**, wo diese Datei eine Vorgabe macht oder wo es
  eine offensichtlich übliche Lösung gibt. Halte die Entscheidung in `FORTSCHRITT.md` fest.
- Frage nur, wenn eine Entscheidung ihn wirklich betrifft — etwa wenn eine Installation
  Geld kostet, Administratorrechte braucht oder etwas auf seinem Rechner verändert, das
  nichts mit diesem Projekt zu tun hat.
- Erkläre am Ende jedes Arbeitspakets in drei bis vier Sätzen in normalem Deutsch, was
  jetzt funktioniert und was er selbst prüfen soll. Keine Code-Vorträge.
- Hinterlasse nach **jedem** Arbeitspaket einen lauffähigen Zustand. Niemals ein halb
  umgebautes Projekt zurücklassen, nur weil ein Paket noch nicht fertig ist.

---

## 1. Arbeitspaket 0 — Umgebung prüfen und herrichten

Mirco weiß nicht, was auf seinem Rechner installiert ist. Finde es heraus, statt zu raten.

1. Prüfe, ob Flutter vorhanden und benutzbar ist (`flutter --version`, dann
   `flutter doctor -v`).
2. Prüfe, ob ein Android-Build möglich ist: Android SDK, Plattform-Tools, ein JDK und
   akzeptierte Android-Lizenzen. `flutter doctor` sagt dir, was fehlt.
3. Fehlt etwas: **ermittle den aktuell offiziellen Installationsweg von
   `docs.flutter.dev`** und folge dem. Verlasse dich nicht auf einen Befehl aus deinem
   Gedächtnis — Paketnamen und Installationswege ändern sich. Wenn ein Paketmanager wie
   winget, Chocolatey oder Scoop auf dem Rechner vorhanden ist, nutze ihn; sonst den
   offiziellen Download.
4. Für APK-Builds ist der einfachste verlässliche Weg eine Android-Studio-Installation,
   weil sie SDK und JDK mitbringt. Wenn ohnehin etwas fehlt, nimm diesen Weg, statt die
   Einzelteile zusammenzusuchen.
5. Am Ende müssen `flutter doctor` für die Android-Toolchain einen Haken zeigen und
   `flutter config --list` Android-Builds aktiviert haben.

**Abnahme:** `flutter doctor` meldet keine Fehler mehr für Android. Schreibe in
`FORTSCHRITT.md`, was vorhanden war und was du installiert hast.

Falls eine Installation an fehlenden Rechten scheitert: brich nicht ab, sondern schreibe
Mirco in zwei Sätzen, welchen einen Schritt er selbst ausführen muss.

---

## 2. Arbeitspaket 1 — Projekt und Logik-Package

### Projekt anlegen

Flutter-Projekt im aktuellen Ordner, Paketname `de.mircoschroeder.wanderrucksack`,
`minSdkVersion 24`. Nur die Android-Plattform, kein iOS, kein Web, kein Desktop.

### Struktur

```
packages/
  packliste_core/          <- reines Dart, KEIN Flutter-Import
    pubspec.yaml
    lib/
      models.dart          Item, Rule, TripConfig, TripItem, WeightSummary, Enums
      item_repository.dart laedt und parst items.json
      quantity.dart         Mengen-Ausdruecke auswerten
      generator.dart        generateList(TripConfig) -> List<TripItem>
      weights.dart          Summen je Gewichtstyp
    assets/
      items.json
    test/
      generator_test.dart
      weights_test.dart
      quantity_test.dart
lib/                       <- Flutter-App, haengt packliste_core per path-Dependency ein
```

**Diese Trennung ist die wichtigste Vorgabe des Auftrags.** Mirco baut parallel eine
Wanderapp und will die Packliste später möglicherweise dorthin umziehen. Deshalb:

- In `packages/packliste_core/` steht **kein** `import 'package:flutter/...'`. Wer Flutter
  braucht, gehört in die App.
- Die App enthält **keine** Packlisten-Logik, sondern ruft nur das Package auf.
- Der Umzug soll später ein Kopieren des Ordners sein, kein Neuschreiben.

### Die Seed-Daten

`items.json` liegt fertig vor, mit 74 Gegenständen, Standardgewichten und Aufnahmeregeln.
Die Datei liegt neben diesem Auftrag; falls nicht, hier:

```
C:\Users\mirco\Documents\Claude\40-Quellen\packlisten-app-items.json
```

Kopiere sie nach `packages/packliste_core/assets/items.json`. **Inhalt nicht verändern und
nichts dazuerfinden** — die Referenzwerte der Tests beziehen sich genau auf diesen Stand.

Felder je Gegenstand: `id`, `name`, `category`, `defaultWeightG`, `weightType`
(`base` | `consumable` | `worn`), optional `perDay`, `perDayFactorG`, `essential`,
`searchQuery`, und ein `rule`-Block mit `tourTypes`, `tempBands`, optional
`requiresOptions`, `minDays`, `maxDays`, `quantity`.

`searchQuery` wird in V0 nicht benutzt — einlesen, aber nicht anzeigen.

### Mengen-Ausdrücke

`quantity` ist ein kleiner Ausdruck mit der Variablen `days`. Vorkommende Formen:

```
1   2   3   days   days + 1   days*2
ceil(days/2)   ceil(days/3)   ceil(days/4)
min(days, 4)   min(ceil(days/2), 3)   ceil(days/2) + 1
```

Schreibe dafür einen kleinen eigenen Auswerter für genau diese Formen. **Keine
Expression-Library als Abhängigkeit.** Ein unbekannter Ausdruck wirft beim Laden eine
Exception — niemals stillschweigend 1 annehmen.

### Generator

```
Eingabe: tourType, days, tempBand, options[]

1. Alle Regeln laden
2. Regel trifft zu, wenn ALLE gelten:
   - tourType in rule.tourTypes
   - tempBand in rule.tempBands
   - days innerhalb [minDays, maxDays], soweit gesetzt
   - alle rule.requiresOptions sind in options enthalten
3. Menge aus quantity berechnen
4. Gewicht: eigener Wert des Nutzers ?? defaultWeightG ?? 0
5. Duplikate zusammenfassen, hoechste Menge gewinnt
6. Nach Kategorie gruppieren; je Kategorie essential zuerst, dann alphabetisch
7. Summen je weightType bilden
```

Kategorien in dieser Anzeigereihenfolge, wie in `items.json` vorgegeben:
Rucksack & Tragesystem, Kleidung, Regen & Wetterschutz, Schlafen, Küche & Verpflegung,
Wasser, Navigation, Sicherheit & Erste Hilfe, Hygiene, Elektronik, Foto & Video,
Dokumente & Geld, Sonstiges.

### Gewichte

| Typ | Bedeutung | Zählt zu |
|---|---|---|
| `base` | bleibt die ganze Tour im Rucksack | Basisgewicht |
| `consumable` | wird unterwegs verbraucht | Verbrauch |
| `worn` | wird am Körper getragen | getragen, **nicht** im Rucksack |

Angezeigt werden: Basisgewicht, Verbrauch, **Rucksack beim Start** (Basis + Verbrauch) und
getragen. Gegenstände ohne Gewicht zählen mit 0 g, werden aber als „x Gegenstände ohne
Gewicht" ausgewiesen — eine ehrliche Zahl ist wichtiger als eine schöne.

### Abnahme Arbeitspaket 1

`dart test` in `packages/packliste_core/` läuft grün und reproduziert diese vier Fälle mit
den Standardgewichten **exakt**:

| Fall | Positionen | Basis | Verbrauch | Rucksack beim Start |
|---|---|---|---|---|
| `day`, 1 Tag, `warm`, keine Optionen | 30 | 2,6 kg | 2,5 kg | 5,1 kg |
| `hut`, 3 Tage, `mild`, keine Optionen | 43 | 5,6 kg | 3,8 kg | 9,4 kg |
| `tent`, 5 Tage, `cold`, `rain`+`cooking` | 52 | 11,3 kg | 5,3 kg | 16,6 kg |
| `tent`, 21 Tage, `frost`, alle Optionen | 59 | 16,1 kg | 16,7 kg | 32,8 kg |

Dazu diese Tests:

- Tagestour enthält kein Zelt, keinen Schlafsack, keinen Kocher
- Hüttentour enthält kein Zelt, aber einen Hüttenschlafsack
- Option `photo` verändert genau die sechs Gegenstände des Foto-Blocks und nichts sonst
- `days = 1` und `days = 21` liefern beide gültige Listen, keine Division durch null
- Jeder Mengen-Ausdruck aus der Liste oben hat einen eigenen Test

**Weichen die Zahlen ab, ist der Code falsch, nicht die Tabelle.** Passe niemals die
Erwartungswerte an, um Tests grün zu bekommen. Findest du einen begründeten Fehler in der
Tabelle selbst, halte ihn in `FORTSCHRITT.md` fest und sag es Mirco, statt es still zu
ändern.

---

## 3. Arbeitspaket 2 — Oberfläche

Material 3, helles **und** dunkles Theme, gedeckte Naturfarben mit Waldgrün als Akzent.
State Management: Riverpod. Deutsche Texte in **einer** Konstantendatei sammeln, nicht über
den Code verstreut — keine ARB-Lokalisierung in V0.

Die App wird draußen mit kalten Fingern bedient: große Touch-Ziele, mindestens 16 sp
Schrift im Listenbereich, keine Animationsspielereien.

**Screen 1 — Meine Touren.** Liste gespeicherter Touren, großer Button „Neue Packliste".
Beim ersten Start ein freundlicher leerer Zustand.

**Screen 2 — Generator**, vier Schritte mit Fortschrittspunkten:

1. Tourtyp: Tageswanderung (`day`) · Mehrtagestour mit Unterkunft (`hut`) · Trekking mit Zelt (`tent`)
2. Dauer in Tagen 1–21; bei `day` fest 1 und übersprungen
3. Temperaturband: Warm über 18 °C · Mild 8–18 °C · Kalt 0–8 °C · Frost unter 0 °C
4. Optionen, mehrfach wählbar: Regen erwartet (`rain`) · Foto-/Videoausrüstung (`photo`) ·
   Selbstverpflegung/Kochen (`cooking`) · Hund dabei (`dog`) · Übernachtung ohne Strom (`nopower`)

**Screen 3 — Packliste.** Kopf mit Gewichtsübersicht und Fortschritt („18 von 34
gepackt"), darunter die Kategorien mit abhakbaren Zeilen. Alles abhaken und alles
zurücksetzen als Aktion im Menü.

**Abnahme:** Von der Startseite bis zur fertigen Liste durchklickbar, und die angezeigten
Gewichte stimmen mit den Werten aus Arbeitspaket 1 überein.

---

## 4. Arbeitspaket 3 — Bearbeiten und Speichern

**Persistenz bewusst einfach:** kein Drift, kein SQLite, kein `build_runner`. Gespeicherte
Touren und eigene Gewichte landen als JSON-Datei im App-Dokumentenverzeichnis
(`path_provider` plus `dart:io`). Nur ein Repository kennt die Speicherung, damit ein
späterer Wechsel auf eine Datenbank eine isolierte Änderung bleibt.

Schreibe atomar: erst in eine temporäre Datei, dann umbenennen. Eine abgebrochene
Speicherung darf keine kaputte Datei hinterlassen. Ist die Datei beschädigt oder nicht
lesbar, startet die App mit leerem Stand und einer verständlichen Meldung — kein Absturz.

Funktionen:

- Gegenstand bearbeiten: Name, Menge, Gewicht, Typ, Notiz (Bottom Sheet)
- Gegenstand hinzufügen und löschen
- Eigenes Gewicht setzen; es wird gemerkt und bei der nächsten erzeugten Liste übernommen
- Tour speichern unter eigenem Namen, laden, duplizieren, löschen mit Undo

**Abnahme:** Eine gespeicherte Tour und ein selbst gesetztes Gewicht überleben das
vollständige Beenden und Neustarten der App.

---

## 5. Arbeitspaket 4 — APK bauen

Mirco will die App als Datei aufs Handy kopieren, nicht per Kabel aufspielen.

```
flutter build apk --release
```

Ergebnis: `build/app/outputs/flutter-apk/app-release.apk`. Kopiere die Datei zusätzlich
als `Wanderrucksack-v0-<JJJJ-MM-TT>.apk` in den Projektordner, damit sie leicht zu finden
ist.

Flutter signiert Release-Builds ohne eigene Konfiguration mit einem Debug-Schlüssel. Für
eine private App ist das in Ordnung — richte **keinen** eigenen Keystore ein, das wird erst
bei einer Veröffentlichung nötig.

Schreibe Mirco dazu in einfachen Worten:

- wo die Datei liegt
- dass er sie per USB-Kabel, Cloud-Ordner oder Messenger aufs Handy bringt
- dass er beim Installieren einmalig erlauben muss, dass die Datei-App Apps installieren
  darf (Android fragt von selbst danach)
- dass jede neue Version einfach über die alte installiert wird und die gespeicherten
  Touren dabei erhalten bleiben

**Abnahme:** Die APK ist gebaut und Mirco hat die Anleitung in der Hand.

---

## 6. Qualitätsregeln

- Baue nur, was in diesem Auftrag steht. Fällt dir eine gute Zusatzfunktion ein, schreibe
  sie in `IDEEN-V1.md` und baue sie nicht. Scope-Wachstum ist bei diesem Projekt das
  größte Risiko.
- `flutter analyze` ohne Warnungen.
- Die Tests aus Arbeitspaket 1 laufen nach **jedem** weiteren Paket erneut.
- Keine Abhängigkeit aufnehmen, die nur eine Kleinigkeit erledigt. Erlaubt und erwartet:
  `flutter_riverpod`, `path_provider`. Alles Weitere begründen und in `FORTSCHRITT.md`
  notieren.
- Keine Netzwerkberechtigung im Manifest, keine Telemetrie, keine Crash-Reporter.

---

## 7. Erster Start für Mirco

Wenn alles steht, nenn ihm genau eine nächste Handlung: **die App auf einer echten
Wanderung benutzen.** Was dabei stört, ist die Liste für V1 — und die ist mehr wert als
jede Vermutung am Schreibtisch.

---

## 8. Vorlage für FORTSCHRITT.md

Lege diese Datei an und halte sie nach jedem Arbeitspaket aktuell. Sie ist der
Wiedereinstiegspunkt, wenn wochenlang nichts passiert.

```markdown
# Fortschritt — Mirco Wanderrucksack V0

Zuletzt bearbeitet: JJJJ-MM-TT
Naechster Schritt: <ein Satz>

## Arbeitspakete
- [ ] AP0 Umgebung geprueft und hergerichtet
- [ ] AP1 packliste_core mit gruenen Tests
- [ ] AP2 Oberflaeche durchklickbar
- [ ] AP3 Bearbeiten und Speichern
- [ ] AP4 APK gebaut

## Umgebung
<was war vorhanden, was wurde installiert>

## Entscheidungen
<jede selbst getroffene Entscheidung, ein Satz pro Zeile>

## Offene Punkte fuer Mirco
<nur was wirklich ihn braucht>
```
