// lib/screens/sidebar/faq_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mgw_tutorial/provider/faq_provider.dart';
import 'package:mgw_tutorial/models/faq.dart'; 
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class FaqScreen extends StatefulWidget { 
  static const String routeName = '/faq';

  const FaqScreen({super.key});

  @override
  State<FaqScreen> createState() => _FaqScreenState();
}

class _FaqScreenState extends State<FaqScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch FAQs when the screen is initialized, if not already loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Check if FAQs are empty or if there was a previous error, then fetch
      final faqProvider = Provider.of<FaqProvider>(context, listen: false);
      if (faqProvider.faqs.isEmpty || faqProvider.error != null) {
         faqProvider.fetchFaqs();
      }
    });
  }

  Future<void> _refreshFaqs() async {
    await Provider.of<FaqProvider>(context, listen: false).fetchFaqs(forceRefresh: true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final faqProvider = Provider.of<FaqProvider>(context);

    Widget bodyContent;

    if (faqProvider.isLoading && faqProvider.faqs.isEmpty) { // Show loader only on initial load
      bodyContent = const Center(child: CircularProgressIndicator());
    } else if (faqProvider.error != null && faqProvider.faqs.isEmpty) { // Show error only if no data
      bodyContent = Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: theme.colorScheme.error, size: 50),
              const SizedBox(height: 16),
              Text(
                l10n.errorLoadingData, // "Error loading data"
                style: theme.textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                faqProvider.error!,
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: Text(l10n.retry), // "Retry"
                onPressed: _refreshFaqs,
              ),
            ],
          ),
        ),
      );
    } else if (faqProvider.faqs.isEmpty) {
      bodyContent = Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.help_outline, size: 60, color: theme.colorScheme.onSurface.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(
              l10n.faqNoItems,
              style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.7)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            if (faqProvider.error == null) // Show refresh button if no specific error but empty
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: Text(l10n.refresh),
                onPressed: _refreshFaqs,
              ),
          ],
        ),
      );
    } else {
      // Use faqProvider.faqs which already filters for isActive
      final List<Faq> activeFaqs = faqProvider.faqs;
      bodyContent = RefreshIndicator(
        onRefresh: _refreshFaqs,
        color: theme.colorScheme.primary,
        backgroundColor: theme.colorScheme.surface,
        child: ListView.builder(
          padding: const EdgeInsets.all(8.0),
          itemCount: activeFaqs.length,
          itemBuilder: (context, index) {
            final item = activeFaqs[index];
            return Card(
              elevation: 2.0,
              margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: ExpansionTile(
                iconColor: theme.colorScheme.primary,
                collapsedIconColor: theme.colorScheme.onSurfaceVariant,
                tilePadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                title: Text(
                  item.question, 
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                childrenPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0).copyWith(top: 0),
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Text(
                      item.answer, 
                      style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.faqTitle),
        elevation: 1.0,
      ),
      body: bodyContent,
    );
  }
}