// lib/widgets/question_card.dart

import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:mgw_tutorial/models/question.dart'; // Use your project's model
import 'package:mgw_tutorial/widgets/choice_card.dart'; // Use your project's widget
// import 'package:video_app/constants/styles.dart'; // Replace if needed
// import 'package:video_app/UEE/screens/explanation_screen.dart'; // Remove or adapt ExplanationWidget

class QuestionCard extends StatelessWidget {
  final Question question;
  final int questionNumber; // 1-based index for display
  final bool hasSubmitted; // Pass this state down

  const QuestionCard({
    super.key,
    required this.question,
    required this.questionNumber,
    required this.hasSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    // No need to listen to provider here unless QuestionCard itself changes based on selection
    // The choices handle their own state updates via Consumer.

    return Card(
      elevation: 2, // Slightly less elevation than SubjectCard
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6), // Smaller margin
      shape: RoundedRectangleBorder(
         borderRadius: BorderRadius.circular(10.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0), // Increased padding inside the card
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Question Text with Number
            HtmlWidget(
              '$questionNumber: ${question.questionText}',
              textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12), // Increased spacing

            // Image if available
            if (question.imageUrl != null && question.imageUrl!.isNotEmpty) ...[
               // Simplified image loading - just network for now
               Image.network(
                 question.imageUrl!,
                 errorBuilder: (context, error, stackTrace) =>
                     const Center(child: Text('Failed to load image')),
               ),
               const SizedBox(height: 12),
             ],

             // Passage text if available
             if (question.passage != null && question.passage!.isNotEmpty) ...[
               Card(
                 margin: const EdgeInsets.symmetric(vertical: 8.0),
                 elevation: 0.5,
                 color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
                 child: Padding(
                   padding: const EdgeInsets.all(12.0),
                   child: HtmlWidget(
                     question.passage!,
                     textStyle: TextStyle(
                        fontSize: 15,
                        fontStyle: FontStyle.italic,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                   ),
                 ),
               ),
               const SizedBox(height: 12),
             ],


            // Choices
            ChoiceCard(
              label: 'A',
              choiceText: question.optionA,
              question: question,
              hasSubmitted: hasSubmitted,
            ),
            ChoiceCard(
              label: 'B',
              choiceText: question.optionB,
              question: question,
              hasSubmitted: hasSubmitted,
            ),
            ChoiceCard(
              label: 'C',
              choiceText: question.optionC,
              question: question,
              hasSubmitted: hasSubmitted,
            ),
            ChoiceCard(
              label: 'D',
              choiceText: question.optionD,
              question: question,
              hasSubmitted: hasSubmitted,
            ),

            // Explanation - Temporarily remove or add a placeholder
            // if (hasSubmitted && question.explanation != null && question.explanation!.isNotEmpty) ...[
            //   const SizedBox(height: 16),
            //   // Add a button to show/hide explanation if desired,
            //   // or display directly if space is not an issue.
            //   // For simplicity, let's show a placeholder.
            //   Text('Explanation: ${question.explanation}', style: TextStyle(fontStyle: FontStyle.italic)),
            // ]
             // Removed the explanation widget and related logic for simplicity initially.
             // You can add it back later, integrating it into this project's structure.
          ],
        ),
      ),
    );
  }
}