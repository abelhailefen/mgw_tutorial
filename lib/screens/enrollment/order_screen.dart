// lib/screens/enrollment/order_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For Clipboard
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:mgw_tutorial/provider/auth_provider.dart';
// import 'package:mgw_tutorial/provider/semester_provider.dart'; // Used Consumer directly
import 'package:mgw_tutorial/provider/order_provider.dart';
import 'package:mgw_tutorial/models/user.dart';
import 'package:mgw_tutorial/models/semester.dart';
import 'package:mgw_tutorial/models/order.dart' as AppOrder;
import 'package:mgw_tutorial/l10n/app_localizations.dart';import 'package:mgw_tutorial/screens/main_screen.dart';
import 'package:mgw_tutorial/provider/semester_provider.dart';


class OrderScreen extends StatefulWidget {
  static const routeName = '/order-semester';
  final Semester semesterToEnroll;

  const OrderScreen({super.key, required this.semesterToEnroll});

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _bankNameController = TextEditingController();
  XFile? _pickedScreenshotFile;
  final ImagePicker _picker = ImagePicker();
  bool _agreedToTerms = false;
  bool _hasAttemptedSubmit = false;

  @override
  void initState() {
    super.initState();
    // Fetch semesters if not already loaded (e.g. if user directly navigates here somehow without Home screen)
    // This is more of a fallback.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final semesterProvider = Provider.of<SemesterProvider>(context, listen: false);
      if (semesterProvider.semesters.isEmpty) { // Only fetch if list is completely empty
        semesterProvider.fetchSemesters();
      }
    });
  }

  @override
  void dispose() {
    _bankNameController.dispose();
    super.dispose();
  }

  Future<void> _pickScreenshot() async {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    try {
      final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null && mounted) {
        setState(() { _pickedScreenshotFile = pickedFile; });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(l10n.errorPickingImage(e.toString()), style: TextStyle(color: theme.colorScheme.onErrorContainer)),
          backgroundColor: theme.colorScheme.errorContainer,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  Future<void> _submitOrder() async {
    final l10n = AppLocalizations.of(context)!;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    final theme = Theme.of(context);

    if (!mounted) return;

    final User? currentUser = authProvider.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(l10n.pleaseLoginOrRegister, style: TextStyle(color: theme.colorScheme.onErrorContainer)),
        backgroundColor: theme.colorScheme.errorContainer,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    orderProvider.clearError();
    setState(() { _hasAttemptedSubmit = true; });

    if (!_formKey.currentState!.validate()) return;

    if (_pickedScreenshotFile == null) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.pleaseAttachScreenshotError, style: TextStyle(color: theme.colorScheme.onErrorContainer)), backgroundColor: theme.colorScheme.errorContainer, behavior: SnackBarBehavior.floating,));
      return;
    }
    if (!_agreedToTerms) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.pleaseAgreeToTermsError, style: TextStyle(color: theme.colorScheme.onErrorContainer)), backgroundColor: theme.colorScheme.errorContainer, behavior: SnackBarBehavior.floating,));
      return;
    }
    // Bank name validation is handled by TextFormField

    List<AppOrder.OrderSelectionItem> orderSelections = [
      AppOrder.OrderSelectionItem(
        id: widget.semesterToEnroll.id.toString(),
        name: widget.semesterToEnroll.name,
      )
    ];

    String phoneForOrder = currentUser.phone;
    if (currentUser.phone.startsWith('+251') && currentUser.phone.length == 13) {
        phoneForOrder = '0${currentUser.phone.substring(4)}';
    }

    final AppOrder.Order orderPayload = AppOrder.Order(
      fullName: '${currentUser.firstName} ${currentUser.lastName}'.trim(),
      phone: phoneForOrder,
      bankName: _bankNameController.text.trim(),
      type: "semester_enrollment",
      status: "pending_approval",
      selections: orderSelections,
    );

    bool orderCreationSuccess = await orderProvider.createOrder(
      orderData: orderPayload,
      screenshotFile: _pickedScreenshotFile,
    );

    if (!mounted) return;

    if (orderCreationSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.enrollmentRequestSuccess, style: TextStyle(color: theme.colorScheme.onPrimaryContainer)),
          backgroundColor: theme.colorScheme.primaryContainer,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const MainScreen()),
            (Route<dynamic> route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(orderProvider.error ?? l10n.enrollmentRequestFailed, style: TextStyle(color: theme.colorScheme.onErrorContainer)),
          backgroundColor: theme.colorScheme.errorContainer,
          duration: const Duration(seconds: 5),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (authProvider.currentUser == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
          if(mounted) Navigator.of(context).pop();
      });
      return Scaffold(
        appBar: AppBar(title: Text(l10n.registerforcourses)),
        body: Center(child: Text(l10n.pleaseLoginOrRegister, style: theme.textTheme.titleLarge)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.enrollForSemesterTitle(widget.semesterToEnroll.name)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          autovalidateMode: _hasAttemptedSubmit ? AutovalidateMode.onUserInteraction : AutovalidateMode.disabled,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(l10n.selectedSemesterLabel, style: theme.textTheme.titleMedium),
              const SizedBox(height: 4),
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${widget.semesterToEnroll.name} - ${widget.semesterToEnroll.year}",
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${l10n.priceLabel} ${widget.semesterToEnroll.price} ${l10n.currencySymbol}",
                        style: theme.textTheme.bodyLarge,
                      ),
                      if (widget.semesterToEnroll.courses.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(l10n.coursesIncludedLabel, style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                        ...widget.semesterToEnroll.courses.map((course) => Text("- ${course.name}", style: theme.textTheme.bodyMedium)).toList(),
                      ]
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              Text(l10n.paymentInstruction, style: theme.textTheme.bodyMedium),
              const SizedBox(height: 16),

              TextFormField(
                controller: _bankNameController,
                decoration: InputDecoration(
                  labelText: l10n.bankNamePaymentLabel,
                  hintText: l10n.bankNamePaymentHint,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return l10n.bankNameValidationError;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              OutlinedButton.icon(
                  icon: Icon(Icons.attach_file, color: theme.colorScheme.primary),
                  label: Text(
                      _pickedScreenshotFile == null ? l10n.attachScreenshotButton : l10n.screenshotAttachedButton,
                      style: TextStyle(color: theme.colorScheme.primary),
                  ),
                  onPressed: _pickScreenshot,
                  style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      textStyle: const TextStyle(fontSize: 16),
                      side: BorderSide(color: theme.colorScheme.primary),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                  )
              ),
              if (_pickedScreenshotFile != null)
                Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                        '${l10n.fileNamePrefix}: ${_pickedScreenshotFile!.name}',
                        style: TextStyle(color: theme.colorScheme.secondary),
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis)),
              if (_hasAttemptedSubmit && _pickedScreenshotFile == null)
                 Padding(
                   padding: const EdgeInsets.only(top: 8.0, left: 12.0),
                   child: Text(l10n.pleaseAttachScreenshotError, style: TextStyle(color: theme.colorScheme.error, fontSize: 12)),
                 ),
              const SizedBox(height: 24),

              CheckboxListTile(
                title: RichText(
                    text: TextSpan(
                        style: theme.textTheme.bodyMedium,
                        children: [
                      TextSpan(text: l10n.termsAndConditionsAgreement),
                      TextSpan(text: l10n.termsAndConditionsLink, style: TextStyle(color: theme.colorScheme.primary, decoration: TextDecoration.underline)),
                      TextSpan(text: l10n.termsAndConditionsAnd),
                      TextSpan(text: l10n.privacyPolicyLink, style: TextStyle(color: theme.colorScheme.primary, decoration: TextDecoration.underline))
                    ])),
                value: _agreedToTerms,
                onChanged: (bool? value) => setState(() => _agreedToTerms = value ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: theme.colorScheme.primary,
                contentPadding: EdgeInsets.zero,
              ),
              if (_hasAttemptedSubmit && !_agreedToTerms)
                 Padding(
                   padding: const EdgeInsets.only(top: 8.0, left: 12.0),
                   child: Text(l10n.pleaseAgreeToTermsError, style: TextStyle(color: theme.colorScheme.error, fontSize: 12)),
                 ),
              const SizedBox(height: 30),

              Center(
                child: Consumer<OrderProvider>(
                  builder: (context, orderProv, child) {
                    return (orderProv.isLoading)
                        ? const CircularProgressIndicator()
                        : SizedBox(
                            width: MediaQuery.of(context).size.width * 0.8,
                            child: ElevatedButton(
                              onPressed: _submitOrder,
                              style: theme.elevatedButtonTheme.style?.copyWith(
                                padding: MaterialStateProperty.all(const EdgeInsets.symmetric(vertical: 16)),
                              ),
                              child: Text(
                                l10n.submitEnrollmentRequestButton,
                                textAlign: TextAlign.center,
                              )
                            ),
                          );
                  },
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}