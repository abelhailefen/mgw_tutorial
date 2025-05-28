// lib/screens/sidebar/faq_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class FAQScreen extends StatelessWidget {
  static const routeName = '/faq';
  const FAQScreen({super.key});

  // Sample FAQ data - Replace with your actual questions and answers
  // You might fetch this from an API if the list is long or changes often
  final List<Map<String, String>> _faqItems = const [
    {
      'question': 'What is MGW Tutorial?',
      'answer': 'MGW Tutorial is an educational app designed to help students learn various subjects through tutorials, notes, and practice exams.',
    },
    {
      'question': 'How do I register for courses?',
      'answer': 'You can register for courses by navigating to the "Library" section or the "Register for Courses" option in the sidebar, and following the steps provided.',
    },
    {
      'question': 'How can I change the app language?',
      'answer': 'You can change the app language from the "Change Language" option available in the sidebar menu.',
    },
    {
      'question': 'Where can I find weekly exams?',
      'answer': 'Weekly exams are available under the "Weekly Exams" section in the sidebar menu.',
    },
    {
      'question': 'How do I contact support?',
      'answer': 'You can contact us via the "Contact Us" option in the sidebar, which provides email and phone contact details.',
    },
    // Add more FAQ items here
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.faq), // Assuming 'faq' key exists in AppLocalizations
      ),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        itemCount: _faqItems.length,
        separatorBuilder: (context, index) => Divider(color: theme.dividerColor),
        itemBuilder: (context, index) {
          final item = _faqItems[index];
          return ExpansionTile(
            title: Text(
              item['question']!,
              style: theme.textTheme.titleMedium,
            ),
            collapsedIconColor: theme.iconTheme.color,
            iconColor: theme.colorScheme.primary,
            backgroundColor: theme.colorScheme.surface,
            collapsedBackgroundColor: theme.colorScheme.surface,
            tilePadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            childrenPadding: const EdgeInsets.symmetric(horizontal: 16.0).copyWith(bottom: 8.0),
            children: <Widget>[
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  item['answer']!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.8),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}