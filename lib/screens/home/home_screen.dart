import 'package:flutter/material.dart';
import 'package:mgw_tutorial/widgets/home/course_card.dart';
import 'package:mgw_tutorial/widgets/home/notes_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    
    return Scaffold(
      /* key: _scaffoldKey,
      appBar: AppBar(
        title: const Text('MGW Tutorial'),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
        ),
      ), */
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const CourseCard(
              title: 'Freshman First Semester',
              imageUrl: '',
              subjectsLeft: ['Maths', 'Physics', 'Chemistry', 'Biology'],
              subjectsRight: ['English', 'Civics', ],
              price: '200',
            ),
            const SizedBox(height: 16),
            const CourseCard(
              title: 'Freshman Second Semester',
              imageUrl: '',
              subjectsLeft: ['Maths II', 'Physics II', 'Statistics'],
              subjectsRight: ['Psychology', 'Logic', /* ... */],
              price: '400',
            ),
            const SizedBox(height: 16),
            const NotesCard(
              title: 'Notes',
              description: 'Notes we have collected from students all around the country.',
              imageUrl: '',
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'Join over 4,000 students who are already boosting their grades',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[800],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: ElevatedButton(
                onPressed: () {
                   ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Get Registered Now Tapped (Not Implemented)')),
                  );
                },
                child: const Text('Get Registered Now'),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}