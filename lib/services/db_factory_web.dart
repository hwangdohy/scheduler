import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

/// Web has no native sqflite implementation, so point it at the
/// WASM build of SQLite served from `web/sqlite3.wasm`.
void configureDatabaseFactory() {
  databaseFactory = databaseFactoryFfiWebNoWebWorker;
}
