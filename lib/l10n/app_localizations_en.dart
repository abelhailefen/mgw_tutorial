// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'MGW Tutorial';

  @override
  String get home => 'Home';

  @override
  String get library => 'Library';

  @override
  String get notifications => 'Notifications';

  @override
  String get account => 'Account';

  @override
  String get aboutUs => 'About Us';

  @override
  String get settings => 'Settings';

  @override
  String get logout => 'Logout';

  @override
  String get changeLanguage => 'Change Language';

  @override
  String get english => 'English';

  @override
  String get amharic => 'Amharic';

  @override
  String get tigrigna => 'Tigrigna';

  @override
  String get afaanOromo => 'Afaan Oromo';

  @override
  String get welcomeMessage => 'Welcome to MGW Tutorial!';

  @override
  String get testimonials => 'Testimonials';

  @override
  String get registerforcourses => 'Enroll for Courses';

  @override
  String get mycourses => 'My Courses';

  @override
  String get weeklyexam => 'Weekly Exams';

  @override
  String get sharetheapp => 'Share the App';

  @override
  String get joinourtelegram => 'Join our Telegram';

  @override
  String get discussiongroup => 'Discussion Group';

  @override
  String get contactus => 'Contact Us';

  @override
  String get refresh => 'Refresh';

  @override
  String get getRegisteredTitle => 'Create Account';

  @override
  String get studentNameLabel => 'Student\'s Name';

  @override
  String get studentNameValidationError => 'Please enter student\'s name';

  @override
  String get fatherNameLabel => 'Father\'s Name';

  @override
  String get fatherNameValidationError => 'Please enter father\'s name';

  @override
  String get streamLabel => 'Department';

  @override
  String get naturalStream => 'Natural';

  @override
  String get socialStream => 'Social';

  @override
  String get institutionLabel => 'Institution';

  @override
  String get selectInstitutionHint => 'Select Institution';

  @override
  String get institutionValidationError => 'Please select institution';

  @override
  String get genderLabel => 'Gender';

  @override
  String get maleGender => 'Male';

  @override
  String get femaleGender => 'Female';

  @override
  String get selectServiceLabel => 'Select Service';

  @override
  String get selectServiceHint => 'Select Service';

  @override
  String get serviceValidationError => 'Please select a service';

  @override
  String get paymentInstruction => 'After making the payment, please enter the name of the bank you used below and attach the payment confirmation screenshot. Our Bank Account Details:\n • CBE: 1000 XXX XXXX XXXX (Debebe W.)\n • Telebirr: 09XX XXX XXX (Debebe W.)';

  @override
  String get bankAccountLabel => 'Account';

  @override
  String get bankHolderNameLabel => 'Name';

  @override
  String copiedToClipboardMessage(String accountNumber) {
    return '$accountNumber copied to clipboard!';
  }

  @override
  String get attachScreenshotButton => 'Attach Screenshot';

  @override
  String get screenshotAttachedButton => 'Screenshot Attached!';

  @override
  String get fileNamePrefix => 'File';

  @override
  String get termsAndConditionsAgreement => 'By continuing you are agreeing to the ';

  @override
  String get termsAndConditionsLink => 'terms and condition';

  @override
  String get termsAndConditionsAnd => ' and ';

  @override
  String get privacyPolicyLink => 'privacy policy';

  @override
  String get submitButton => 'Create Account';

  @override
  String errorPickingImage(String errorMessage) {
    return 'Error picking image: $errorMessage';
  }

  @override
  String get pleaseSelectStreamError => 'Please select a Department.';

  @override
  String get pleaseSelectInstitutionError => 'Please select an institution.';

  @override
  String get pleaseSelectGenderError => 'Please select your gender.';

  @override
  String get pleaseSelectServiceError => 'Please select a service.';

  @override
  String get pleaseAttachScreenshotError => 'Please attach a payment screenshot.';

  @override
  String get pleaseAgreeToTermsError => 'Please agree to the terms and conditions.';

  @override
  String get notRegisteredTitle => 'Looks like you\'re not registered yet';

  @override
  String get notRegisteredSubtitle => 'Fill out the form to register and access our educational resources to boost your grades.';

  @override
  String get getRegisteredNowButton => 'Get Registered Now';

  @override
  String get mgwTutorialTitle => 'MGW Tutorial';

  @override
  String get signUpToStartLearning => 'Sign up to start learning';

  @override
  String get signUpTitle => 'Create Account';

  @override
  String get createAccountButton => 'Create Account';

  @override
  String get alreadyHaveAccount => 'Already have an account?';

  @override
  String get signInLink => 'Sign In';

  @override
  String get signUpSuccessMessage => 'Account created successfully! You can now sign in.';

  @override
  String get signUpFailedErrorGeneral => 'Sign up failed. Please try again.';

  @override
  String get loginTitle => 'Sign In';

  @override
  String get loginToContinue => 'Sign in to continue your learning journey.';

  @override
  String get signInButton => 'Sign In';

  @override
  String get dontHaveAccount => 'Don\'t have an account?';

  @override
  String get signUpLinkText => 'Sign Up Now';

  @override
  String get phoneNumberLabel => 'Phone Number';

  @override
  String get phoneNumberHint => '912 345 678';

  @override
  String get phoneNumberValidationErrorRequired => 'Please enter your phone number';

  @override
  String get phoneNumberValidationErrorInvalid => 'Enter a valid 9-digit phone number';

  @override
  String get passwordLabel => 'Password';

  @override
  String get passwordHint => 'Enter your password';

  @override
  String get passwordValidationErrorRequired => 'Please enter your password';

  @override
  String get passwordValidationErrorLength => 'Password must be at least 6 characters';

  @override
  String get accountCreationSimulatedMessage => 'Account creation simulated. Check console.';

  @override
  String get loginSuccessMessage => 'Login successful! Welcome back.';

  @override
  String get signInFailedErrorGeneral => 'Sign in failed. Please check your credentials and try again.';

  @override
  String get changeProfilePictureButton => 'Change Profile Picture';

  @override
  String get profilePictureSelectedMessage => 'Profile picture selected! (Not Uploaded)';

  @override
  String get accountPhoneNumberLabel => 'Phone number';

  @override
  String get changePhoneNumberNotImplementedMessage => 'Change Phone Number Tapped (Not Implemented)';

  @override
  String get accountPasswordLabel => 'Password';

  @override
  String get changePasswordNotImplementedMessage => 'Change Password Tapped (Not Implemented)';

  @override
  String get notificationsEnabledMessage => 'Notifications Enabled';

  @override
  String get notificationsDisabledMessage => 'Notifications Disabled';

  @override
  String get changeButton => 'Change';

  @override
  String get phoneNumberCannotBeEmptyError => 'Phone number cannot be empty.';

  @override
  String get invalidPhoneNumberFormatError => 'Invalid phone number format. Use 09..., 9..., or +2519...';

  @override
  String get registrationSuccessMessage => 'Registration successful! Please await admin approval.';

  @override
  String get registrationFailedDefaultMessage => 'Registration failed. Please try again.';

  @override
  String get selectDepartmentHint => 'Select Department / Stream';

  @override
  String get yearLabel => 'Academic Year';

  @override
  String get yearValidationErrorEmpty => 'Please enter year.';

  @override
  String get yearValidationErrorInvalid => 'Please enter a valid year.';

  @override
  String get departmentLabel => 'Department';

  @override
  String get pleaseSelectDepartmentError => 'Please select a department.';

  @override
  String get selectYearHint => 'Select Year';

  @override
  String get pleaseSelectYearError => 'Please select your academic year.';

  @override
  String get guestUser => 'Guest User';

  @override
  String get pleaseLoginOrRegister => 'Please login or register';

  @override
  String get registeredUser => 'Registered User';

  @override
  String get logoutSuccess => 'Logged out successfully.';

  @override
  String get selectSemesterLabel => 'Select Semester';

  @override
  String get selectSemesterHint => 'Select a Semester';

  @override
  String get pleaseSelectSemesterError => 'Please select a semester.';

  @override
  String get deviceInfoNotAvailable => 'Device information not available. Please wait and try again.';

  @override
  String get deviceInfoProcessing => 'Device information is still being processed. Please try again shortly.';

  @override
  String get deviceInfoInitializing => 'Initializing... Please try logging in again.';

  @override
  String get deviceInfoProceedingDefault => 'Could not fully determine device info. Proceeding with available data.';

  @override
  String get initializing => 'Initializing...';

  @override
  String enrollForSemesterTitle(String semesterName) {
    return 'Enroll for $semesterName';
  }

  @override
  String get selectedSemesterLabel => 'Selected Semester:';

  @override
  String get priceLabel => 'Price:';

  @override
  String get coursesIncludedLabel => 'Courses Included:';

  @override
  String get bankNamePaymentLabel => 'Bank Name of Payment';

  @override
  String get bankNamePaymentHint => 'e.g., Commercial Bank of Ethiopia, Awash Bank';

  @override
  String get bankNameValidationError => 'Please enter the bank name.';

  @override
  String get enrollmentRequestSuccess => 'Enrollment request submitted successfully! Please await approval.';

  @override
  String get enrollmentRequestFailed => 'Failed to submit enrollment request.';

  @override
  String get selectPaymentBankPrompt => 'Please select a payment bank for reference.';

  @override
  String get goBackButton => 'Go Back';

  @override
  String get createPostTitle => 'Create New Post';

  @override
  String get postTitleLabel => 'Post Title';

  @override
  String get postTitleHint => 'Enter a clear and concise title';

  @override
  String get postTitleValidationRequired => 'Please enter a title.';

  @override
  String get postTitleValidationLength => 'Title must be at least 5 characters long.';

  @override
  String get postDescriptionLabel => 'Post Description';

  @override
  String get postDescriptionHint => 'Share your thoughts or questions in detail...';

  @override
  String get postDescriptionValidationRequired => 'Please enter a description.';

  @override
  String get postDescriptionValidationLength => 'Description must be at least 10 characters long.';

  @override
  String get submitPostButton => 'Submit Post';

  @override
  String get postCreatedSuccess => 'Post created successfully!';

  @override
  String get postCreateFailed => 'Failed to create post. Please try again.';

  @override
  String get editPostTitle => 'Edit Post';

  @override
  String get generalTitleLabel => 'Title';

  @override
  String get generalTitleEmptyValidation => 'Title cannot be empty';

  @override
  String get generalDescriptionLabel => 'Description';

  @override
  String get generalDescriptionEmptyValidation => 'Description cannot be empty';

  @override
  String get cancelButton => 'Cancel';

  @override
  String get saveButton => 'Save';

  @override
  String get postUpdatedSuccess => 'Post updated!';

  @override
  String get postUpdateFailed => 'Failed to update post.';

  @override
  String get deletePostTitle => 'Delete Post';

  @override
  String get deletePostConfirmation => 'Are you sure you want to delete this post and all its comments? This action cannot be undone.';

  @override
  String get deleteButton => 'Delete';

  @override
  String get postDeletedSuccess => 'Post deleted successfully!';

  @override
  String get postDeleteFailed => 'Failed to delete post.';

  @override
  String get commentPostedSuccess => 'Comment posted!';

  @override
  String get commentPostFailed => 'Failed to post comment.';

  @override
  String get replyPostedSuccess => 'Reply posted!';

  @override
  String get replyPostFailed => 'Failed to post reply.';

  @override
  String get updateGenericSuccess => 'Update successful!';

  @override
  String get updateGenericFailed => 'Update failed.';

  @override
  String get deleteCommentTitle => 'Delete Comment';

  @override
  String get deleteReplyTitle => 'Delete Reply';

  @override
  String deleteItemConfirmation(String itemType) {
    return 'Are you sure you want to delete this $itemType? This action cannot be undone.';
  }

  @override
  String itemDeletedSuccess(String itemType) {
    return '$itemType deleted successfully!';
  }

  @override
  String itemDeleteFailed(String itemType) {
    return 'Failed to delete $itemType.';
  }

  @override
  String get commentsSectionHeader => 'Comments';

  @override
  String get noCommentsYet => 'No comments yet. Be the first!';

  @override
  String get writeCommentHint => 'Write a comment...';

  @override
  String get commentValidationEmpty => 'Comment cannot be empty.';

  @override
  String get postCommentTooltip => 'Post Comment';

  @override
  String get replyButtonLabel => 'Reply';

  @override
  String get cancelReplyButtonLabel => 'Cancel';

  @override
  String get writeReplyHint => 'Write a reply...';

  @override
  String get replyValidationEmpty => 'Reply cannot be empty.';

  @override
  String get editFieldValidationEmpty => 'Cannot be empty';

  @override
  String get saveChangesButton => 'Save Changes';

  @override
  String viewAllReplies(String replyCount) {
    return 'View all $replyCount replies...';
  }

  @override
  String get commentItemDisplay => 'Comment';

  @override
  String get replyItemDisplay => 'Reply';

  @override
  String get darkModeLabel => 'Dark Mode';

  @override
  String get darkModeSubtitle => 'Enable or disable dark theme';

  @override
  String get receiveNotificationsSubtitle => 'Receive important updates';

  @override
  String get pushNotificationsEnabled => 'Push Notifications Enabled';

  @override
  String get pushNotificationsDisabled => 'Push Notifications Disabled';

  @override
  String get viewPrivacyPolicyAction => 'View Privacy Policy';

  @override
  String get viewTermsAction => 'View Terms of Service';

  @override
  String actionNotImplemented(String featureName) {
    return '$featureName: Not Implemented Yet';
  }

  @override
  String couldNotLaunchUrl(String urlString) {
    return 'Could not launch $urlString';
  }

  @override
  String get shareAppSubject => 'MGW Tutorial App';

  @override
  String get emailSupportSubject => 'App Support Query';

  @override
  String get contactViaEmail => 'Contact via Email';

  @override
  String get callUs => 'Call Us';

  @override
  String get visitOurWebsite => 'Visit our Website';

  @override
  String get refreshingData => 'Refreshing data...';

  @override
  String get dataRefreshed => 'Data refreshed!';

  @override
  String get errorRefreshingData => 'Error refreshing data. Please check your internet connection.';

  @override
  String get notesSectionTitle => 'Notes';

  @override
  String get notesSectionDescription => 'Notes we have collected from students all around the country.';

  @override
  String get notesComingSoon => 'Notes section coming soon!';

  @override
  String get coursesDetailsComingSoon => 'Courses details coming soon.';

  @override
  String semesterCardTapped(String semesterName, String semesterId) {
    return '$semesterName (ID: $semesterId) Tapped';
  }

  @override
  String get enrollNowButton => 'Enroll Now';

  @override
  String get currencySymbol => 'ETB';

  @override
  String get submitEnrollmentRequestButton => 'Submit Enrollment Request';

  @override
  String get currentPasswordLabel => 'Current Password';

  @override
  String get newPasswordLabel => 'New Password';

  @override
  String get confirmNewPasswordLabel => 'Confirm New Password';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match';

  @override
  String get newPhoneNumberLabel => 'New Phone Number';

  @override
  String get otpEnterPrompt => 'Enter OTP';

  @override
  String get otpValidationErrorRequired => 'Please enter OTP';

  @override
  String get otpValidationErrorLength => 'OTP must be 6 digits';

  @override
  String get otpNewPhoneSameAsCurrentError => 'New phone number cannot be the same as current.';

  @override
  String get otpRequestButton => 'Request OTP';

  @override
  String get otpVerifyButton => 'Verify OTP';

  @override
  String get passwordChangedSuccess => 'Password changed successfully!';

  @override
  String get passwordChangeFailed => 'Failed to change password.';

  @override
  String get otpSentSuccess => 'OTP sent successfully.';

  @override
  String get otpRequestFailed => 'Failed to request OTP.';

  @override
  String get phoneUpdateSuccess => 'Phone number updated successfully.';

  @override
  String get phoneUpdateFailed => 'Failed to update phone number.';

  @override
  String get videoItemType => 'Video';

  @override
  String get documentItemType => 'Document';

  @override
  String get quizItemType => 'Quiz';

  @override
  String get textItemType => 'Text';

  @override
  String get unknownItemType => 'Content';

  @override
  String get noVideosAvailable => 'No videos available.';

  @override
  String get noDocumentsAvailable => 'No documents available.';

  @override
  String get noTextLessonsAvailable => 'No text lessons available.';

  @override
  String get noQuizzesAvailable => 'No quizzes available.';

  @override
  String itemNotAvailable(String contentType) {
    return '$contentType not available.';
  }

  @override
  String couldNotLaunchItem(String urlString) {
    return 'Could not launch $urlString';
  }

  @override
  String noLaunchableContent(String itemName) {
    return 'No launchable content for: $itemName';
  }

  @override
  String get chaptersTitle => 'Chapters';

  @override
  String failedToLoadChaptersError(String error) {
    return 'Failed to load chapters.\n$error';
  }

  @override
  String get noChaptersForCourse => 'No chapters found for this course.';

  @override
  String failedToLoadLessonsError(String error) {
    return 'Failed to load lessons.\n$error';
  }

  @override
  String get noLessonsInChapter => 'No lessons in this chapter yet.';

  @override
  String get noCoursesAvailable => 'No courses available at the moment.';

  @override
  String get shareYourTestimonialTitle => 'Share Your Testimonial';

  @override
  String get titleLabel => 'Title';

  @override
  String get titleValidationPrompt => 'Please enter a title';

  @override
  String get yourExperienceLabel => 'Your Experience';

  @override
  String get experienceValidationPrompt => 'Please describe your experience';

  @override
  String get submitButtonGeneral => 'Submit';

  @override
  String get testimonialSubmittedSuccess => 'Testimonial submitted! It will appear after approval.';
}
