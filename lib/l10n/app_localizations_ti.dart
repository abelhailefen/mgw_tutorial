// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Tigrinya (`ti`).
class AppLocalizationsTi extends AppLocalizations {
  AppLocalizationsTi([String locale = 'ti']) : super(locale);

  @override
  String get downloadDocumentTooltip => 'Download PDF';

  @override
  String get downloadedDocumentTooltip => 'Open downloaded PDF';

  @override
  String get notesItemType => 'Notes';

  @override
  String get examsItemType => 'Exams';

  @override
  String get noNotesAvailable => 'No notes available for this section';

  @override
  String get noExamsAvailable => 'No exams available for this section';

  @override
  String get appTitle => 'መጂወ መምህር';

  @override
  String get home => 'መበገሲ';

  @override
  String get library => 'ቤተ-መጽሐፍቲ';

  @override
  String get notifications => 'ናይ መጠንቀቕታ መልእኽታት';

  @override
  String get account => 'ሕሳብ';

  @override
  String get aboutUs => 'ብዛዕባና';

  @override
  String get settings => 'ቅጥዕታት';

  @override
  String get logout => 'ውጻእ';

  @override
  String get changeLanguage => 'ቋንቋ ቀይር';

  @override
  String get english => 'እንግሊዝኛ';

  @override
  String get amharic => 'ኣምሓርኛ';

  @override
  String get tigrigna => 'ትግርኛ';

  @override
  String get afaanOromo => 'ኣፋን ኦሮሞ';

  @override
  String get welcomeMessage => 'እንቋዕ ናብ መጂወ መምህር ብደሓን መጻእኩም!';

  @override
  String get testimonials => 'ምስክር ወሃብቲ';

  @override
  String get registerforcourses => 'ንኮርስታት ተመዝገብ';

  @override
  String get mycourses => 'ናተይ ኮርስታት';

  @override
  String get weeklyexam => 'ናይ ሰሙን ፈተናታት';

  @override
  String get sharetheapp => 'ኣፕሊኬሽን ኣካፍል';

  @override
  String get joinourtelegram => 'ቴሌግራምና ተጸንበር';

  @override
  String get discussiongroup => 'ጉጅለ ዘተ';

  @override
  String get contactus => 'ተራኸቡና';

  @override
  String get refresh => 'ኣሕድስ';

  @override
  String get getRegisteredTitle => 'ሕሳብ ፍጠር';

  @override
  String get studentNameLabel => 'ሽም ተማሃራይ';

  @override
  String get studentNameValidationError => 'እባኽ ኣትሽም ተማሃራይ ኣስገብ';

  @override
  String get fatherNameLabel => 'ሽም ኣቦ';

  @override
  String get fatherNameValidationError => 'እባኽ ኣትሽም ኣቦ ኣስገብ';

  @override
  String get streamLabel => 'ዲፓርትመንት';

  @override
  String get naturalStream => 'ተፈጥሮ';

  @override
  String get socialStream => 'ማሕበራዊ';

  @override
  String get institutionLabel => 'ተቋም';

  @override
  String get selectInstitutionHint => 'ተቋም ምረጽ';

  @override
  String get institutionValidationError => 'እባኽ ኣተቋም ምረጽ';

  @override
  String get genderLabel => 'ጾታ';

  @override
  String get maleGender => 'ወዲ';

  @override
  String get femaleGender => 'ጓል';

  @override
  String get selectServiceLabel => 'ዓይነት ኣገልግሎት ምረጽ';

  @override
  String get selectServiceHint => 'ዓይነት ኣገልግሎት ምረጽ';

  @override
  String get serviceValidationError => 'እባኽ ኣትዓይነት ኣገልግሎት ምረጽ';

  @override
  String get paymentInstruction =>
      'ክፍሊት ምስ ፈጸምካ፣ በጃኻ ሽም እቲ ዝኸፈልካሉ ባንክ ኣብ ታሕቲ ኣእቱ እሞ ስእሊ መረጋገጺ ክፍሊት ኣመዝግብ። ዝርዝር ሕሳብ ባንክና፡\n • CBE: 1000 XXX XXXX XXXX (ደበበ ወ.)\n • Telebirr: 09XX XXX XXX (ደበበ ወ.)';

  @override
  String get bankAccountLabel => 'ሕሳብ';

  @override
  String get bankHolderNameLabel => 'ሽም';

  @override
  String copiedToClipboardMessage(String accountNumber) {
    return '$accountNumber ናብ ክሊፕቦርድ ተቐዲሑ!';
  }

  @override
  String couldNotOpenFileError(String error) {
    return 'ፋይል ክኸፈት ኣይከኣለን: $error';
  }

  @override
  String get couldNotFindDownloadedFileError => 'ዝወረደ ፋይል ክትረክብ ኣይከኣልካን።';

  @override
  String get videoIsDownloadingMessage => 'ቪዲዮ ይወርድ ኣሎ። በጃኻም ጽበዩ።';

  @override
  String get videoDownloadFailedMessage =>
      'ምውራድ ቪዲዮ ኣይተዓወተን። እንደገና ንምፍታን አዝራር ምውራድ ጠውቕ።';

  @override
  String get videoDownloadCancelledMessage => 'ምውራድ ቪዲዮ ተሰሪዙ።';

  @override
  String get notImplementedMessage => 'ኣይተፈጸመን።';

  @override
  String get noTextContent => 'ጽሑፋዊ ትሕዝቶ የለን።';

  @override
  String get closeButtonText => 'ዕጾ';

  @override
  String get downloadVideoTooltip => 'ቪዲዮ ኣውርድ';

  @override
  String get downloadedVideoTooltip => 'ቪዲዮ ወሪዱ። ንምጽዋት ጠውቕ፣ ንምስራዝ ነዊሕ ጠውቕ።';

  @override
  String get downloadFailedTooltip => 'ምውራድ ኣይተዓወተን። እንደገና ንምፍታን ጠውቕ።';

  @override
  String get deleteDownloadedFileTooltip => 'ዝወረደ ፋይል ሰርዝ';

  @override
  String get couldNotDeleteFileError => 'ፋይል ክስረዝ ኣይከኣለን፡ ግጉይ ዝርዝር ትምህርቲ።';

  @override
  String get fileDeletedSuccessfully => 'ፋይል ብዕዉት ተሰሪዙ።';

  @override
  String get fileNotFoundOrFailedToDelete => 'ፋይል ኣይተረኽበን ወይ ክፍለቕ ኣይተኻእለን።';

  @override
  String get attachScreenshotButton => 'ስእሊ ስክሪን ኣመዝግብ';

  @override
  String get screenshotAttachedButton => 'ስእሊ ስክሪን ተመዝጊቡ!';

  @override
  String get fileNamePrefix => 'ፋይል';

  @override
  String get termsAndConditionsAgreement => 'ብምቕጻልካ ምስ እዚ ';

  @override
  String get termsAndConditionsLink => 'ውዕላት ከምኡውን ኩነታት';

  @override
  String get termsAndConditionsAnd => ' ከምኡውን እዚ ';

  @override
  String get privacyPolicyLink => 'ፖሊሲ ምስጢር';

  @override
  String get submitButton => 'ሕሳብ ፍጠር';

  @override
  String errorPickingImage(String errorMessage) {
    return 'ስእሊ ኣብ ምምራጽ ጌጋ፡ $errorMessage';
  }

  @override
  String get pleaseSelectStreamError => 'እባኽ ኣትዲፓርትመንት ምረጽ።';

  @override
  String get pleaseSelectInstitutionError => 'እባኽ ኣትተቋም ምረጽ።';

  @override
  String get pleaseSelectGenderError => 'እባኽ ኣትጾታኻ ምረጽ።';

  @override
  String get pleaseSelectServiceError => 'እባኽ ኣትዓይነት ኣገልግሎት ምረጽ።';

  @override
  String get pleaseAttachScreenshotError => 'እባኽ ኣትስእሊ ክፍሊት ኣመዝግብ።';

  @override
  String get pleaseAgreeToTermsError => 'እባኽ ኣትምስ ውዕላት ከምኡውን ኩነታት ተሰማማዕ።';

  @override
  String get notRegisteredTitle => 'ኣይተመዝገብካን ዝመስል።';

  @override
  String get notRegisteredSubtitle =>
      'ኣብቲ ቅጥዒ ምላእ እሞ ንትምህርታዊ ንብረትና ተመዝገብ እሞ ንውጽኢትካ ኣዐብዮ።';

  @override
  String get getRegisteredNowButton => 'ሕጂ ተመዝገብ';

  @override
  String get mgwTutorialTitle => 'መጂወ መምህር';

  @override
  String get signUpToStartLearning => 'ምምሃር ንምጅማር ተመዝገብ';

  @override
  String get signUpTitle => 'ሕሳብ ፍጠር';

  @override
  String get createAccountButton => 'ሕሳብ ፍጠር';

  @override
  String get alreadyHaveAccount => 'ቅድሚ ሕጂ ሕሳብ ኣሎካ?';

  @override
  String get signInLink => 'እቶ';

  @override
  String get signUpSuccessMessage => 'ሕሳብ ብዕዉት ተፈጢሩ! ሕጂ ክትኣቱ ትኽእል ኢኻ።';

  @override
  String get signUpFailedErrorGeneral => 'ምምዝጋብ ኣይተዓወተን። እባኽ እንደገና ፈትን።';

  @override
  String get loginTitle => 'እቶ';

  @override
  String get loginToContinue =>
      'እንቋዕ ናብ MGW ብደሓን መጻእኩም፣ ናትኩም በሊሕ ናይ ሓደሽቲ ተማሃሮ መንገዲ ናብ A+/A’s ኣብ ነፍሲ ወከፍ ኮርስ።';

  @override
  String get signInButton => 'እቶ';

  @override
  String get dontHaveAccount => 'ሕሳብ የብልካን?';

  @override
  String get signUpLinkText => 'ሕጂ ተመዝገብ';

  @override
  String get phoneNumberLabel => 'ቁጽሪ ስልኪ';

  @override
  String get phoneNumberHint => '912 345 678';

  @override
  String get phoneNumberValidationErrorRequired => 'እባኽ ኣትቁጽሪ ስልኪ ኣስገብ';

  @override
  String get phoneNumberValidationErrorInvalid => 'ትክክለኛ 9-ኣሃዝ ቁጽሪ ስልኪ ኣእቱ';

  @override
  String get passwordLabel => 'ሕቡእ ቃል';

  @override
  String get passwordHint => 'ሕቡእ ቃልካ ኣስገብ';

  @override
  String get passwordValidationErrorRequired => 'እባኽ ኣትሕቡእ ቃልካ ኣስገብ';

  @override
  String get passwordValidationErrorLength => 'ሕቡእ ቃል ቢያንስ 6 ቁምፊታት ክኸውን ኣለዎ';

  @override
  String get accountCreationSimulatedMessage => 'ምፍጣር ሕሳብ ተሰሪሑ። ኮንሶል ኣረጋግጽ።';

  @override
  String get loginSuccessMessage => 'ምእታው ብዕዉት ተፈጺሙ! ብደሓን ምጻእ።';

  @override
  String get signInFailedErrorGeneral =>
      'ምእታው ኣይተዓወተን። በጃኻም መረጃኻ ኣረጋግጽ እሞ እንደገና ፈትኖ።';

  @override
  String get changeProfilePictureButton => 'ስእሊ መገለጺ ቀይር';

  @override
  String get profilePictureSelectedMessage => 'ስእሊ መገለጺ ተመሪጹ! (ኣይተሰቕለን)';

  @override
  String get accountPhoneNumberLabel => 'ቁጽሪ ስልኪ';

  @override
  String get changePhoneNumberNotImplementedMessage =>
      'ቁጽሪ ስልኪ ንምቕያር ተጠዊቑ (ኣይተፈጸመን)';

  @override
  String get accountPasswordLabel => 'ሕቡእ ቃል';

  @override
  String get changePasswordNotImplementedMessage =>
      'ሕቡእ ቃል ንምቕያር ተጠዊቑ (ኣይተፈጸመን)';

  @override
  String get notificationsEnabledMessage => 'ናይ መጠንቀቕታ መልእኽታት ንቑሑት ኣለዉ';

  @override
  String get notificationsDisabledMessage => 'ናይ መጠንቀቕታ መልእኽታት ደዊኖም ኣለዉ';

  @override
  String get changeButton => 'ቀይር';

  @override
  String get phoneNumberCannotBeEmptyError => 'ቁጽሪ ስልኪ ባዶ ክኸውን ኣይከኣልን።';

  @override
  String get invalidPhoneNumberFormatError =>
      'ግጉይ ቅርጺ ቁጽሪ ስልኪ። 09...፣ 9...፣ ወይ +2519... ተጠቐም።';

  @override
  String get registrationSuccessMessage =>
      'ምምዝጋብ ብዕዉት ተፈጺሙ! በጃኻም ንፍቓድ ኣድሚን ጽበዩ።';

  @override
  String get registrationFailedDefaultMessage =>
      'ምምዝጋብ ኣይተዓወተን። እባኽ እንደገና ፈትን።';

  @override
  String get selectDepartmentHint => 'ዲፓርትመንት / ስትሪም ምረጽ';

  @override
  String get yearLabel => 'ዓመት ትምህርቲ';

  @override
  String get yearValidationErrorEmpty => 'እባኽ ኣትዓመት ኣስገብ።';

  @override
  String get yearValidationErrorInvalid => 'እባኽ ኣትትክክለኛ ዓመት ኣስገብ።';

  @override
  String get departmentLabel => 'ዲፓርትመንት';

  @override
  String get pleaseSelectDepartmentError => 'እባኽ ኣትዲፓርትመንት ምረጽ።';

  @override
  String get selectYearHint => 'ዓመት ምረጽ';

  @override
  String get pleaseSelectYearError => 'እባኽ ኣትዓመት ትምህርቲኻ ምረጽ።';

  @override
  String get guestUser => 'ዕዱም ተጠቀም';

  @override
  String get pleaseLoginOrRegister => 'እባኽ ኣትእቶ ወይ ተመዝገብ';

  @override
  String get registeredUser => 'ዝተመዝገበ ተጠቀም';

  @override
  String get logoutSuccess => 'ብዕዉት ወጺእካ።';

  @override
  String get selectSemesterLabel => 'ሴሚስተር ምረጽ';

  @override
  String get selectSemesterHint => 'ሴሚስተር ምረጽ';

  @override
  String get pleaseSelectSemesterError => 'እባኽ ኣትሴሚስተር ምረጽ።';

  @override
  String get deviceInfoNotAvailable =>
      'ዝርዝር ብዛዕባ መሳርሒ የለን። በጃኻም ጽበይ እሞ እንደገና ፈትን።';

  @override
  String get deviceInfoProcessing =>
      'ዝርዝር ብዛዕባ መሳርሒ ይካየድ ኣሎ። በጃኻም ድሕሪ ቁሩብ ግዜ እንደገና ፈትኖ።';

  @override
  String get deviceInfoInitializing => 'ጅምር ይገብር ኣሎ... በጃኻም እንደገና ንምእታው ፈትን።';

  @override
  String get deviceInfoProceedingDefault =>
      'ዝርዝር ብዛዕባ መሳርሒ ምሉእ ብምሉእ ክትረክብ ኣይከኣለን።';

  @override
  String get initializing => 'ጅምር ይገብር ኣሎ...';

  @override
  String enrollForSemesterTitle(String semesterName) {
    return 'ን $semesterName ተመዝገብ';
  }

  @override
  String get selectedSemesterLabel => 'ዝተመርጸ ሴሚስተር:';

  @override
  String get priceLabel => 'ዋጋ:';

  @override
  String get coursesIncludedLabel => 'ዝተሓወሱ ኮርስታት:';

  @override
  String get bankNamePaymentLabel => 'ሽም ባንክ ክፍሊት';

  @override
  String get bankNamePaymentHint => 'ኣብነት፡ ኮመርሻል ባንክ ኦፍ ኢትዮጵያ፣ ኣዋሽ ባንክ';

  @override
  String get bankNameValidationError => 'እባኽ ኣትሽም ባንክ ኣስገብ።';

  @override
  String get enrollmentRequestSuccess => 'ናይ ምምዝጋብ ሕቶ ብዕዉት ቀሪቡ! በጃኻም ንፍቓድ ጽበዩ።';

  @override
  String get enrollmentRequestFailed => 'ናይ ምምዝጋብ ሕቶ ንምቕራብ ኣይተዓወተን።';

  @override
  String get selectPaymentBankPrompt => 'እባኽ ኣትናይ ክፍሊት ባንክ ምረጽ።';

  @override
  String get goBackButton => 'ተመለስ';

  @override
  String get createPostTitle => 'ሓድሽ ጽሑፍ ፍጠር';

  @override
  String get postTitleLabel => 'ናይ ጽሑፍ ኣርእስቲ';

  @override
  String get postTitleHint => 'ንጹርን ሓጺርን ኣርእስቲ ኣእቱ';

  @override
  String get postTitleValidationRequired => 'እባኽ ኣትርእስቲ ኣእቱ።';

  @override
  String get postTitleValidationLength => 'ኣርእስቲ ቢያንስ 5 ቁምፊታት ክኸውን ኣለዎ።';

  @override
  String get postDescriptionLabel => 'ናይ ጽሑፍ መግለጺ';

  @override
  String get postDescriptionHint => 'ሓሳባትካ ወይ ሕቶታትካ ብዝርዝር ኣካፍል...';

  @override
  String get postDescriptionValidationRequired => 'እባኽ ኣትመግለጺ ኣእቱ።';

  @override
  String get postDescriptionValidationLength => 'መግለጺ ቢያንስ 10 ቁምፊታት ክኸውን ኣለዎ።';

  @override
  String get submitPostButton => 'ጽሑፍ ኣቕርብ';

  @override
  String get postCreatedSuccess => 'ጽሑፍ ብዕዉት ተፈጢሩ!';

  @override
  String get postCreateFailed => 'ጽሑፍ ንምፍጣር ኣይተዓወተን። እባኽ እንደገና ፈትን።';

  @override
  String get editPostTitle => 'ጽሑፍ ኣስተኻኽል';

  @override
  String get generalTitleLabel => 'ኣርእስቲ';

  @override
  String get generalTitleEmptyValidation => 'ኣርእስቲ ባዶ ክኸውን ኣይክእልን እዩ።';

  @override
  String get generalDescriptionLabel => 'መግለጺ';

  @override
  String get generalDescriptionEmptyValidation => 'መግለጺ ባዶ ክኸውን ኣይክእልን እዩ።';

  @override
  String get cancelButton => 'ሰርዝ';

  @override
  String get saveButton => 'ኣቐምጥ';

  @override
  String get postUpdatedSuccess => 'ጽሑፍ ተሓዲሱ!';

  @override
  String get postUpdateFailed => 'ጽሑፍ ንምሕዳስ ኣይተዓወተን።';

  @override
  String get deletePostTitle => 'ጽሑፍ ሰርዝ';

  @override
  String get deletePostConfirmation =>
      'እዝዩ ጽሑፍን ኩሎም እቶም 댓글ታቱን ንምስራዝ እርግጸኛ ድዩ? እዚ ተግባር ክቕየር ኣይክእልን እዩ።';

  @override
  String get deleteButton => 'ሰርዝ';

  @override
  String get postDeletedSuccess => 'ጽሑፍ ብዕዉት ተሰሪዙ!';

  @override
  String get postDeleteFailed => 'ጽሑፍ ንምስራዝ ኣይተዓወተን።';

  @override
  String get commentPostedSuccess => '댓글 ብዕዉት ተለጥፉ!';

  @override
  String get commentPostFailed => '댓글 ንምልጣፍ ኣይተዓወተን።';

  @override
  String get replyPostedSuccess => 'መልሲ ብዕዉት ተለጥፉ!';

  @override
  String get replyPostFailed => 'መልሲ ንምልጣፍ ኣይተዓወተን።';

  @override
  String get updateGenericSuccess => 'ምሕዳስ ብዕዉት ተፈጺሙ!';

  @override
  String get updateGenericFailed => 'ምሕዳስ ኣይተዓወተን።';

  @override
  String get deleteCommentTitle => '댓글 ሰርዝ';

  @override
  String get deleteReplyTitle => 'መልሲ ሰርዝ';

  @override
  String deleteItemConfirmation(String itemType) {
    return 'እዝዩ $itemType ንምስራዝ እርግጸኛ ድዩ? እዚ ተግባር ክቕየር ኣይክእልን እዩ።';
  }

  @override
  String itemDeletedSuccess(String itemType) {
    return '$itemType ብዕዉት ተሰሪዙ!';
  }

  @override
  String itemDeleteFailed(String itemType) {
    return '$itemType ንምስራዝ ኣይተዓወተን።';
  }

  @override
  String get commentsSectionHeader => '댓글ታት';

  @override
  String get noCommentsYet => 'ኣብዚ እዋን 댓글 የለን። ቀዳማይኹም ኩኑ!';

  @override
  String get writeCommentHint => '댓글 ጽሐፍ...';

  @override
  String get commentValidationEmpty => '댓글 ባዶ ክኸውን ኣይክእልን እዩ።';

  @override
  String get postCommentTooltip => '댓글 ለጥፍ';

  @override
  String get replyButtonLabel => 'መልሲ';

  @override
  String get cancelReplyButtonLabel => 'ሰርዝ';

  @override
  String get writeReplyHint => 'መልሲ ጽሐፍ...';

  @override
  String get replyValidationEmpty => 'መልሲ ባዶ ክኸውን ኣይክእልን እዩ።';

  @override
  String get editFieldValidationEmpty => 'ባዶ ክኸውን ኣይክእልን እዩ።';

  @override
  String get saveChangesButton => 'ለውጥታት ኣቐምጥ';

  @override
  String viewAllReplies(String replyCount) {
    return 'ኩሎም እቶም $replyCount መልስታት ርአ...';
  }

  @override
  String get commentItemDisplay => '댓글';

  @override
  String get replyItemDisplay => 'መልሲ';

  @override
  String get darkModeLabel => 'ጸሊም ሞድ';

  @override
  String get darkModeSubtitle => 'ጸሊም ገጽ ንቑሕ ግበር ወይ ኣዕጹ';

  @override
  String get receiveNotificationsSubtitle => 'ኣገዳሲ ሓደስቲ ሓበሬታ ተቐበል';

  @override
  String get pushNotificationsEnabled => 'ናይ ፑሽ ማሳወቂያታት ንቑሕ ኣለዉ';

  @override
  String get pushNotificationsDisabled => 'ናይ ፑሽ ማሳወቂያታት ደዊኖም ኣለዉ';

  @override
  String get viewPrivacyPolicyAction => 'ፖሊሲ ምስጢር ርአ';

  @override
  String get viewTermsAction => 'ውዕላት ኣገልግሎት ርአ';

  @override
  String actionNotImplemented(String featureName) {
    return '$featureName: ገና ኣይተፈጸመን';
  }

  @override
  String couldNotLaunchUrl(String urlString) {
    return '$urlString ክትጅምር ኣይከኣለን።';
  }

  @override
  String get shareAppSubject => 'መጂወ መምህር ኣፕ';

  @override
  String get emailSupportSubject => 'ሕቶ ደገፍ ኣፕ';

  @override
  String get contactViaEmail => 'ብኢሜል ተራኸቡና';

  @override
  String get callUs => 'ደውሉልና';

  @override
  String get visitOurWebsite => 'ድረ-ገጽና ጎብኙ';

  @override
  String get refreshingData => 'መረጃ ይሕደስ ኣሎ...';

  @override
  String get dataRefreshed => 'መረጃ ተሓዲሱ!';

  @override
  String get errorRefreshingData => 'መረጃ ኣብ ምሕዳስ ጌጋ። እባኻም መርበብ ኢንተርነትኩም ኣረጋግጹ።';

  @override
  String get notesSectionTitle => 'ማስታወሻታት';

  @override
  String get notesSectionDescription => 'ካብ ኩለን ሃገራት ካብ ተማሃሮ ዝሰበሰብናዮም ማስታወሻታት።';

  @override
  String get notesComingSoon => 'ክፍሊ ማስታወሻታት ቀርባ ይመጽእ!';

  @override
  String get coursesDetailsComingSoon => 'ዝርዝር ኮርስታት ቀርባ ይመጽእ።';

  @override
  String semesterCardTapped(String semesterName, String semesterId) {
    return '$semesterName (መለያ፡ $semesterId) ተጠዊቑ';
  }

  @override
  String get enrollNowButton => 'ሕጂ ተመዝገብ';

  @override
  String get currencySymbol => 'ብር';

  @override
  String get submitEnrollmentRequestButton => 'ናይ ምምዝጋብ ሕቶ ኣቕርብ';

  @override
  String get currentPasswordLabel => 'ናይ ሕጂ ሕቡእ ቃል';

  @override
  String get newPasswordLabel => 'ሓድሽ ሕቡእ ቃል';

  @override
  String get confirmNewPasswordLabel => 'ሓድሽ ሕቡእ ቃል ኣረጋግጽ';

  @override
  String get passwordsDoNotMatch => 'ሕቡእ ቃላት ኣይመሳሰሉን';

  @override
  String get newPhoneNumberLabel => 'ሓድሽ ቁጽሪ ስልኪ';

  @override
  String get otpEnterPrompt => 'OTP ኣእቱ';

  @override
  String get otpValidationErrorRequired => 'እባኽ ኣትOTP ኣእቱ';

  @override
  String get otpValidationErrorLength => 'OTP 6 ኣሃዝ ክኸውን ኣለዎ';

  @override
  String get otpNewPhoneSameAsCurrentError =>
      'ሓድሽ ቁጽሪ ስልኪ ምስ ናይ ሕጂ ክመሳሰል የብሉን።';

  @override
  String get otpRequestButton => 'OTP ሕተት';

  @override
  String get otpVerifyButton => 'OTP ኣረጋግጽ';

  @override
  String get passwordChangedSuccess => 'ሕቡእ ቃል ብዕዉት ተቐይሩ!';

  @override
  String get passwordChangeFailed => 'ሕቡእ ቃል ንምቕያር ኣይተዓወተን።';

  @override
  String get otpSentSuccess => 'OTP ብዕዉት ተላኢኹ።';

  @override
  String get otpRequestFailed => 'OTP ንምሕታት ኣይተዓወተን።';

  @override
  String get phoneUpdateSuccess => 'ቁጽሪ ስልኪ ብዕዉት ተሓዲሱ።';

  @override
  String get phoneUpdateFailed => 'ቁጽሪ ስልኪ ንምሕዳስ ኣይተዓወተን።';

  @override
  String get videoItemType => 'ቪዲዮ';

  @override
  String get documentItemType => 'ሰነድ';

  @override
  String get quizItemType => 'ፈተና';

  @override
  String get textItemType => 'ጽሑፍ';

  @override
  String get unknownItemType => 'ትሕዝቶ';

  @override
  String get noVideosAvailable => 'ኣብዚ ክፍሊ ምንም ቪዲዮታት የለን።';

  @override
  String get noDocumentsAvailable => 'ኣብዚ ክፍሊ ምንም ሰነዳት የለን።';

  @override
  String get noTextLessonsAvailable => 'ኣብዚ ክፍሊ ምንም ትምህርቲ ብጽሑፍ የለን።';

  @override
  String get noQuizzesAvailable => 'ኣብዚ ክፍሊ ምንም ፈተናታት የለን።';

  @override
  String itemNotAvailable(String title) {
    return 'ን $title ምንም ትሕዝቶ የለን።';
  }

  @override
  String couldNotLaunchItem(String url) {
    return '$url ክትጅምር ኣይከኣለን';
  }

  @override
  String noLaunchableContent(String title) {
    return 'ን $title ምንም ክጅመር ዝኽእል ትሕዝቶ የለን';
  }

  @override
  String get chaptersTitle => 'ምዕራፋት';

  @override
  String failedToLoadChaptersError(String error) {
    return 'ምዕራፋት ንምጽዓን ኣይተዓወተን: $error';
  }

  @override
  String get noChaptersForCourse => 'ንዚ ኮርስ ምንም ምዕራፋት ኣይተረኽቡን።';

  @override
  String failedToLoadLessonsError(String error) {
    return 'ትምህርቲ ንምጽዓን ኣይተዓወተን: $error';
  }

  @override
  String get noLessonsInChapter => 'ኣብዚ ምዕራፍ ምንም ትምህርቲ የለን።';

  @override
  String get noCoursesAvailable => 'ኣብዚ እዋን ምንም ኮርስታት የለን።';

  @override
  String get shareYourTestimonialTitle => 'ምስክርነትካ ኣካፍል';

  @override
  String get titleLabel => 'ኣርእስቲ';

  @override
  String get titleValidationPrompt => 'እባኽ ኣትርእስቲ ኣእቱ';

  @override
  String get yourExperienceLabel => 'ናይ ንስኻ ተሞክሮ';

  @override
  String get experienceValidationPrompt => 'እባኽ ኣትተሞክሮኻ ግለጽ';

  @override
  String get submitButtonGeneral => 'ኣቕርብ';

  @override
  String get testimonialSubmittedSuccess => 'ምስክርነት ቀሪቡ! ድሕሪ ፍቓድ ክርአ እዩ።';

  @override
  String get accountNameLabel => 'ሽም';

  @override
  String get changeNameLabel => 'ሽም ቀይር';

  @override
  String get firstNameLabel => 'ሽም';

  @override
  String get lastNameLabel => 'ሽም ኣቦ';

  @override
  String get firstNameValidationErrorRequired => 'ሽም ኣድላዪ እዩ';

  @override
  String get lastNameValidationErrorRequired => 'ሽም ኣቦ ኣድላዪ እዩ';

  @override
  String get nameChangedSuccess => 'ሽም ብዕዉት ተቐይሩ';

  @override
  String get nameChangeFailed => 'ሽም ንምቕያር ኣይተዓወተን';

  @override
  String get sessionInvalid => 'ምምዝጋብ ሰነድ ኣይተፈተረን። እባኽ እንደገና ፈትን።';

  @override
  String get errorLoadingData => 'ኣብ ምጽዓን ጌጋ';

  @override
  String get retry => 'ዳግማይ ፈትን';

  @override
  String get faqTitle => 'FAQ';

  @override
  String get faqNoItems => 'ምንም የተመዘገበ ጥያቄ የለም።';

  @override
  String get videoPlaybackError => 'ቪዲዮ መጫን ላይ ስህተት።';

  @override
  String get otherItemsTabTitle => 'ሌሎች ይዘቶች';

  @override
  String get noOtherVideosInChapter => 'በዚህ ምዕራፍ ሌሎች ቪዲዮዎች የሉም።';

  @override
  String get noOtherContentInChapter => 'በዚህ ምዕራፍ ሌሎች ይዘቶች የሉም።';

  @override
  String get cannotPlayOtherVideoHere => 'ይህን ቪዲዮ እዚህ መጫን አልተቻለም።';

  @override
  String get noOnlineVideoUrlAvailable => ' የቪዲዮው መረጃ በመስመር ላይ አልተገኘም።';

  @override
  String get playOriginalOnline => 'መስመር ላይ ይጫኑ';

  @override
  String get unexpectedError => 'ያልተጠበቀ ስህተት ተፈጥሯል። እባክዎ እንደገና ይሞክሩ።';

  @override
  String get loginFailedNoUserData =>
      'Login failed: No user data returned by the server. Please try again or contact support.';

  @override
  String get playDownloadedVideoTooltip => 'Play downloaded video';

  @override
  String get openDownloadedDocumentTooltip => 'Open downloaded document';

  @override
  String get myExams => 'My Exams';

  @override
  String get errorLoadingExams => 'Failed to load exams. Please try again.';

  @override
  String get downloadExamTooltip => 'Download Exam';

  @override
  String get cancelDownloadTooltip => 'Cancel Download';

  @override
  String get deleteExamTooltip => 'Delete Exam';

  @override
  String get documentIsDownloadingMessage =>
      'Document is currently downloading...';

  @override
  String get quizIsDownloadingMessage => 'Exam is currently downloading...';

  @override
  String get couldNotOpenDownloadedFileError =>
      'Could not open downloaded file';

  @override
  String get downloadQuizTooltip => 'Download exam';

  @override
  String get openDownloadedQuizTooltip => 'Open downloaded exam';

  @override
  String get fileDownloadedTooltip => 'File downloaded';

  @override
  String get couldNotLoadItem => 'Could not load';

  @override
  String get submitExam => 'Submit Exam';
}
