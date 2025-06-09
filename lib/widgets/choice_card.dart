// lib/widgets/choice_card.dart

import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:provider/provider.dart';
import 'package:mgw_tutorial/provider/question_provider.dart'; // Use your project's provider
import 'package:mgw_tutorial/models/question.dart'; // Use your project's model
// import 'package:video_app/constants/styles.dart'; // Replace with your AppColors or Theme

class ChoiceCard extends StatelessWidget {
  final String label; // 'A', 'B', 'C', 'D'
  final String choiceText; // The actual text for the choice
  final Question question; // The question object this choice belongs to
  final bool hasSubmitted; // Whether the user has submitted the exam

  const ChoiceCard({
    super.key,
    required this.label,
    required this.choiceText,
    required this.question,
    required this.hasSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    // Use Consumer to react to changes in selected answers
    return Consumer<QuestionProvider>(
      builder: (context, provider, child) {
        final selectedAnswer = provider.getSelectedAnswer(question.id);
        final bool isSelected = selectedAnswer == label;
        final bool isCorrectAnswer = question.answer == label;

        Color? cardColor;
        Color? textColor = Theme.of(context).colorScheme.onSurface; // Default text color

        if (hasSubmitted) {
          if (isSelected) {
            cardColor = isCorrectAnswer
                ? Colors.green.withOpacity(0.3) // User selected correctly
                : Colors.red.withOpacity(0.3); // User selected incorrectly
             textColor = isCorrectAnswer ? Colors.green.shade800 : Colors.red.shade800;
          } else if (isCorrectAnswer) {
            cardColor = Colors.green.withOpacity(0.3); // Correct answer not selected by user
             textColor = Colors.green.shade800;
          }
        } else {
          // Before submission, only highlight the selected answer
          if (isSelected) {
            cardColor = Theme.of(context).colorScheme.primary.withOpacity(0.1); // Highlight selected
             textColor = Theme.of(context).colorScheme.primary;
          }
        }

        Icon? trailingIcon;
        if (hasSubmitted) {
          if (isSelected) {
            trailingIcon = isCorrectAnswer
                ? Icon(Icons.check_circle, color: Colors.green.shade800)
                : Icon(Icons.cancel, color: Colors.red.shade800);
          } else if (isCorrectAnswer) {
            trailingIcon = Icon(Icons.check_circle_outline, color: Colors.green.shade800);
          }
        }


        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4.0),
          color: cardColor ?? Theme.of(context).cardColor, // Use default card color if no specific color
          shape: RoundedRectangleBorder(
             borderRadius: BorderRadius.circular(8.0),
             side: isSelected && !hasSubmitted
                 ? BorderSide(color: Theme.of(context).colorScheme.primary, width: 1.5) // Add border when selected before submit
                 : BorderSide.none, // No border otherwise
          ),
          elevation: isSelected ? 2.0 : 1.0, // Slightly more elevation when selected
          child: InkWell(
            onTap: hasSubmitted ? null : () { // Disable tap after submission
              provider.selectAnswer(question.id, label);
            },
            borderRadius: BorderRadius.circular(8.0),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$label. ',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textColor, // Apply text color
                    ),
                  ),
                  Expanded(
                    child: HtmlWidget(
                      choiceText,
                       textStyle: TextStyle(fontSize: 16, color: textColor), // Apply text color
                    ),
                  ),
                  if (trailingIcon != null) ...[
                     const SizedBox(width: 8),
                     trailingIcon,
                   ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}