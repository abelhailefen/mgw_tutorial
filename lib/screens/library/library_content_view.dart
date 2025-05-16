

import 'package:flutter/material.dart';
import 'package:mgw_tutorial/screens/library/subject_chapters_screen.dart';
import 'package:mgw_tutorial/widgets/library/subject_card.dart';

class LibraryContentView extends StatelessWidget {
  const LibraryContentView({super.key});

  static const List<Map<String, String>> subjects = [
    {'title': 'Maths', 'imageUrl': 'https://images.unsplash.com/photo-1509228468518-180dd4864904?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8Mnx8bWF0aHN8ZW58MHx8MHx8fDA%3D&auto=format&fit=crop&w=500&q=60'},
    {'title': 'Physics', 'imageUrl': 'https://images.unsplash.com/photo-1632500649933-22d999318759?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8Mnx8cGh5c2ljc3xlbnwwfHwwfHx8MA%3D%3D&auto=format&fit=crop&w=500&q=60'},
    {'title': 'Chemistry', 'imageUrl': 'https://images.unsplash.com/photo-1564086809780-3958b3732057?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8M3x8Y2hlbWlzdHJ5fGVufDB8fDB8fHww&auto=format&fit=crop&w=500&q=60'},
    {'title': 'Biology', 'imageUrl': 'https://images.unsplash.com/photo-1532187863486-abf9db50d0d6?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8Mnx8YmlvbG9neXxlbnwwfHwwfHx8MA%3D%3D&auto=format&fit=crop&w=500&q=60'},
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16.0,
        mainAxisSpacing: 16.0,
        childAspectRatio: 0.9,
      ),
      itemCount: subjects.length,
      itemBuilder: (context, index) {
        final subject = subjects[index];
        return SubjectCard(
          title: subject['title']!,
          imageUrl: subject['imageUrl']!,
          onTap: () {
            Navigator.pushNamed(
              context,
              SubjectChaptersScreen.routeName,
              arguments: subject['title']!, // Pass the subject title as an argument
            );
          },
        );
      },
    );
  }
}