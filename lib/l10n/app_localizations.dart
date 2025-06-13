import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_am.dart';
import 'app_localizations_en.dart';
import 'app_localizations_or.dart';
import 'app_localizations_ti.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('am'),
    Locale('en'),
    Locale('or'),
    Locale('ti')
  ];

  /// No description provided for @downloadDocumentTooltip.
  ///
  /// In en, this message translates to:
  /// **'Download PDF'**
  String get downloadDocumentTooltip;

  /// No description provided for @downloadedDocumentTooltip.
  ///
  /// In en, this message translates to:
  /// **'Open downloaded PDF'**
  String get downloadedDocumentTooltip;

  /// No description provided for @notesItemType.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notesItemType;

  /// No description provided for @examsItemType.
  ///
  /// In en, this message translates to:
  /// **'Exams'**
  String get examsItemType;

  /// No description provided for @noNotesAvailable.
  ///
  /// In en, this message translates to:
  /// **'No notes available for this section'**
  String get noNotesAvailable;

  /// No description provided for @noExamsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No exams available for this section'**
  String get noExamsAvailable;

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'MGW Tutorial'**
  String get appTitle;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @library.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get library;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @aboutUs.
  ///
  /// In en, this message translates to:
  /// **'About Us'**
  String get aboutUs;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @changeLanguage.
  ///
  /// In en, this message translates to:
  /// **'Change Language'**
  String get changeLanguage;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @amharic.
  ///
  /// In en, this message translates to:
  /// **'Amharic'**
  String get amharic;

  /// No description provided for @tigrigna.
  ///
  /// In en, this message translates to:
  /// **'Tigrigna'**
  String get tigrigna;

  /// No description provided for @afaanOromo.
  ///
  /// In en, this message translates to:
  /// **'Afaan Oromo'**
  String get afaanOromo;

  /// No description provided for @welcomeMessage.
  ///
  /// In en, this message translates to:
  /// **'Welcome to MGW Tutorial!'**
  String get welcomeMessage;

  /// No description provided for @testimonials.
  ///
  /// In en, this message translates to:
  /// **'Testimonials'**
  String get testimonials;

  /// No description provided for @registerforcourses.
  ///
  /// In en, this message translates to:
  /// **'Enroll for Courses'**
  String get registerforcourses;

  /// No description provided for @mycourses.
  ///
  /// In en, this message translates to:
  /// **'My Courses'**
  String get mycourses;

  /// No description provided for @weeklyexam.
  ///
  /// In en, this message translates to:
  /// **'Weekly Exams'**
  String get weeklyexam;

  /// No description provided for @sharetheapp.
  ///
  /// In en, this message translates to:
  /// **'Share the App'**
  String get sharetheapp;

  /// No description provided for @joinourtelegram.
  ///
  /// In en, this message translates to:
  /// **'Join our Telegram'**
  String get joinourtelegram;

  /// No description provided for @discussiongroup.
  ///
  /// In en, this message translates to:
  /// **'Discussion Group'**
  String get discussiongroup;

  /// No description provided for @contactus.
  ///
  /// In en, this message translates to:
  /// **'Contact Us'**
  String get contactus;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @getRegisteredTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get getRegisteredTitle;

  /// No description provided for @studentNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Student\'s Name'**
  String get studentNameLabel;

  /// No description provided for @studentNameValidationError.
  ///
  /// In en, this message translates to:
  /// **'Please enter student\'s name'**
  String get studentNameValidationError;

  /// No description provided for @fatherNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Father\'s Name'**
  String get fatherNameLabel;

  /// No description provided for @fatherNameValidationError.
  ///
  /// In en, this message translates to:
  /// **'Please enter father\'s name'**
  String get fatherNameValidationError;

  /// No description provided for @streamLabel.
  ///
  /// In en, this message translates to:
  /// **'Department'**
  String get streamLabel;

  /// No description provided for @naturalStream.
  ///
  /// In en, this message translates to:
  /// **'Natural'**
  String get naturalStream;

  /// No description provided for @socialStream.
  ///
  /// In en, this message translates to:
  /// **'Social'**
  String get socialStream;

  /// No description provided for @institutionLabel.
  ///
  /// In en, this message translates to:
  /// **'Institution'**
  String get institutionLabel;

  /// No description provided for @selectInstitutionHint.
  ///
  /// In en, this message translates to:
  /// **'Select Institution'**
  String get selectInstitutionHint;

  /// No description provided for @institutionValidationError.
  ///
  /// In en, this message translates to:
  /// **'Please select institution'**
  String get institutionValidationError;

  /// No description provided for @genderLabel.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get genderLabel;

  /// No description provided for @maleGender.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get maleGender;

  /// No description provided for @femaleGender.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get femaleGender;

  /// No description provided for @selectServiceLabel.
  ///
  /// In en, this message translates to:
  /// **'Select Service'**
  String get selectServiceLabel;

  /// No description provided for @selectServiceHint.
  ///
  /// In en, this message translates to:
  /// **'Select Service'**
  String get selectServiceHint;

  /// No description provided for @serviceValidationError.
  ///
  /// In en, this message translates to:
  /// **'Please select a service'**
  String get serviceValidationError;

  /// No description provided for @paymentInstruction.
  ///
  /// In en, this message translates to:
  /// **'After making the payment, please enter the name of the bank you used below and attach the payment confirmation screenshot. Our Bank Account Details:\n • CBE: 1000 XXX XXXX XXXX (Debebe W.)\n • Telebirr: 09XX XXX XXX (Debebe W.)'**
  String get paymentInstruction;

  /// No description provided for @bankAccountLabel.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get bankAccountLabel;

  /// No description provided for @bankHolderNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get bankHolderNameLabel;

  /// No description provided for @copiedToClipboardMessage.
  ///
  /// In en, this message translates to:
  /// **'{accountNumber} copied to clipboard!'**
  String copiedToClipboardMessage(String accountNumber);

  /// No description provided for @couldNotOpenFileError.
  ///
  /// In en, this message translates to:
  /// **'Could not open file: {error}'**
  String couldNotOpenFileError(String error);

  /// No description provided for @couldNotFindDownloadedFileError.
  ///
  /// In en, this message translates to:
  /// **'Could not find the downloaded file.'**
  String get couldNotFindDownloadedFileError;

  /// No description provided for @videoIsDownloadingMessage.
  ///
  /// In en, this message translates to:
  /// **'Video is currently downloading. Please wait.'**
  String get videoIsDownloadingMessage;

  /// No description provided for @videoDownloadFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'Video download failed. Tap download button to retry.'**
  String get videoDownloadFailedMessage;

  /// No description provided for @videoDownloadCancelledMessage.
  ///
  /// In en, this message translates to:
  /// **'Video download was cancelled.'**
  String get videoDownloadCancelledMessage;

  /// No description provided for @notImplementedMessage.
  ///
  /// In en, this message translates to:
  /// **'Not implemented'**
  String get notImplementedMessage;

  /// No description provided for @noTextContent.
  ///
  /// In en, this message translates to:
  /// **'No text content.'**
  String get noTextContent;

  /// No description provided for @closeButtonText.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get closeButtonText;

  /// No description provided for @downloadVideoTooltip.
  ///
  /// In en, this message translates to:
  /// **'Download video for offline viewing'**
  String get downloadVideoTooltip;

  /// No description provided for @downloadedVideoTooltip.
  ///
  /// In en, this message translates to:
  /// **'Video downloaded. Tap to play, long press to delete.'**
  String get downloadedVideoTooltip;

  /// No description provided for @downloadFailedTooltip.
  ///
  /// In en, this message translates to:
  /// **'Download failed. Tap to retry.'**
  String get downloadFailedTooltip;

  /// No description provided for @deleteDownloadedFileTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete downloaded file'**
  String get deleteDownloadedFileTooltip;

  /// No description provided for @couldNotDeleteFileError.
  ///
  /// In en, this message translates to:
  /// **'Could not delete file: Invalid lesson data.'**
  String get couldNotDeleteFileError;

  /// No description provided for @fileDeletedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'File deleted successfully'**
  String get fileDeletedSuccessfully;

  /// No description provided for @fileNotFoundOrFailedToDelete.
  ///
  /// In en, this message translates to:
  /// **'File not found or failed to delete'**
  String get fileNotFoundOrFailedToDelete;

  /// No description provided for @attachScreenshotButton.
  ///
  /// In en, this message translates to:
  /// **'Attach Screenshot'**
  String get attachScreenshotButton;

  /// No description provided for @screenshotAttachedButton.
  ///
  /// In en, this message translates to:
  /// **'Screenshot Attached!'**
  String get screenshotAttachedButton;

  /// No description provided for @fileNamePrefix.
  ///
  /// In en, this message translates to:
  /// **'File'**
  String get fileNamePrefix;

  /// No description provided for @termsAndConditionsAgreement.
  ///
  /// In en, this message translates to:
  /// **'By continuing you are agreeing to the '**
  String get termsAndConditionsAgreement;

  /// No description provided for @termsAndConditionsLink.
  ///
  /// In en, this message translates to:
  /// **'terms and condition'**
  String get termsAndConditionsLink;

  /// No description provided for @termsAndConditionsAnd.
  ///
  /// In en, this message translates to:
  /// **' and '**
  String get termsAndConditionsAnd;

  /// No description provided for @privacyPolicyLink.
  ///
  /// In en, this message translates to:
  /// **'privacy policy'**
  String get privacyPolicyLink;

  /// No description provided for @submitButton.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get submitButton;

  /// No description provided for @errorPickingImage.
  ///
  /// In en, this message translates to:
  /// **'Error picking image: {errorMessage}'**
  String errorPickingImage(String errorMessage);

  /// No description provided for @pleaseSelectStreamError.
  ///
  /// In en, this message translates to:
  /// **'Please select a Department.'**
  String get pleaseSelectStreamError;

  /// No description provided for @pleaseSelectInstitutionError.
  ///
  /// In en, this message translates to:
  /// **'Please select an institution.'**
  String get pleaseSelectInstitutionError;

  /// No description provided for @pleaseSelectGenderError.
  ///
  /// In en, this message translates to:
  /// **'Please select your gender.'**
  String get pleaseSelectGenderError;

  /// No description provided for @pleaseSelectServiceError.
  ///
  /// In en, this message translates to:
  /// **'Please select a service.'**
  String get pleaseSelectServiceError;

  /// No description provided for @pleaseAttachScreenshotError.
  ///
  /// In en, this message translates to:
  /// **'Please attach a payment screenshot.'**
  String get pleaseAttachScreenshotError;

  /// No description provided for @pleaseAgreeToTermsError.
  ///
  /// In en, this message translates to:
  /// **'Please agree to the terms and conditions.'**
  String get pleaseAgreeToTermsError;

  /// No description provided for @notRegisteredTitle.
  ///
  /// In en, this message translates to:
  /// **'Looks like you\'re not registered yet'**
  String get notRegisteredTitle;

  /// No description provided for @notRegisteredSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Fill out the form to register and access our educational resources to boost your grades.'**
  String get notRegisteredSubtitle;

  /// No description provided for @getRegisteredNowButton.
  ///
  /// In en, this message translates to:
  /// **'Get Registered Now'**
  String get getRegisteredNowButton;

  /// No description provided for @mgwTutorialTitle.
  ///
  /// In en, this message translates to:
  /// **'MGW Tutorial'**
  String get mgwTutorialTitle;

  /// No description provided for @signUpToStartLearning.
  ///
  /// In en, this message translates to:
  /// **'Sign up to start learning'**
  String get signUpToStartLearning;

  /// No description provided for @signUpTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get signUpTitle;

  /// No description provided for @createAccountButton.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccountButton;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get alreadyHaveAccount;

  /// No description provided for @signInLink.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signInLink;

  /// No description provided for @signUpSuccessMessage.
  ///
  /// In en, this message translates to:
  /// **'Account created successfully! You can now sign in.'**
  String get signUpSuccessMessage;

  /// No description provided for @signUpFailedErrorGeneral.
  ///
  /// In en, this message translates to:
  /// **'Sign up failed. Please try again.'**
  String get signUpFailedErrorGeneral;

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get loginTitle;

  /// No description provided for @loginToContinue.
  ///
  /// In en, this message translates to:
  /// **'Welcome To MGW, Your Smarter Freshman Path To Straight A+/A’s in Every Course.'**
  String get loginToContinue;

  /// No description provided for @signInButton.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signInButton;

  /// No description provided for @dontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get dontHaveAccount;

  /// No description provided for @signUpLinkText.
  ///
  /// In en, this message translates to:
  /// **'Create Now'**
  String get signUpLinkText;

  /// No description provided for @phoneNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumberLabel;

  /// No description provided for @phoneNumberHint.
  ///
  /// In en, this message translates to:
  /// **'912 345 678'**
  String get phoneNumberHint;

  /// No description provided for @phoneNumberValidationErrorRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your phone number'**
  String get phoneNumberValidationErrorRequired;

  /// No description provided for @phoneNumberValidationErrorInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid 9-digit phone number'**
  String get phoneNumberValidationErrorInvalid;

  /// No description provided for @passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// No description provided for @passwordHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get passwordHint;

  /// No description provided for @passwordValidationErrorRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your password'**
  String get passwordValidationErrorRequired;

  /// No description provided for @passwordValidationErrorLength.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get passwordValidationErrorLength;

  /// No description provided for @accountCreationSimulatedMessage.
  ///
  /// In en, this message translates to:
  /// **'Account creation simulated. Check console.'**
  String get accountCreationSimulatedMessage;

  /// No description provided for @loginSuccessMessage.
  ///
  /// In en, this message translates to:
  /// **'Login successful! Welcome back.'**
  String get loginSuccessMessage;

  /// No description provided for @signInFailedErrorGeneral.
  ///
  /// In en, this message translates to:
  /// **'Sign in failed. Please check your credentials and try again.'**
  String get signInFailedErrorGeneral;

  /// No description provided for @changeProfilePictureButton.
  ///
  /// In en, this message translates to:
  /// **'Change Profile Picture'**
  String get changeProfilePictureButton;

  /// No description provided for @profilePictureSelectedMessage.
  ///
  /// In en, this message translates to:
  /// **'Profile picture selected! (Not Uploaded)'**
  String get profilePictureSelectedMessage;

  /// No description provided for @accountPhoneNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get accountPhoneNumberLabel;

  /// No description provided for @changePhoneNumberNotImplementedMessage.
  ///
  /// In en, this message translates to:
  /// **'Change Phone Number Tapped (Not Implemented)'**
  String get changePhoneNumberNotImplementedMessage;

  /// No description provided for @accountPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get accountPasswordLabel;

  /// No description provided for @changePasswordNotImplementedMessage.
  ///
  /// In en, this message translates to:
  /// **'Change Password Tapped (Not Implemented)'**
  String get changePasswordNotImplementedMessage;

  /// No description provided for @notificationsEnabledMessage.
  ///
  /// In en, this message translates to:
  /// **'Notifications Enabled'**
  String get notificationsEnabledMessage;

  /// No description provided for @notificationsDisabledMessage.
  ///
  /// In en, this message translates to:
  /// **'Notifications Disabled'**
  String get notificationsDisabledMessage;

  /// No description provided for @changeButton.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get changeButton;

  /// No description provided for @phoneNumberCannotBeEmptyError.
  ///
  /// In en, this message translates to:
  /// **'Phone number cannot be empty.'**
  String get phoneNumberCannotBeEmptyError;

  /// No description provided for @invalidPhoneNumberFormatError.
  ///
  /// In en, this message translates to:
  /// **'Invalid phone number format. Use 09..., 9..., or +2519...'**
  String get invalidPhoneNumberFormatError;

  /// No description provided for @registrationSuccessMessage.
  ///
  /// In en, this message translates to:
  /// **'Registration successful! Please await admin approval.'**
  String get registrationSuccessMessage;

  /// No description provided for @registrationFailedDefaultMessage.
  ///
  /// In en, this message translates to:
  /// **'Registration failed. Please try again.'**
  String get registrationFailedDefaultMessage;

  /// No description provided for @selectDepartmentHint.
  ///
  /// In en, this message translates to:
  /// **'Select Department / Stream'**
  String get selectDepartmentHint;

  /// No description provided for @yearLabel.
  ///
  /// In en, this message translates to:
  /// **'Academic Year'**
  String get yearLabel;

  /// No description provided for @yearValidationErrorEmpty.
  ///
  /// In en, this message translates to:
  /// **'Please enter year.'**
  String get yearValidationErrorEmpty;

  /// No description provided for @yearValidationErrorInvalid.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid year.'**
  String get yearValidationErrorInvalid;

  /// No description provided for @departmentLabel.
  ///
  /// In en, this message translates to:
  /// **'Department'**
  String get departmentLabel;

  /// No description provided for @pleaseSelectDepartmentError.
  ///
  /// In en, this message translates to:
  /// **'Please select a department.'**
  String get pleaseSelectDepartmentError;

  /// No description provided for @selectYearHint.
  ///
  /// In en, this message translates to:
  /// **'Select Year'**
  String get selectYearHint;

  /// No description provided for @pleaseSelectYearError.
  ///
  /// In en, this message translates to:
  /// **'Please select your academic year.'**
  String get pleaseSelectYearError;

  /// No description provided for @guestUser.
  ///
  /// In en, this message translates to:
  /// **'Guest User'**
  String get guestUser;

  /// No description provided for @pleaseLoginOrRegister.
  ///
  /// In en, this message translates to:
  /// **'Please login or register'**
  String get pleaseLoginOrRegister;

  /// No description provided for @registeredUser.
  ///
  /// In en, this message translates to:
  /// **'Registered User'**
  String get registeredUser;

  /// No description provided for @logoutSuccess.
  ///
  /// In en, this message translates to:
  /// **'Logged out successfully.'**
  String get logoutSuccess;

  /// No description provided for @selectSemesterLabel.
  ///
  /// In en, this message translates to:
  /// **'Select Semester'**
  String get selectSemesterLabel;

  /// No description provided for @selectSemesterHint.
  ///
  /// In en, this message translates to:
  /// **'Select a Semester'**
  String get selectSemesterHint;

  /// No description provided for @pleaseSelectSemesterError.
  ///
  /// In en, this message translates to:
  /// **'Please select a semester.'**
  String get pleaseSelectSemesterError;

  /// No description provided for @deviceInfoNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Device information not available. Please wait and try again.'**
  String get deviceInfoNotAvailable;

  /// No description provided for @deviceInfoProcessing.
  ///
  /// In en, this message translates to:
  /// **'Device information is still being processed. Please try again shortly.'**
  String get deviceInfoProcessing;

  /// No description provided for @deviceInfoInitializing.
  ///
  /// In en, this message translates to:
  /// **'Initializing... Please try logging in again.'**
  String get deviceInfoInitializing;

  /// No description provided for @deviceInfoProceedingDefault.
  ///
  /// In en, this message translates to:
  /// **'Could not fully determine device info.'**
  String get deviceInfoProceedingDefault;

  /// No description provided for @initializing.
  ///
  /// In en, this message translates to:
  /// **'Initializing...'**
  String get initializing;

  /// No description provided for @enrollForSemesterTitle.
  ///
  /// In en, this message translates to:
  /// **'Enroll for {semesterName}'**
  String enrollForSemesterTitle(String semesterName);

  /// No description provided for @selectedSemesterLabel.
  ///
  /// In en, this message translates to:
  /// **'Selected Semester:'**
  String get selectedSemesterLabel;

  /// No description provided for @priceLabel.
  ///
  /// In en, this message translates to:
  /// **'Price:'**
  String get priceLabel;

  /// No description provided for @coursesIncludedLabel.
  ///
  /// In en, this message translates to:
  /// **'Courses Included:'**
  String get coursesIncludedLabel;

  /// No description provided for @bankNamePaymentLabel.
  ///
  /// In en, this message translates to:
  /// **'Bank Name of Payment'**
  String get bankNamePaymentLabel;

  /// No description provided for @bankNamePaymentHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., Commercial Bank of Ethiopia, Awash Bank'**
  String get bankNamePaymentHint;

  /// No description provided for @bankNameValidationError.
  ///
  /// In en, this message translates to:
  /// **'Please enter the bank name.'**
  String get bankNameValidationError;

  /// No description provided for @enrollmentRequestSuccess.
  ///
  /// In en, this message translates to:
  /// **'Enrollment request submitted successfully! Please await approval.'**
  String get enrollmentRequestSuccess;

  /// No description provided for @enrollmentRequestFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to submit enrollment request.'**
  String get enrollmentRequestFailed;

  /// No description provided for @selectPaymentBankPrompt.
  ///
  /// In en, this message translates to:
  /// **'Please select a payment bank for reference.'**
  String get selectPaymentBankPrompt;

  /// No description provided for @goBackButton.
  ///
  /// In en, this message translates to:
  /// **'Go Back'**
  String get goBackButton;

  /// No description provided for @createPostTitle.
  ///
  /// In en, this message translates to:
  /// **'Create New Post'**
  String get createPostTitle;

  /// No description provided for @postTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Post Title'**
  String get postTitleLabel;

  /// No description provided for @postTitleHint.
  ///
  /// In en, this message translates to:
  /// **'Enter a clear and concise title'**
  String get postTitleHint;

  /// No description provided for @postTitleValidationRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter a title.'**
  String get postTitleValidationRequired;

  /// No description provided for @postTitleValidationLength.
  ///
  /// In en, this message translates to:
  /// **'Title must be at least 5 characters long.'**
  String get postTitleValidationLength;

  /// No description provided for @postDescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Post Description'**
  String get postDescriptionLabel;

  /// No description provided for @postDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Share your thoughts or questions in detail...'**
  String get postDescriptionHint;

  /// No description provided for @postDescriptionValidationRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter a description.'**
  String get postDescriptionValidationRequired;

  /// No description provided for @postDescriptionValidationLength.
  ///
  /// In en, this message translates to:
  /// **'Description must be at least 10 characters long.'**
  String get postDescriptionValidationLength;

  /// No description provided for @submitPostButton.
  ///
  /// In en, this message translates to:
  /// **'Submit Post'**
  String get submitPostButton;

  /// No description provided for @postCreatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Post created successfully!'**
  String get postCreatedSuccess;

  /// No description provided for @postCreateFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to create post. Please try again.'**
  String get postCreateFailed;

  /// No description provided for @editPostTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Post'**
  String get editPostTitle;

  /// No description provided for @generalTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get generalTitleLabel;

  /// No description provided for @generalTitleEmptyValidation.
  ///
  /// In en, this message translates to:
  /// **'Title cannot be empty'**
  String get generalTitleEmptyValidation;

  /// No description provided for @generalDescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get generalDescriptionLabel;

  /// No description provided for @generalDescriptionEmptyValidation.
  ///
  /// In en, this message translates to:
  /// **'Description cannot be empty'**
  String get generalDescriptionEmptyValidation;

  /// No description provided for @cancelButton.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelButton;

  /// No description provided for @saveButton.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get saveButton;

  /// No description provided for @postUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Post updated successfully!'**
  String get postUpdatedSuccess;

  /// No description provided for @postUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to update post.'**
  String get postUpdateFailed;

  /// No description provided for @deletePostTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Post'**
  String get deletePostTitle;

  /// No description provided for @deletePostConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this post and all its comments? This action cannot be undone.'**
  String get deletePostConfirmation;

  /// No description provided for @deleteButton.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteButton;

  /// No description provided for @postDeletedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Post deleted successfully!'**
  String get postDeletedSuccess;

  /// No description provided for @postDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete post.'**
  String get postDeleteFailed;

  /// No description provided for @commentPostedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Comment posted successfully!'**
  String get commentPostedSuccess;

  /// No description provided for @commentPostFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to post comment.'**
  String get commentPostFailed;

  /// No description provided for @replyPostedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Reply posted successfully!'**
  String get replyPostedSuccess;

  /// No description provided for @replyPostFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to post reply.'**
  String get replyPostFailed;

  /// No description provided for @updateGenericSuccess.
  ///
  /// In en, this message translates to:
  /// **'Update successful!'**
  String get updateGenericSuccess;

  /// No description provided for @updateGenericFailed.
  ///
  /// In en, this message translates to:
  /// **'Update failed.'**
  String get updateGenericFailed;

  /// No description provided for @deleteCommentTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Comment'**
  String get deleteCommentTitle;

  /// No description provided for @deleteReplyTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Reply'**
  String get deleteReplyTitle;

  /// No description provided for @deleteItemConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this {itemType}? This action cannot be undone.'**
  String deleteItemConfirmation(String itemType);

  /// No description provided for @itemDeletedSuccess.
  ///
  /// In en, this message translates to:
  /// **'{itemType} deleted successfully!'**
  String itemDeletedSuccess(String itemType);

  /// No description provided for @itemDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete {itemType}.'**
  String itemDeleteFailed(String itemType);

  /// No description provided for @commentsSectionHeader.
  ///
  /// In en, this message translates to:
  /// **'Comments'**
  String get commentsSectionHeader;

  /// No description provided for @noCommentsYet.
  ///
  /// In en, this message translates to:
  /// **'No comments yet. Be the first!'**
  String get noCommentsYet;

  /// No description provided for @writeCommentHint.
  ///
  /// In en, this message translates to:
  /// **'Write a comment...'**
  String get writeCommentHint;

  /// No description provided for @commentValidationEmpty.
  ///
  /// In en, this message translates to:
  /// **'Comment cannot be empty.'**
  String get commentValidationEmpty;

  /// No description provided for @postCommentTooltip.
  ///
  /// In en, this message translates to:
  /// **'Post Comment'**
  String get postCommentTooltip;

  /// No description provided for @replyButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'Reply'**
  String get replyButtonLabel;

  /// No description provided for @cancelReplyButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelReplyButtonLabel;

  /// No description provided for @writeReplyHint.
  ///
  /// In en, this message translates to:
  /// **'Write a reply...'**
  String get writeReplyHint;

  /// No description provided for @replyValidationEmpty.
  ///
  /// In en, this message translates to:
  /// **'Reply cannot be empty.'**
  String get replyValidationEmpty;

  /// No description provided for @editFieldValidationEmpty.
  ///
  /// In en, this message translates to:
  /// **'Cannot be empty'**
  String get editFieldValidationEmpty;

  /// No description provided for @saveChangesButton.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChangesButton;

  /// No description provided for @viewAllReplies.
  ///
  /// In en, this message translates to:
  /// **'View all {replyCount} replies...'**
  String viewAllReplies(String replyCount);

  /// No description provided for @commentItemDisplay.
  ///
  /// In en, this message translates to:
  /// **'Comment'**
  String get commentItemDisplay;

  /// No description provided for @replyItemDisplay.
  ///
  /// In en, this message translates to:
  /// **'Reply'**
  String get replyItemDisplay;

  /// No description provided for @darkModeLabel.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkModeLabel;

  /// No description provided for @darkModeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enable or disable dark theme'**
  String get darkModeSubtitle;

  /// No description provided for @receiveNotificationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Receive important updates'**
  String get receiveNotificationsSubtitle;

  /// No description provided for @pushNotificationsEnabled.
  ///
  /// In en, this message translates to:
  /// **'Push Notifications Enabled'**
  String get pushNotificationsEnabled;

  /// No description provided for @pushNotificationsDisabled.
  ///
  /// In en, this message translates to:
  /// **'Push Notifications Disabled'**
  String get pushNotificationsDisabled;

  /// No description provided for @viewPrivacyPolicyAction.
  ///
  /// In en, this message translates to:
  /// **'View Privacy Policy'**
  String get viewPrivacyPolicyAction;

  /// No description provided for @viewTermsAction.
  ///
  /// In en, this message translates to:
  /// **'View Terms of Service'**
  String get viewTermsAction;

  /// No description provided for @actionNotImplemented.
  ///
  /// In en, this message translates to:
  /// **'{featureName}: Not Implemented Yet'**
  String actionNotImplemented(String featureName);

  /// No description provided for @couldNotLaunchUrl.
  ///
  /// In en, this message translates to:
  /// **'Could not launch {urlString}'**
  String couldNotLaunchUrl(String urlString);

  /// No description provided for @shareAppSubject.
  ///
  /// In en, this message translates to:
  /// **'MGW Tutorial App'**
  String get shareAppSubject;

  /// No description provided for @emailSupportSubject.
  ///
  /// In en, this message translates to:
  /// **'App Support Query'**
  String get emailSupportSubject;

  /// No description provided for @contactViaEmail.
  ///
  /// In en, this message translates to:
  /// **'Contact via Email'**
  String get contactViaEmail;

  /// No description provided for @callUs.
  ///
  /// In en, this message translates to:
  /// **'Call Us'**
  String get callUs;

  /// No description provided for @visitOurWebsite.
  ///
  /// In en, this message translates to:
  /// **'Visit our Website'**
  String get visitOurWebsite;

  /// No description provided for @refreshingData.
  ///
  /// In en, this message translates to:
  /// **'Refreshing data...'**
  String get refreshingData;

  /// No description provided for @dataRefreshed.
  ///
  /// In en, this message translates to:
  /// **'Data refreshed!'**
  String get dataRefreshed;

  /// No description provided for @errorRefreshingData.
  ///
  /// In en, this message translates to:
  /// **'Error refreshing data. Please check your internet connection.'**
  String get errorRefreshingData;

  /// No description provided for @notesSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notesSectionTitle;

  /// No description provided for @notesSectionDescription.
  ///
  /// In en, this message translates to:
  /// **'Notes we have collected from students all around the country.'**
  String get notesSectionDescription;

  /// No description provided for @notesComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Notes section coming soon!'**
  String get notesComingSoon;

  /// No description provided for @coursesDetailsComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Courses details coming soon.'**
  String get coursesDetailsComingSoon;

  /// No description provided for @semesterCardTapped.
  ///
  /// In en, this message translates to:
  /// **'{semesterName} (ID: {semesterId}) Tapped'**
  String semesterCardTapped(String semesterName, String semesterId);

  /// No description provided for @enrollNowButton.
  ///
  /// In en, this message translates to:
  /// **'Enroll Now'**
  String get enrollNowButton;

  /// No description provided for @currencySymbol.
  ///
  /// In en, this message translates to:
  /// **'ETB'**
  String get currencySymbol;

  /// No description provided for @submitEnrollmentRequestButton.
  ///
  /// In en, this message translates to:
  /// **'Submit Enrollment Request'**
  String get submitEnrollmentRequestButton;

  /// No description provided for @currentPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Current Password'**
  String get currentPasswordLabel;

  /// No description provided for @newPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get newPasswordLabel;

  /// No description provided for @confirmNewPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm New Password'**
  String get confirmNewPasswordLabel;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// No description provided for @newPhoneNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'New Phone Number'**
  String get newPhoneNumberLabel;

  /// No description provided for @otpEnterPrompt.
  ///
  /// In en, this message translates to:
  /// **'Enter OTP'**
  String get otpEnterPrompt;

  /// No description provided for @otpValidationErrorRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter OTP'**
  String get otpValidationErrorRequired;

  /// No description provided for @otpValidationErrorLength.
  ///
  /// In en, this message translates to:
  /// **'OTP must be 6 digits'**
  String get otpValidationErrorLength;

  /// No description provided for @otpNewPhoneSameAsCurrentError.
  ///
  /// In en, this message translates to:
  /// **'New phone number cannot be the same as current.'**
  String get otpNewPhoneSameAsCurrentError;

  /// No description provided for @otpRequestButton.
  ///
  /// In en, this message translates to:
  /// **'Request OTP'**
  String get otpRequestButton;

  /// No description provided for @otpVerifyButton.
  ///
  /// In en, this message translates to:
  /// **'Verify OTP'**
  String get otpVerifyButton;

  /// No description provided for @passwordChangedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Password changed successfully!'**
  String get passwordChangedSuccess;

  /// No description provided for @passwordChangeFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to change password.'**
  String get passwordChangeFailed;

  /// No description provided for @otpSentSuccess.
  ///
  /// In en, this message translates to:
  /// **'OTP sent successfully.'**
  String get otpSentSuccess;

  /// No description provided for @otpRequestFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to request OTP.'**
  String get otpRequestFailed;

  /// No description provided for @phoneUpdateSuccess.
  ///
  /// In en, this message translates to:
  /// **'Phone number updated successfully.'**
  String get phoneUpdateSuccess;

  /// No description provided for @phoneUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to update phone number.'**
  String get phoneUpdateFailed;

  /// No description provided for @videoItemType.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get videoItemType;

  /// No description provided for @documentItemType.
  ///
  /// In en, this message translates to:
  /// **'Document'**
  String get documentItemType;

  /// No description provided for @quizItemType.
  ///
  /// In en, this message translates to:
  /// **'Quiz'**
  String get quizItemType;

  /// No description provided for @textItemType.
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get textItemType;

  /// No description provided for @unknownItemType.
  ///
  /// In en, this message translates to:
  /// **'Content'**
  String get unknownItemType;

  /// No description provided for @noVideosAvailable.
  ///
  /// In en, this message translates to:
  /// **'No videos available in this section.'**
  String get noVideosAvailable;

  /// No description provided for @noDocumentsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No documents available in this section.'**
  String get noDocumentsAvailable;

  /// No description provided for @noTextLessonsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No text lessons available in this section.'**
  String get noTextLessonsAvailable;

  /// No description provided for @noQuizzesAvailable.
  ///
  /// In en, this message translates to:
  /// **'No quizzes available in this section.'**
  String get noQuizzesAvailable;

  /// No description provided for @itemNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'No content available for {title}.'**
  String itemNotAvailable(String title);

  /// No description provided for @couldNotLaunchItem.
  ///
  /// In en, this message translates to:
  /// **'Could not launch {url}'**
  String couldNotLaunchItem(String url);

  /// No description provided for @noLaunchableContent.
  ///
  /// In en, this message translates to:
  /// **'No launchable content for {title}'**
  String noLaunchableContent(String title);

  /// No description provided for @chaptersTitle.
  ///
  /// In en, this message translates to:
  /// **'Chapters'**
  String get chaptersTitle;

  /// No description provided for @failedToLoadChaptersError.
  ///
  /// In en, this message translates to:
  /// **'Failed to load chapters: {error}'**
  String failedToLoadChaptersError(String error);

  /// No description provided for @noChaptersForCourse.
  ///
  /// In en, this message translates to:
  /// **'No chapters found for this course.'**
  String get noChaptersForCourse;

  /// No description provided for @failedToLoadLessonsError.
  ///
  /// In en, this message translates to:
  /// **'Failed to load lessons: {error}'**
  String failedToLoadLessonsError(String error);

  /// No description provided for @noLessonsInChapter.
  ///
  /// In en, this message translates to:
  /// **'No lessons in this chapter.'**
  String get noLessonsInChapter;

  /// No description provided for @noCoursesAvailable.
  ///
  /// In en, this message translates to:
  /// **'No courses available at the moment.'**
  String get noCoursesAvailable;

  /// No description provided for @shareYourTestimonialTitle.
  ///
  /// In en, this message translates to:
  /// **'Share Your Testimonial'**
  String get shareYourTestimonialTitle;

  /// No description provided for @titleLabel.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get titleLabel;

  /// No description provided for @titleValidationPrompt.
  ///
  /// In en, this message translates to:
  /// **'Please enter a title'**
  String get titleValidationPrompt;

  /// No description provided for @yourExperienceLabel.
  ///
  /// In en, this message translates to:
  /// **'Your Experience'**
  String get yourExperienceLabel;

  /// No description provided for @experienceValidationPrompt.
  ///
  /// In en, this message translates to:
  /// **'Please describe your experience'**
  String get experienceValidationPrompt;

  /// No description provided for @submitButtonGeneral.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submitButtonGeneral;

  /// No description provided for @testimonialSubmittedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Testimonial submitted! It will appear after approval.'**
  String get testimonialSubmittedSuccess;

  /// No description provided for @accountNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get accountNameLabel;

  /// No description provided for @changeNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Change Name'**
  String get changeNameLabel;

  /// No description provided for @firstNameLabel.
  ///
  /// In en, this message translates to:
  /// **'First Name'**
  String get firstNameLabel;

  /// No description provided for @lastNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Last Name'**
  String get lastNameLabel;

  /// No description provided for @firstNameValidationErrorRequired.
  ///
  /// In en, this message translates to:
  /// **'First name is required'**
  String get firstNameValidationErrorRequired;

  /// No description provided for @lastNameValidationErrorRequired.
  ///
  /// In en, this message translates to:
  /// **'Last name is required'**
  String get lastNameValidationErrorRequired;

  /// No description provided for @nameChangedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Name changed successfully'**
  String get nameChangedSuccess;

  /// No description provided for @nameChangeFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to change name'**
  String get nameChangeFailed;

  /// No description provided for @sessionInvalid.
  ///
  /// In en, this message translates to:
  /// **'Session expired. Please log in again'**
  String get sessionInvalid;

  /// No description provided for @errorLoadingData.
  ///
  /// In en, this message translates to:
  /// **'Error Loading Data'**
  String get errorLoadingData;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @faqTitle.
  ///
  /// In en, this message translates to:
  /// **'FAQ'**
  String get faqTitle;

  /// No description provided for @faqNoItems.
  ///
  /// In en, this message translates to:
  /// **'No FAQ items available at the moment.'**
  String get faqNoItems;

  /// No description provided for @videoPlaybackError.
  ///
  /// In en, this message translates to:
  /// **'Video playback error'**
  String get videoPlaybackError;

  /// No description provided for @otherItemsTabTitle.
  ///
  /// In en, this message translates to:
  /// **'Other Content'**
  String get otherItemsTabTitle;

  /// No description provided for @noOtherVideosInChapter.
  ///
  /// In en, this message translates to:
  /// **'No other videos found in this chapter.'**
  String get noOtherVideosInChapter;

  /// No description provided for @noOtherContentInChapter.
  ///
  /// In en, this message translates to:
  /// **'No other content found in this chapter.'**
  String get noOtherContentInChapter;

  /// No description provided for @cannotPlayOtherVideoHere.
  ///
  /// In en, this message translates to:
  /// **'Cannot play other videos from this list.'**
  String get cannotPlayOtherVideoHere;

  /// No description provided for @noOnlineVideoUrlAvailable.
  ///
  /// In en, this message translates to:
  /// **' No online video URL available for this item.'**
  String get noOnlineVideoUrlAvailable;

  /// No description provided for @playOriginalOnline.
  ///
  /// In en, this message translates to:
  /// **'Play Original Online'**
  String get playOriginalOnline;

  /// No description provided for @unexpectedError.
  ///
  /// In en, this message translates to:
  /// **'An unexpected error occurred: '**
  String get unexpectedError;

  /// No description provided for @loginFailedNoUserData.
  ///
  /// In en, this message translates to:
  /// **'Login failed: No user data returned by the server. Please try again or contact support.'**
  String get loginFailedNoUserData;

  /// No description provided for @playDownloadedVideoTooltip.
  ///
  /// In en, this message translates to:
  /// **'Play downloaded video'**
  String get playDownloadedVideoTooltip;

  /// No description provided for @openDownloadedDocumentTooltip.
  ///
  /// In en, this message translates to:
  /// **'Open downloaded document'**
  String get openDownloadedDocumentTooltip;

  /// No description provided for @myExams.
  ///
  /// In en, this message translates to:
  /// **'My Exams'**
  String get myExams;

  /// No description provided for @errorLoadingExams.
  ///
  /// In en, this message translates to:
  /// **'Failed to load exams. Please try again.'**
  String get errorLoadingExams;

  /// No description provided for @downloadExamTooltip.
  ///
  /// In en, this message translates to:
  /// **'Download Exam'**
  String get downloadExamTooltip;

  /// No description provided for @cancelDownloadTooltip.
  ///
  /// In en, this message translates to:
  /// **'Cancel Download'**
  String get cancelDownloadTooltip;

  /// No description provided for @deleteExamTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete Exam'**
  String get deleteExamTooltip;

  /// No description provided for @documentIsDownloadingMessage.
  ///
  /// In en, this message translates to:
  /// **'Document is currently downloading...'**
  String get documentIsDownloadingMessage;

  /// No description provided for @quizIsDownloadingMessage.
  ///
  /// In en, this message translates to:
  /// **'Exam is currently downloading...'**
  String get quizIsDownloadingMessage;

  /// No description provided for @couldNotOpenDownloadedFileError.
  ///
  /// In en, this message translates to:
  /// **'Could not open downloaded file'**
  String get couldNotOpenDownloadedFileError;

  /// No description provided for @downloadQuizTooltip.
  ///
  /// In en, this message translates to:
  /// **'Download exam'**
  String get downloadQuizTooltip;

  /// No description provided for @openDownloadedQuizTooltip.
  ///
  /// In en, this message translates to:
  /// **'Open downloaded exam'**
  String get openDownloadedQuizTooltip;

  /// No description provided for @fileDownloadedTooltip.
  ///
  /// In en, this message translates to:
  /// **'File downloaded'**
  String get fileDownloadedTooltip;

  /// No description provided for @couldNotLoadItem.
  ///
  /// In en, this message translates to:
  /// **'Could not load'**
  String get couldNotLoadItem;

  /// No description provided for @submitExam.
  ///
  /// In en, this message translates to:
  /// **'Submit Exam'**
  String get submitExam;

  /// No description provided for @noSemestersAvailable.
  ///
  /// In en, this message translates to:
  /// **'No semesters available.'**
  String get noSemestersAvailable;

  /// No description provided for @notificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// No description provided for @noNotificationsMessage.
  ///
  /// In en, this message translates to:
  /// **'You have no notifications yet'**
  String get noNotificationsMessage;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['am', 'en', 'or', 'ti'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'am':
      return AppLocalizationsAm();
    case 'en':
      return AppLocalizationsEn();
    case 'or':
      return AppLocalizationsOr();
    case 'ti':
      return AppLocalizationsTi();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
