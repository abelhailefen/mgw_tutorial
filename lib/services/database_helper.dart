// lib/services/database_helper.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DownloadedVideo {
  final String videoId;
  final String title;
  final String filePath;
  final bool isVideoOnly;
  final DateTime downloadedAt;

  DownloadedVideo({
    required this.videoId,
    required this.title,
    required this.filePath,
    required this.isVideoOnly,
    required this.downloadedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'videoId': videoId,
      'title': title,
      'filePath': filePath,
      'isVideoOnly': isVideoOnly ? 1 : 0,
      'downloadedAt': downloadedAt.toIso8601String(),
    };
  }

  factory DownloadedVideo.fromMap(Map<String, dynamic> map) {
    return DownloadedVideo(
      videoId: map['videoId'] as String,
      title: map['title'] as String,
      filePath: map['filePath'] as String,
      isVideoOnly: (map['isVideoOnly'] as int) == 1,
      downloadedAt: DateTime.parse(map['downloadedAt'] as String),
    );
  }
}

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'app_downloads.db');

    return await openDatabase(
      path,
      version: 1, // Increment version if you change schema
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE downloaded_videos (
            videoId TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            filePath TEXT NOT NULL UNIQUE,
            isVideoOnly INTEGER NOT NULL DEFAULT 0,
            downloadedAt TEXT NOT NULL
          )
        ''');
      },
      // onUpgrade: (db, oldVersion, newVersion) async {
      //   if (oldVersion < 2) {
      //     // await db.execute("ALTER TABLE downloaded_videos ADD COLUMN new_column TEXT;");
      //   }
      // },
    );
  }

  // === Video Download Operations ===
  Future<void> insertOrUpdateDownloadedVideo(DownloadedVideo video) async {
    final db = await database;
    await db.insert(
      'downloaded_videos',
      video.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace, // Replaces if videoId already exists
    );
    print('DB: Inserted/Updated video: ${video.videoId}');
  }

  Future<DownloadedVideo?> getDownloadedVideo(String videoId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'downloaded_videos',
      where: 'videoId = ?',
      whereArgs: [videoId],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return DownloadedVideo.fromMap(maps.first);
    }
    return null;
  }

  Future<List<DownloadedVideo>> getAllDownloadedVideos() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('downloaded_videos', orderBy: 'downloadedAt DESC');
    return List.generate(maps.length, (i) {
      return DownloadedVideo.fromMap(maps[i]);
    });
  }

  Future<int> deleteDownloadedVideo(String videoId) async {
    final db = await database;
    final count = await db.delete(
      'downloaded_videos',
      where: 'videoId = ?',
      whereArgs: [videoId],
    );
    print('DB: Deleted video: $videoId, count: $count');
    return count;
  }

  Future<bool> isVideoDownloadedInDb(String videoId) async {
    final video = await getDownloadedVideo(videoId);
    return video != null;
  }
}