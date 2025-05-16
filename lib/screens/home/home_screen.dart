import 'package:flutter/material.dart';
import 'package:mgw_tutorial/widgets/home/semesters_card.dart';
import 'package:mgw_tutorial/widgets/home/notes_card.dart';
import 'package:mgw_tutorial/provider/semester_provider.dart';
import 'package:provider/provider.dart';
// import 'package:mgw_tutorial/screens/library/library_screen.dart'; // Not used in this snippet
import 'package:mgw_tutorial/screens/registration/registration_screen.dart'; // Ensure this path is correct
import 'package:mgw_tutorial/models/semester.dart'; // Import the Semester model

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch semesters when the screen is initialized
    // Use listen:false because we are in initState
    Future.microtask(() =>
        Provider.of<SemesterProvider>(context, listen: false).fetchSemesters());
  }

  void _navigateToRegistrationForm() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RegistrationScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar( // Optional: Add an AppBar if your design needs one for HomeScreen
      //   title: const Text('Home'),
      // ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Consumer<SemesterProvider>(
              builder: (context, semesterProvider, child) {
                if (semesterProvider.isLoading) {
                  // Show a loading indicator that doesn't take up the whole screen initially
                  // or a more specific shimmer effect for the card area if preferred.
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 50.0),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (semesterProvider.error != null) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            // Using semesterProvider.error directly as it's formatted in provider
                            '${semesterProvider.error}',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.red[700]),
                          ),
                          const SizedBox(height: 10),
                          ElevatedButton(
                            onPressed: () => semesterProvider.fetchSemesters(),
                            child: const Text('Retry'),
                          )
                        ],
                      ),
                    ),
                  );
                }
                if (semesterProvider.semesters.isEmpty) {
                  return const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 50.0),
                        child: Text('No semesters available at the moment.',
                            style: TextStyle(fontSize: 16)),
                      ));
                }

                // If data is available, build the list of SemestersCard
                return Column(
                  children: semesterProvider.semesters.map((semester) {
                    // Prepare subjects for the card
                    List<String> subjectsLeft = [];
                    List<String> subjectsRight = [];
                    for (int i = 0; i < semester.courses.length; i++) {
                      if (i.isEven) {
                        subjectsLeft.add(semester.courses[i].name);
                      } else {
                        subjectsRight.add(semester.courses[i].name);
                      }
                    }
                    // If no courses, provide a default message or leave empty
                    if (semester.courses.isEmpty) {
                      subjectsLeft.add("Courses details coming soon.");
                    }

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: SemestersCard(
                        title: '${semester.name} - ${semester.year}',
                        // Use the helper getter from Semester model
                        // Provide a fallback URL if firstImageUrl is null
                        imageUrl: semester.firstImageUrl ?? 'https://via.placeholder.com/600x300.png?text=Semester+Image',
                        subjectsLeft: subjectsLeft,
                        subjectsRight: subjectsRight,
                        price: semester.price, // Assuming price is a string like "150.00"
                        onTap: () {
                           // Example: Navigate to a SemesterDetailScreen
                           // Navigator.of(context).push(MaterialPageRoute(builder: (_) => SemesterDetailScreen(semester: semester)));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('${semester.name} (ID: ${semester.id}) Tapped')),
                          );
                           print('Tapped on semester: ${semester.name}, ID: ${semester.id}');
                        },
                      ),
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 16),
            // Assuming NotesCard takes a full URL or you have a placeholder/asset
            const NotesCard(
              title: 'Notes',
              description: 'Notes we have collected from students all around the country.',
              imageUrl: 'https://via.placeholder.com/600x200.png?text=Notes+Preview', // Placeholder
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
                onPressed: _navigateToRegistrationForm,
                style: ElevatedButton.styleFrom(
                  // backgroundColor: Theme.of(context).primaryColor, // Example theming
                  // padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Get Registered Now', style: TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(height: 20), // For some spacing at the bottom
          ],
        ),
      ),
    );
  }
}