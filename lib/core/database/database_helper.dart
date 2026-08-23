import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static DatabaseHelper get instance => _instance;
  
  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'synap.db');
    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: _onConfigure,
    );
  }

  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE decks (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        created_at TEXT,
        updated_at TEXT,
        card_count INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE cards (
        id TEXT PRIMARY KEY,
        deck_id TEXT NOT NULL,
        front_text TEXT NOT NULL,
        back_text TEXT NOT NULL,
        card_type INTEGER DEFAULT 0,
        extra_data TEXT,
        parent_note_id TEXT,
        created_at TEXT,
        updated_at TEXT,
        FOREIGN KEY (deck_id) REFERENCES decks(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE review_logs (
        id TEXT PRIMARY KEY,
        card_id TEXT NOT NULL,
        rating INTEGER,
        review_time_ms INTEGER,
        scheduled_days REAL,
        elapsed_days REAL,
        reviewed_at TEXT,
        FOREIGN KEY (card_id) REFERENCES cards(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE scheduler_state (
        card_id TEXT PRIMARY KEY,
        stability REAL,
        difficulty REAL,
        due_date TEXT,
        last_review TEXT,
        reps INTEGER DEFAULT 0,
        lapses INTEGER DEFAULT 0,
        state INTEGER DEFAULT 0,
        FOREIGN KEY (card_id) REFERENCES cards(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE media_attachments (
        id TEXT PRIMARY KEY,
        card_id TEXT NOT NULL,
        type INTEGER NOT NULL,
        file_name TEXT NOT NULL,
        local_path TEXT NOT NULL,
        size_bytes INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        FOREIGN KEY (card_id) REFERENCES cards(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE ai_providers (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        provider_type TEXT NOT NULL,
        base_url TEXT,
        api_key TEXT,
        selected_model TEXT,
        is_active INTEGER DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE ai_generation_queue (
        id TEXT PRIMARY KEY,
        deck_id TEXT NOT NULL,
        front_text TEXT NOT NULL,
        back_text TEXT NOT NULL,
        extra_data TEXT,
        source_snippet TEXT,
        status INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        FOREIGN KEY (deck_id) REFERENCES decks(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE chat_messages (
        id TEXT PRIMARY KEY,
        deck_id TEXT,
        role TEXT NOT NULL,
        content TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE cards ADD COLUMN card_type INTEGER DEFAULT 0');
      await db.execute('ALTER TABLE cards ADD COLUMN extra_data TEXT');
      await db.execute('ALTER TABLE cards ADD COLUMN parent_note_id TEXT');

      await db.execute('''
        CREATE TABLE media_attachments (
          id TEXT PRIMARY KEY,
          card_id TEXT NOT NULL,
          type INTEGER NOT NULL,
          file_name TEXT NOT NULL,
          local_path TEXT NOT NULL,
          size_bytes INTEGER DEFAULT 0,
          created_at TEXT NOT NULL,
          FOREIGN KEY (card_id) REFERENCES cards(id) ON DELETE CASCADE
        )
      ''');

      await db.execute('''
        CREATE TABLE ai_providers (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          provider_type TEXT NOT NULL,
          base_url TEXT,
          api_key TEXT,
          selected_model TEXT,
          is_active INTEGER DEFAULT 0,
          created_at TEXT NOT NULL
        )
      ''');

      await db.execute('''
        CREATE TABLE ai_generation_queue (
          id TEXT PRIMARY KEY,
          deck_id TEXT NOT NULL,
          front_text TEXT NOT NULL,
          back_text TEXT NOT NULL,
          extra_data TEXT,
          source_snippet TEXT,
          status INTEGER DEFAULT 0,
          created_at TEXT NOT NULL,
          FOREIGN KEY (deck_id) REFERENCES decks(id) ON DELETE CASCADE
        )
      ''');

      await db.execute('''
        CREATE TABLE chat_messages (
          id TEXT PRIMARY KEY,
          deck_id TEXT,
          role TEXT NOT NULL,
          content TEXT NOT NULL,
          created_at TEXT NOT NULL
        )
      ''');
    }
  }
}
