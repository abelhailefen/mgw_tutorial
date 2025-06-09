import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' show join;
import 'package:mgw_tutorial/models/user.dart';
import 'package:mgw_tutorial/models/api_course.dart';
import 'package:mgw_tutorial/models/subject.dart'; // Added import

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'app_database.db');
    return await openDatabase(
      path,
      version: 8,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE courses(
        id INTEGER PRIMARY KEY,
        title TEXT,
        shortDescription TEXT,
        description TEXT,
        outcomes TEXT,
        language TEXT,
        categoryId INTEGER,
        section TEXT,
        requirements TEXT,
        price TEXT,
        discountFlag INTEGER,
        discountedPrice TEXT,
        thumbnail TEXT,
        videoUrl TEXT,
        isTopCourse INTEGER,
        status TEXT,
        isVideoCourse INTEGER,
        isFreeCourse INTEGER,
        multiInstructor INTEGER,
        creator TEXT,
        createdAt TEXT,
        updatedAt TEXT,
        localThumbnailPath TEXT,
        courseCategoryId INTEGER,
        courseCategoryName TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE sections(
        id INTEGER PRIMARY KEY,
        courseId INTEGER,
        title TEXT,
        'order' INTEGER,
        createdAt TEXT,
        updatedAt TEXT,
        FOREIGN KEY (courseId) REFERENCES courses(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE lessons(
        id INTEGER PRIMARY KEY,
        sectionId INTEGER,
        title TEXT,
        summary TEXT,
        'order' INTEGER,
        videoProvider TEXT,
        videoUrl TEXT,
        attachmentUrl TEXT,
        attachmentTypeString TEXT,
        lessonTypeString TEXT,
        duration TEXT,
        createdAt TEXT,
        updatedAt TEXT,
        FOREIGN KEY (sectionId) REFERENCES sections(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE logged_in_user(
        id INTEGER PRIMARY KEY,
        user_id INTEGER UNIQUE,
        first_name TEXT,
        last_name TEXT,
        phone TEXT UNIQUE,
        login_timestamp TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE subjects(
        id INTEGER PRIMARY KEY,
        name TEXT,
        category TEXT,
        year TEXT,
        imageUrl TEXT,
        localImagePath TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE chapters(
        id INTEGER PRIMARY KEY,
        name TEXT,
        description TEXT,
        status TEXT,
        subjectId INTEGER,
        'order' INTEGER,
        FOREIGN KEY (subjectId) REFERENCES subjects(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE exams(
        id INTEGER PRIMARY KEY,
        title TEXT,
        description TEXT,
        chapterId INTEGER,
        totalQuestions INTEGER,
        timeLimit INTEGER,
        status TEXT,
        isAnswerBefore INTEGER,
        passingScore INTEGER,
        examType TEXT,
        examYear TEXT,
        maxAttempts INTEGER,
        shuffleQuestions INTEGER,
        showResultsImmediately INTEGER,
        startDate TEXT,
        endDate TEXT,
        instructions TEXT,
        FOREIGN KEY (chapterId) REFERENCES chapters(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE questions (
        id INTEGER PRIMARY KEY,
        question TEXT,
        answer TEXT,
        time TEXT,
        passage TEXT,
        image TEXT,
        A TEXT,
        B TEXT,
        C TEXT,
        D TEXT,
        explanation TEXT,
        subjectId INTEGER,
        chapterId INTEGER,
        examId INTEGER,
        expImage TEXT,
        expVideo TEXT,
        examType TEXT,
        examYear TEXT,
        FOREIGN KEY (subjectId) REFERENCES subjects (id) ON DELETE CASCADE,
        FOREIGN KEY (chapterId) REFERENCES chapters (id) ON DELETE CASCADE,
        FOREIGN KEY (examId) REFERENCES exams (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('CREATE INDEX idx_sections_courseId ON sections(courseId)');
    await db.execute('CREATE INDEX idx_lessons_sectionId ON lessons(sectionId)');
    await db.execute('CREATE INDEX idx_chapters_subjectId ON chapters(subjectId)');
    await db.execute('CREATE INDEX idx_exams_chapterId ON exams(chapterId)');
    await db.execute('CREATE INDEX idx_questions_examId ON questions (examId)');
    await db.execute('CREATE INDEX idx_questions_chapterId ON questions (chapterId)');
    await db.execute('CREATE INDEX idx_questions_subjectId ON questions (subjectId)');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    print("Database upgrade started: oldVersion=$oldVersion, newVersion=$newVersion");

    if (oldVersion < 2) {
      print("Upgrading from < 2 to $newVersion.");
    }
    if (oldVersion < 3) {
      print("Upgrading from < 3 to $newVersion. Dropping and recreating logged_in_user table.");
      var tableExists = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table' AND name='logged_in_user'");
      if (tableExists.isNotEmpty) {
        await db.execute('DROP TABLE logged_in_user');
      }
      await db.execute('''
        CREATE TABLE logged_in_user(
          id INTEGER PRIMARY KEY,
          user_id INTEGER UNIQUE,
          first_name TEXT,
          last_name TEXT,
          phone TEXT UNIQUE,
          login_timestamp TEXT
        )
      ''');
      print("logged_in_user table recreated.");
    }
    if (oldVersion < 4) {
      print("Upgrading from < 4 to $newVersion. Adding localThumbnailPath to courses.");
      await db.execute('ALTER TABLE courses ADD COLUMN localThumbnailPath TEXT');
      print("localThumbnailPath column added to courses.");
    }
    if (oldVersion < 5) {
      print("Upgrading from < 5 to $newVersion. Adding category columns to courses.");
      var columnExists = await db.rawQuery("PRAGMA table_info(courses)");
      bool hasCategoryId = false;
      bool hasCategoryName = false;
      for (var column in columnExists) {
        if (column['name'] == 'courseCategoryId') hasCategoryId = true;
        if (column['name'] == 'courseCategoryName') hasCategoryName = true;
      }
      if (!hasCategoryId) {
        await db.execute('ALTER TABLE courses ADD COLUMN courseCategoryId INTEGER');
        print("courseCategoryId column added to courses.");
      }
      if (!hasCategoryName) {
        await db.execute('ALTER TABLE courses ADD COLUMN courseCategoryName TEXT');
        print("courseCategoryName column added to courses.");
      }
    }
    if (oldVersion < 6) {
      print("Upgrading from < 6 to $newVersion. Adding subjects, chapters, and exams tables.");
      await db.execute('''
        CREATE TABLE subjects(
          id INTEGER PRIMARY KEY,
          name TEXT,
          category TEXT,
          year TEXT,
          imageUrl TEXT
        )
      ''');
      await db.execute('''
        CREATE TABLE chapters(
          id INTEGER PRIMARY KEY,
          name TEXT,
          description TEXT,
          status TEXT,
          subjectId INTEGER,
          'order' INTEGER,
          FOREIGN KEY (subjectId) REFERENCES subjects(id) ON DELETE CASCADE
        )
      ''');
      await db.execute('''
        CREATE TABLE exams(
          id INTEGER PRIMARY KEY,
          title TEXT,
          description TEXT,
          chapterId INTEGER,
          totalQuestions INTEGER,
          timeLimit INTEGER,
          status TEXT,
          isAnswerBefore INTEGER,
          passingScore INTEGER,
          examType TEXT,
          examYear TEXT,
          maxAttempts INTEGER,
          shuffleQuestions INTEGER,
          showResultsImmediately INTEGER,
          startDate TEXT,
          endDate TEXT,
          instructions TEXT,
          FOREIGN KEY (chapterId) REFERENCES chapters(id) ON DELETE CASCADE
        )
      ''');
      await db.execute('CREATE INDEX idx_chapters_subjectId ON chapters(subjectId)');
      await db.execute('CREATE INDEX idx_exams_chapterId ON exams(chapterId)');
      print("Subjects, chapters, and exams tables created.");
    }
    if (oldVersion < 7) {
      print("Upgrading from < 7 to $newVersion. Adding questions table.");
      await db.execute('''
        CREATE TABLE questions (
          id INTEGER PRIMARY KEY,
          question TEXT,
          answer TEXT,
          time TEXT,
          passage TEXT,
          image TEXT,
          A TEXT,
          B TEXT,
          C TEXT,
          D TEXT,
          explanation TEXT,
          subjectId INTEGER,
          chapterId INTEGER,
          examId INTEGER,
          expImage TEXT,
          expVideo TEXT,
          examType TEXT,
          examYear TEXT,
          FOREIGN KEY (subjectId) REFERENCES subjects (id) ON DELETE CASCADE,
          FOREIGN KEY (chapterId) REFERENCES chapters (id) ON DELETE CASCADE,
          FOREIGN KEY (examId) REFERENCES exams (id) ON DELETE CASCADE
        )
      ''');
      await db.execute('CREATE INDEX idx_questions_examId ON questions (examId)');
      await db.execute('CREATE INDEX idx_questions_chapterId ON questions (chapterId)');
      await db.execute('CREATE INDEX idx_questions_subjectId ON questions (subjectId)');
      print("Questions table created and indexes added.");
    }
    if (oldVersion < 8) {
      print("Upgrading from < 8 to $newVersion. Adding localImagePath to subjects.");
      await db.execute('ALTER TABLE subjects ADD COLUMN localImagePath TEXT');
      print("localImagePath column added to subjects.");
    }

    print("Database upgrade finished: newVersion=$newVersion.");
  }

  Future<int> upsert(String table, Map<String, dynamic> data) async {
    if (data.isEmpty) {
      throw Exception('Data map cannot be empty');
    }
    final db = await database;
    try {
      final id = await db.insert(
        table,
        data,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return id;
    } catch (e) {
      print("DatabaseHelper Error upserting into $table: $e");
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> query(String table, {String? where, List<dynamic>? whereArgs, String? orderBy, int? limit}) async {
    final db = await database;
    try {
      final result = await db.query(
        table,
        where: where,
        whereArgs: whereArgs,
        orderBy: orderBy,
        limit: limit,
      );
      return result;
    } catch (e) {
      print("DatabaseHelper Error querying $table: $e");
      rethrow;
    }
  }

  Future<int> delete(String table, {String? where, List<dynamic>? whereArgs}) async {
    final db = await database;
    try {
      final count = await db.delete(
        table,
        where: where,
        whereArgs: whereArgs,
      );
      return count;
    } catch (e) {
      print("DatabaseHelper Error deleting from $table: $e");
      rethrow;
    }
  }

  Future<List<String>> getOldThumbnailPathsInTxn(Transaction txn) async {
    try {
      final List<Map<String, dynamic>> results = await txn.query(
        'courses',
        columns: ['localThumbnailPath'],
      );
      final List<String> paths = results
          .map((row) => row['localThumbnailPath'] as String?)
          .where((path) => path != null && path.isNotEmpty)
          .cast<String>()
          .toList();
      return paths;
    } catch (e) {
      print("DatabaseHelper: Error retrieving thumbnail paths in transaction: $e");
      return [];
    }
  }

  Future<List<String>> getOldSubjectImagePathsInTxn(Transaction txn) async {
    try {
      final List<Map<String, dynamic>> results = await txn.query(
        'subjects',
        columns: ['localImagePath'],
      );
      final List<String> paths = results
          .map((row) => row['localImagePath'] as String?)
          .where((path) => path != null && path.isNotEmpty)
          .cast<String>()
          .toList();
      return paths;
    } catch (e) {
      print("DatabaseHelper: Error retrieving subject image paths in transaction: $e");
      return [];
    }
  }

  Future<List<String>> deleteCoursesInTxn(Transaction txn) async {
    final paths = await getOldThumbnailPathsInTxn(txn);
    await txn.delete('courses');
    print("DatabaseHelper: All courses deleted from DB transactionally.");
    return paths;
  }

  Future<List<String>> deleteSubjectsInTxn(Transaction txn) async {
    final paths = await getOldSubjectImagePathsInTxn(txn);
    await txn.delete('subjects');
    print("DatabaseHelper: All subjects deleted from DB transactionally.");
    return paths;
  }

  Future<void> insertCoursesInTxn(Transaction txn, List<ApiCourse> courses) async {
    if (courses.isEmpty) {
      print("DatabaseHelper: No courses to insert in transaction.");
      return;
    }
    print("DatabaseHelper: Inserting ${courses.length} courses into DB transactionally...");
    for (final course in courses) {
      await txn.insert('courses', course.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    }
    print("DatabaseHelper: New courses inserted into DB successfully transactionally.");
  }

  Future<void> insertSubjectsInTxn(Transaction txn, List<Subject> subjects) async {
    if (subjects.isEmpty) {
      print("DatabaseHelper: No subjects to insert in transaction.");
      return;
    }
    print("DatabaseHelper: Inserting ${subjects.length} subjects into DB transactionally...");
    for (final subject in subjects) {
      await txn.insert('subjects', subject.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    }
    print("DatabaseHelper: New subjects inserted into DB successfully transactionally.");
  }

  Future<void> deleteThumbnailFiles(List<String> paths) async {
    if (paths.isEmpty) return;
    print("DatabaseHelper: Attempting to delete ${paths.length} image files.");
    List<String> errors = [];
    for (final path in paths) {
      try {
        final file = File(path);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        errors.add("Failed to delete $path: $e");
      }
    }
    if (errors.isNotEmpty) {
      print("DatabaseHelper: Errors during image deletion: ${errors.join(', ')}");
    }
  }

  Future<void> deleteSectionsForCourse(int courseId) async {
    await delete('sections', where: 'courseId = ?', whereArgs: [courseId]);
  }

  Future<void> deleteLessonsForSection(int sectionId) async {
    await delete('lessons', where: 'sectionId = ?', whereArgs: [sectionId]);
  }

  Future<void> saveLoggedInUser(User user) async {
    if (user.id == null) {
      print("DatabaseHelper: Cannot save user, user ID is null.");
      return;
    }
    final db = await database;
    try {
      await db.delete('logged_in_user');
      await db.insert(
        'logged_in_user',
        {
          'user_id': user.id,
          'first_name': user.firstName,
          'last_name': user.lastName,
          'phone': user.phone,
          'login_timestamp': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      print("DatabaseHelper: Logged in user saved.");
    } catch (e) {
      print("DatabaseHelper Error saving logged in user: $e");
    }
  }

  Future<Map<String, dynamic>?> getLoggedInUser() async {
    final db = await database;
    try {
      final List<Map<String, dynamic>> results = await db.query(
        'logged_in_user',
        limit: 1,
      );
      if (results.isNotEmpty) {
        print("DatabaseHelper: Logged in user found.");
        return results.first;
      } else {
        print("DatabaseHelper: No logged in user found.");
        return null;
      }
    } catch (e) {
      print("DatabaseHelper Error getting logged in user: $e");
      return null;
    }
  }

  Future<void> deleteLoggedInUser() async {
    final db = await database;
    try {
      await db.delete('logged_in_user');
      print("DatabaseHelper: Logged in user deleted.");
    } catch (e) {
      print("DatabaseHelper Error deleting logged in user: $e");
    }
  }

  Future<Directory> getThumbnailDirectory() async {
    final directory = await getApplicationSupportDirectory();
    final thumbDir = Directory(join(directory.path, 'thumbnails'));
    if (!await thumbDir.exists()) {
      await thumbDir.create(recursive: true);
    }
    return thumbDir;
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
    print("DatabaseHelper: Database closed.");
  }
}