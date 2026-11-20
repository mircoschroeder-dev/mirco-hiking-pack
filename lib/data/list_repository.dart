import 'dart:convert';
import 'dart:io';

import 'pack_list.dart';

class LoadResult {
  const LoadResult(this.data, {this.corrupted = false});

  final AppData data;
  final bool corrupted;
}

/// Die einzige Stelle, die weiss, wie gespeichert wird: eine JSON-Datei im
/// App-Dokumentenverzeichnis.
class ListRepository {
  ListRepository(this._directory);

  static const _fileName = 'wanderrucksack.json';

  final Future<Directory> Function() _directory;
  Future<void> _lastWrite = Future.value();

  Future<LoadResult> load() async {
    final file = File('${(await _directory()).path}/$_fileName');
    if (!await file.exists()) return const LoadResult(AppData());
    try {
      final json = jsonDecode(await file.readAsString());
      return LoadResult(AppData.fromJson(json as Map<String, dynamic>));
    } catch (_) {
      // Unlesbare Datei beiseitelegen, damit das naechste Speichern sie nicht
      // ueberschreibt.
      try {
        await file.rename('${file.path}.defekt');
      } on FileSystemException {
        // Dann eben ohne Sicherung; die App muss trotzdem starten.
      }
      return const LoadResult(AppData(), corrupted: true);
    }
  }

  /// Schreibt atomar: erst in eine temporaere Datei, dann umbenennen.
  /// Aufrufe laufen nacheinander, nie gleichzeitig.
  Future<void> save(AppData data) {
    final write = _lastWrite.catchError((_) {}).then((_) => _write(data));
    _lastWrite = write;
    return write;
  }

  Future<void> _write(AppData data) async {
    final path = '${(await _directory()).path}/$_fileName';
    final temp = File('$path.tmp');
    await temp.writeAsString(jsonEncode(data.toJson()), flush: true);
    await temp.rename(path);
  }
}
