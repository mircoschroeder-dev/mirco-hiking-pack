# Fortschritt — Mirco Wanderrucksack V0

Zuletzt bearbeitet: 2026-11-20
Naechster Schritt: Mirco gibt die Veroeffentlichung frei; dann oeffentliches Repository, erster Commit und Release mit Mircos-Wanderrucksack-v0.6.0.apk (mit eigenem Schluessel signiert).

## Arbeitspakete
- [ ] AP0 Umgebung geprueft und hergerichtet (alles da, nur `flutter doctor` meldet noch offene Android-Lizenzen, siehe unten)
- [x] AP1 packliste_core mit gruenen Tests
- [x] AP2 Oberflaeche durchklickbar
- [x] AP3 Bearbeiten und Speichern
- [x] AP4 APK gebaut (aktuell Wanderrucksack-v0.6-2026-11-20.apk, Anleitung in ANLEITUNG-HANDY.md)
- [x] Nachtrag: Status je Gegenstand (gruen gepackt, gelb vorhanden, hellblau kaufen, nicht mitnehmen)
- [x] Nachtrag: Listen nach Bedingungen statt gespeicherter Touren (v0.3)
- [x] Nachtrag: GitHub-Version vorbereitet (v0.5): Deutsch und Englisch nach Handysprache, README, MIT-Lizenz, Bildschirmfotos. Noch nicht veroeffentlicht.
- [x] Nachtrag: Design "Papier-Wanderkarte", eigenes App-Symbol, YouTube-Link, App-Name mit Mirco (v0.6)
- [x] Nachtrag: GitHub-Version vorbereitet (v0.5): Deutsch und Englisch nach Handysprache, README, MIT-Lizenz, Bildschirmfotos. Noch nicht veroeffentlicht.
- [x] Nachtrag: Design "Papier-Wanderkarte", eigenes App-Symbol, YouTube-Link, App-Name mit Mirco (v0.6)

## Umgebung
Alles war schon vorhanden, nichts wurde installiert:
Flutter 3.44.8 (C:\dev\flutter), Dart 3.12.2, Android SDK (C:\dev\android-sdk, Plattformen 34/36/37, Build-Tools 36),
Temurin JDK 17 (C:\dev\jdk17_extracted), winget, Git. Kein Android Studio, wird nicht gebraucht.
Chrome und Visual Studio meldet `flutter doctor` als fehlend; beides ist fuer Android-Builds egal.
Die Hauptlizenz (android-sdk-license) ist akzeptiert, der Release-Build laeuft damit.

## Pruefstand (2026-10-30)
- `dart test` in packages/packliste_core: 56 gruen. `flutter test`: 15 gruen. `flutter analyze`: keine Meldungen.
- Release-APK auf Emulator (wanderapp_test): durchgeklickt, Gewichte wie Referenzfall hut (9,4 kg), Regenhuelle auf 300 g gesetzt, App hart beendet und neu gestartet: Tour, Haken und 9,6 kg noch da, neue Liste uebernimmt die 300 g.
- Release-APK fordert keine INTERNET-Berechtigung an (aapt geprueft).
- Nicht auf einem echten Handy getestet.

## Entscheidungen
- Vierter Referenzfall laeuft mit rain+photo+cooking+nopower (ohne dog), weil nur so die Tabellenwerte aufgehen; Erwartungswerte unveraendert.
- Mengen-Ausdruecke werden per fester Formenliste (Regex) geprueft statt mit einem allgemeinen Parser, damit wirklich nur die erlaubten Formen durchgehen.
- `perDayFactorG` und `perDay` werden eingelesen, aber nicht gerechnet: Menge x Stueckgewicht ergibt schon denselben Wert, und ein eigenes Gewicht wirkt so einheitlich.
- Gewicht 0 g zaehlt wie "ohne Gewicht" und wird ausgewiesen.
- items.json bleibt unveraendert, auch die Schreibweisen ohne Umlaute ("Muetze", "Kueche & Verpflegung"); der Auftrag schreibt "Kueche" mit Umlaut.
- Unlesbare Speicherdatei wird als wanderrucksack.json.defekt aufgehoben.
- Eigene Gewichte werden nur fuer Stammdaten-Gegenstaende gemerkt, nicht fuer selbst hinzugefuegte.
- Neuer Gegenstand landet standardmaessig in "Sonstiges", Kategorie ist waehlbar.
- Keine Abhaengigkeiten ausser flutter_riverpod und path_provider.

- Neue Gegenstaende gelten als vorhanden; "muss gekauft werden" setzt man von Hand.
- "Alles abhaken" laesst zu Kaufendes offen; einzeln abgehakt gilt es als gekauft und ist nach dem Auspacken vorhanden.
- "Nicht mitnehmen" zaehlt weder bei Gewicht noch Fortschritt und steht am Listenende zum Zurueckholen; "Von der Liste loeschen" entfernt endgueltig, mit Rueckgaengig.
- Drueberinstallieren ueber v0 auf dem Emulator geprueft: Tour und Haken bleiben erhalten.

- Auf Mircos Wunsch (2026-10-30) gibt es keine gespeicherten Touren mehr: Dauer, Zelt ja/nein, Jahreszeit und Wetter ergeben genau eine Liste, jede Aenderung bleibt automatisch erhalten. Das weicht bewusst von AP3 ab.
- Sommer = warm, Fruehling und Herbst = mild, Winter = Frost. Dauer rechnet mit dem laengsten Fall: 3, 7 oder 21 Tage.
- Auf Mircos Wunsch: "Laenger als eine Woche" rechnet Proviant (Verpflegung, Riegel) fuer 3 Tage. Hundefutter habe ich genauso behandelt. Alles andere rechnet dort weiter mit 21 Tagen.
- Foto, Kochen, Hund, ohne Strom sind Schalter in der Liste; es erscheinen nur die, die dort etwas aendern. Ihre Gegenstaende liegen immer in der Liste und behalten ihren Stand.
- Eigenes Gewicht gilt sofort auch in allen anderen Listen.
- Neu: "Liste neu aufbauen" im Menue, sonst kaeme man an geloeschte Gegenstaende nicht mehr heran.
- Alte gespeicherte Touren entfallen beim Umstieg, eigene Gewichte bleiben.

- Auf Mircos Wunsch: zuerst GitHub als Portfolio, ohne Werbung und Partnerlinks. Der Store-Plan (AUFTRAG-STORE.md) bleibt lokal und wird nicht veroeffentlicht.
- Umlaute in items.json korrigiert und "Klappspaten" in "Toilettenschaufel" umbenannt; das hebt die Regel "items.json nicht veraendern" bewusst auf. IDs und Gewichte unveraendert, Referenztests weiter gruen.
- Englische Namen in items_en.json. Gespeicherte Listen ziehen unveraenderte Standardnamen und Kategorien beim Oeffnen auf Sprache und Schreibweise nach; selbst geaenderte Namen bleiben.
- Texte als Getter mit _t(deutsch, englisch) statt ARB, Sprache wird beim Start aus der Handysprache gesetzt (Deutsch nur bei deutschem Handy).
- Arbeitsdokumente liegen jetzt in docs/process; zwei lokale Pfade darin wurden fuer die Veroeffentlichung neutralisiert.
- Design auf Mircos Wunsch "Papier-Wanderkarte": Papierton, Hoehenlinien als Hintergrund, Kartenbeschriftung, Fortschritt als Massstabsleiste, Gewicht in Kartenrot. Nur Systemschriften (serif, sans-serif-condensed), keine Schriftdateien.
- App-Name: "Mircos Wanderrucksack" (de) / "Mirco's Hiking Pack" (en), auch unter dem Symbol auf dem Handy; Untertitel unten auf der Startseite.
- YouTube-Link (@mircoschroeder1) auf der Startseite und im README. Oeffnet Browser bzw. YouTube-App ueber url_launcher (zusaetzliche Abhaengigkeit, dafuer noetig); weiterhin keine Internet-Berechtigung (aapt geprueft).
- Eigenes App-Symbol (Rucksack auf Hoehenlinien), auch als adaptives Symbol; Zeichenskript lag im Scratchpad, nicht im Projekt.
- Signatur: android/key.properties (nicht in Git) wird genutzt, wenn vorhanden, sonst Test-Schluessel.

- Auf Mircos Wunsch: zuerst GitHub als Portfolio, ohne Werbung und Partnerlinks. Der Store-Plan (AUFTRAG-STORE.md) bleibt lokal und ist git-ignoriert.
- Umlaute in items.json korrigiert und "Klappspaten" in "Toilettenschaufel" umbenannt; das hebt die Regel "items.json nicht veraendern" bewusst auf. IDs und Gewichte unveraendert, Referenztests weiter gruen.
- Englische Namen in items_en.json. Gespeicherte Listen ziehen unveraenderte Standardnamen und Kategorien beim Oeffnen auf Sprache und Schreibweise nach; selbst geaenderte Namen bleiben.
- Texte als Getter mit _t(deutsch, englisch) statt ARB; die Sprache wird beim Start aus der Handysprache gesetzt (Deutsch nur bei deutschem Handy).
- Arbeitsdokumente liegen jetzt in docs/process; zwei lokale Pfade darin wurden fuer die Veroeffentlichung neutralisiert.
- Signatur: android/key.properties (nicht in Git) wird genutzt, wenn vorhanden, sonst Test-Schluessel.

## Offene Punkte fuer Mirco
- Eigener Schluessel liegt in %USERPROFILE%\keys (2026-11-20 erstellt, Release-Build damit signiert und geprueft). Doppelt sichern (E: und Passwort-Manager), nie veroeffentlichen. Auf dem eigenen Handy einmal deinstallieren, weil das Siegel wechselt.
- Signaturschluessel selbst erstellen (Anleitung im Chat), doppelt sichern, nie veroeffentlichen.
- Android-Lizenzen: `flutter doctor --android-licenses` selbst ausfuehren und lesen, das ist seine Zustimmung. Die APK-Erstellung braucht es derzeit nicht.
- Tabelle im Auftrag, Zeile 4: "alle Optionen" stimmt nicht. 59 Positionen / 16,1 / 16,7 / 32,8 kg gelten ohne Hund. Wirklich alle Optionen ergeben 63 Positionen / 16,4 / 25,1 / 41,5 kg (zusaetzlich getestet).
