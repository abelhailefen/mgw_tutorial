// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Amharic (`am`).
class AppLocalizationsAm extends AppLocalizations {
  AppLocalizationsAm([String locale = 'am']) : super(locale);

  @override
  String get appTitle => 'መጂወ አስጠኚ';

  @override
  String get home => 'መነሻ';

  @override
  String get library => 'ቤተ-መጽሐፍት';

  @override
  String get notifications => 'ማሳወቂያዎች';

  @override
  String get account => 'መለያ';

  @override
  String get aboutUs => 'ስለ እኛ';

  @override
  String get settings => 'ቅንብሮች';

  @override
  String get logout => 'ውጣ';

  @override
  String get changeLanguage => 'ቋንቋ ቀይር';

  @override
  String get english => 'እንግሊዝኛ';

  @override
  String get amharic => 'አማርኛ';

  @override
  String get tigrigna => 'ትግርኛ';

  @override
  String get afaanOromo => 'አፋን ኦሮሞ';

  @override
  String get welcomeMessage => 'ወደ መጂወ አስጠኚ በደህና መጡ!';

  @override
  String get testimonials => 'ምስክርነት';

  @override
  String get registerforcourses => 'ለኮርሶች ይመዝገቡ';

  @override
  String get mycourses => 'የኔ ኮርስዎች';

  @override
  String get weeklyexam => 'የሳምንቱ ፈተናዎች';

  @override
  String get sharetheapp => 'አፕሊኬሽኑን ይጋሩ';

  @override
  String get joinourtelegram => 'ቴሌግራማችንን ይቀላቀሉ';

  @override
  String get discussiongroup => 'ውይይት ቡድን';

  @override
  String get contactus => 'አግኙን';

  @override
  String get refresh => 'ማደስ';

  @override
  String get getRegisteredTitle => 'መለያ ፍጠር';

  @override
  String get studentNameLabel => 'የተማሪ ስም';

  @override
  String get studentNameValidationError => 'እባኮትን የተማሪ ስም ያስገቡ';

  @override
  String get fatherNameLabel => 'አባት ስም';

  @override
  String get fatherNameValidationError => 'እባኮትን የአባት ስም ያስገቡ';

  @override
  String get streamLabel => 'ዲፓርትመንት';

  @override
  String get naturalStream => 'ተፈጥሯዊ';

  @override
  String get socialStream => 'ማህበራዊ';

  @override
  String get institutionLabel => 'ተቋም';

  @override
  String get selectInstitutionHint => 'ተቋም ይምረጡ';

  @override
  String get institutionValidationError => 'እባኮትን ተቋም ይምረጡ';

  @override
  String get genderLabel => 'ጾታ';

  @override
  String get maleGender => 'ወንድ';

  @override
  String get femaleGender => 'ሴት';

  @override
  String get selectServiceLabel => 'የአገልግሎት ዓይነት ይምረጡ';

  @override
  String get selectServiceHint => 'የአገልግሎት ዓይነት ይምረጡ';

  @override
  String get serviceValidationError => 'እባኮትን የአገልግሎት ዓይነት ይምረጡ';

  @override
  String get paymentInstruction => 'ክፍያውን ከፈጸሙ በኋላ፣ እባክዎ የከፈሉበትን የባንክ ስም ከዚህ በታች ያስገቡ እና የክፍያ ማረጋገጫ ቅጽበታዊ ገጽ እይታን ያያይዙ። የባንክ ሂሳብ ዝርዝሮቻችን፦\n • ንግድ ባንክ: 1000 XXX XXXX XXXX (ደበበ ወ.)\n • ቴሌብር: 09XX XXX XXX (ደበበ ወ.)';

  @override
  String get bankAccountLabel => 'መለያ';

  @override
  String get bankHolderNameLabel => 'ስም';

  @override
  String copiedToClipboardMessage(String accountNumber) {
    return '$accountNumber ወደ ቅንጥብ ሰሌዳ ተቀድቷል!';
  }

  @override
  String get attachScreenshotButton => 'ቅጽበታዊ ገጽ እይታን ያያይዙ';

  @override
  String get screenshotAttachedButton => 'ቅጽበታዊ ገጽ እይታ ተያይዟል!';

  @override
  String get fileNamePrefix => 'ፋይል';

  @override
  String get termsAndConditionsAgreement => 'በመቀጠልዎ በውሎች እና ሁኔታዎች ተስማምተዋል ';

  @override
  String get termsAndConditionsLink => 'ውሎች እና ሁኔታዎች';

  @override
  String get termsAndConditionsAnd => ' እና ';

  @override
  String get privacyPolicyLink => 'የግላዊነት ፖሊሲ';

  @override
  String get submitButton => 'መለያ ፍጠር';

  @override
  String errorPickingImage(String errorMessage) {
    return 'ምስልን መምረጥ ላይ ስህተት: $errorMessage';
  }

  @override
  String get pleaseSelectStreamError => 'እባክዎ ዲፓርትመንት ይምረጡ።';

  @override
  String get pleaseSelectInstitutionError => 'እባክዎ ተቋም ይምረጡ።';

  @override
  String get pleaseSelectGenderError => 'እባክዎ ጾታዎን ይምረጡ።';

  @override
  String get pleaseSelectServiceError => 'እባክዎ የአገልግሎት ዓይነት ይምረጡ።';

  @override
  String get pleaseAttachScreenshotError => 'እባክዎ የክፍያ ቅጽበታዊ ገጽ ያያይዙ።';

  @override
  String get pleaseAgreeToTermsError => 'እባክዎ በደንቦቹ እና ሁኔታዎች ይስማሙ።';

  @override
  String get notRegisteredTitle => 'እስካሁን ያልተመዘገቡ ይመስላል።';

  @override
  String get notRegisteredSubtitle => 'ውጤቶቻችሁን ለማሳደግ የትምህርት ሀብቶቻችንን ለመመዝገብ እና ለማግኘት ቅጹን ይሙሉ።';

  @override
  String get getRegisteredNowButton => 'አሁን ይመዝገቡ';

  @override
  String get mgwTutorialTitle => 'መጂወ አስጠኚ';

  @override
  String get signUpToStartLearning => 'መማር ለመጀመር ይመዝገቡ';

  @override
  String get signUpTitle => 'መለያ ይፍጠሩ';

  @override
  String get createAccountButton => 'መለያ ይፍጠሩ';

  @override
  String get alreadyHaveAccount => 'አስቀድመው መለያ አለዎት?';

  @override
  String get signInLink => 'ይግቡ';

  @override
  String get signUpSuccessMessage => 'መለያ በተሳካ ሁኔታ ተፈጥሯል! አሁን መግባት ይችላሉ።';

  @override
  String get signUpFailedErrorGeneral => 'መለያ መፍጠር አልተሳካም። እባክዎ እንደገና ይሞክሩ።';

  @override
  String get loginTitle => 'ይግቡ';

  @override
  String get loginToContinue => 'የመማር ጉዞዎን ለመቀጠል ይግቡ።';

  @override
  String get signInButton => 'ይግቡ';

  @override
  String get dontHaveAccount => 'መለያ የሎትም?';

  @override
  String get signUpLinkText => 'አሁን ይመዝገቡ';

  @override
  String get phoneNumberLabel => 'ስልክ ቁጥር';

  @override
  String get phoneNumberHint => '912 345 678';

  @override
  String get phoneNumberValidationErrorRequired => 'እባክዎ ስልክ ቁጥርዎን ያስገቡ';

  @override
  String get phoneNumberValidationErrorInvalid => 'ትክክለኛ ባለ 9 አሃዝ ስልክ ቁጥር ያስገቡ';

  @override
  String get passwordLabel => 'የይለፍ ቃል';

  @override
  String get passwordHint => 'የይለፍ ቃልዎን ያስገቡ';

  @override
  String get passwordValidationErrorRequired => 'እባክዎ የይለፍ ቃልዎን ያስገቡ';

  @override
  String get passwordValidationErrorLength => 'የይለፍ ቃል ቢያንስ 6 ቁምፊዎች መሆን አለበት';

  @override
  String get accountCreationSimulatedMessage => 'የአካውንት አፈጣጠር ተመስሏል። ኮንሶሉን ያረጋግጡ።';

  @override
  String get loginSuccessMessage => 'በተሳካ ሁኔታ ገብተዋል! እንኳን ደህና መጡ።';

  @override
  String get signInFailedErrorGeneral => 'መግባት አልተሳካም። እባክዎ መረጃዎን ያረጋግጡና እንደገና ይሞክሩ።';

  @override
  String get changeProfilePictureButton => 'የመገለጫ ፎቶ ቀይር';

  @override
  String get profilePictureSelectedMessage => 'የመገለጫ ፎቶ ተመርጧል! (አልተሰቀለም)';

  @override
  String get accountPhoneNumberLabel => 'ስልክ ቁጥር';

  @override
  String get changePhoneNumberNotImplementedMessage => 'ስልክ ቁጥር ለመቀየር ተነክቷል (አልተተገበረም)';

  @override
  String get accountPasswordLabel => 'የይለፍ ቃል';

  @override
  String get changePasswordNotImplementedMessage => 'የይለፍ ቃል ለመቀየር ተነክቷል (አልተተገበረም)';

  @override
  String get notificationsEnabledMessage => 'ማሳወቂያዎች ነቅተዋል';

  @override
  String get notificationsDisabledMessage => 'ማሳወቂያዎች ቆመዋል';

  @override
  String get changeButton => 'ቀይር';

  @override
  String get phoneNumberCannotBeEmptyError => 'ስልክ ቁጥር ባዶ መሆን አይችልም።';

  @override
  String get invalidPhoneNumberFormatError => 'የማያገለግል የስልክ ቁጥር ዓይነት። እባክዎ 09...፣ 9...፣ ወይም +2519... ይጠቀሙ።';

  @override
  String get registrationSuccessMessage => 'ምዝገባው ተሳክቷል! እባክዎ የአስተዳዳሪ ማረጋገጫ ይጠብቁ።';

  @override
  String get registrationFailedDefaultMessage => 'ምዝገባ አልተሳካም። እባክዎ እንደገና ይሞክሩ።';

  @override
  String get selectDepartmentHint => 'ዲፓርትመንት / የትምህርት መስክ ይምረጡ';

  @override
  String get yearLabel => 'የትምህርት ዘመን';

  @override
  String get yearValidationErrorEmpty => 'እባክዎ ዓመት ያስገቡ።';

  @override
  String get yearValidationErrorInvalid => 'እባክዎ ትክክለኛ ዓመት ያስገቡ።';

  @override
  String get departmentLabel => 'ዲፓርትመንት';

  @override
  String get pleaseSelectDepartmentError => 'እባክዎ ዲፓርትመንት ይምረጡ።';

  @override
  String get selectYearHint => 'ዓመት ይምረጡ';

  @override
  String get pleaseSelectYearError => 'እባክዎ የትምህርት ዘመንዎን ይምረጡ።';

  @override
  String get guestUser => 'እንግዳ ተጠቃሚ';

  @override
  String get pleaseLoginOrRegister => 'እባክዎ ይግቡ ወይም ይመዝገቡ';

  @override
  String get registeredUser => 'የተመዘገበ ተጠቃሚ';

  @override
  String get logoutSuccess => 'በተሳካ ሁኔታ ወጥተዋል።';

  @override
  String get selectSemesterLabel => 'ሴሚስተር ይምረጡ';

  @override
  String get selectSemesterHint => 'ሴሚስተር ይምረጡ';

  @override
  String get pleaseSelectSemesterError => 'እባክዎ ሴሚስተር ይምረጡ።';

  @override
  String get deviceInfoNotAvailable => 'የመሳሪያ መረጃ የለም። እባክዎ ይጠብቁና እንደገና ይሞክሩ።';

  @override
  String get deviceInfoProcessing => 'የመሳሪያ መረጃ አሁንም እየተሰራ ነው። እባክዎ ትንሽ ቆይተው እንደገና ይሞክሩ።';

  @override
  String get deviceInfoInitializing => 'በማስጀመር ላይ... እባክዎ እንደገና ለመግባት ይሞክሩ።';

  @override
  String get deviceInfoProceedingDefault => 'የመሳሪያውን መረጃ ሙሉ በሙሉ ማወቅ አልተቻለም። ባለው መረጃ እንቀጥላለን።';

  @override
  String get initializing => 'በማስጀመር ላይ...';

  @override
  String enrollForSemesterTitle(String semesterName) {
    return 'ለ $semesterName ይመዝገቡ';
  }

  @override
  String get selectedSemesterLabel => 'የተመረጠ ሴሚስተር:';

  @override
  String get priceLabel => 'ዋጋ:';

  @override
  String get coursesIncludedLabel => 'የተካተቱ ኮርሶች:';

  @override
  String get bankNamePaymentLabel => 'የከፈሉበት ባንክ ስም';

  @override
  String get bankNamePaymentHint => 'ለምሳሌ፡ የኢትዮጵያ ንግድ ባንክ፣ አዋሽ ባንክ';

  @override
  String get bankNameValidationError => 'እባክዎ የባንክ ስም ያስገቡ።';

  @override
  String get enrollmentRequestSuccess => 'የምዝገባ ጥያቄዎ በተሳካ ሁኔታ ገብቷል! እባክዎ ይሁንታ ይጠብቁ።';

  @override
  String get enrollmentRequestFailed => 'የምዝገባ ጥያቄ ማስገባት አልተሳካም።';

  @override
  String get selectPaymentBankPrompt => 'እባክዎ የክፍያ ባንክ ይምረጡ።';

  @override
  String get goBackButton => 'ተመለስ';

  @override
  String get createPostTitle => 'አዲስ ልጥፍ ፍጠር';

  @override
  String get postTitleLabel => 'የልጥፍ ርዕስ';

  @override
  String get postTitleHint => 'ግልጽ እና አጭር ርዕስ ያስገቡ';

  @override
  String get postTitleValidationRequired => 'እባክዎ ርዕስ ያስገቡ።';

  @override
  String get postTitleValidationLength => 'ርዕስ ቢያንስ 5 ቁምፊዎች መሆን አለበት።';

  @override
  String get postDescriptionLabel => 'የልጥፍ መግለጫ';

  @override
  String get postDescriptionHint => 'ሀሳቦችዎን ወይም ጥያቄዎችዎን በዝርዝር ያጋሩ...';

  @override
  String get postDescriptionValidationRequired => 'እባክዎ መግለጫ ያስገቡ።';

  @override
  String get postDescriptionValidationLength => 'መግለጫ ቢያንስ 10 ቁምፊዎች መሆን አለበት።';

  @override
  String get submitPostButton => 'ልጥፍ አስገባ';

  @override
  String get postCreatedSuccess => 'ልጥፍ በተሳካ ሁኔታ ተፈጥሯል!';

  @override
  String get postCreateFailed => 'ልጥፍ መፍጠር አልተሳካም። እባክዎ እንደገና ይሞክሩ።';

  @override
  String get editPostTitle => 'ልጥፍ አስተካክል';

  @override
  String get generalTitleLabel => 'ርዕስ';

  @override
  String get generalTitleEmptyValidation => 'ርዕስ ባዶ መሆን አይችልም';

  @override
  String get generalDescriptionLabel => 'መግለጫ';

  @override
  String get generalDescriptionEmptyValidation => 'መግለጫ ባዶ መሆን አይችልም';

  @override
  String get cancelButton => 'ሰርዝ';

  @override
  String get saveButton => 'አስቀምጥ';

  @override
  String get postUpdatedSuccess => 'ልጥፍ ተዘምኗል!';

  @override
  String get postUpdateFailed => 'ልጥፍ ማዘመን አልተሳካም።';

  @override
  String get deletePostTitle => 'ልጥፍ ሰርዝ';

  @override
  String get deletePostConfirmation => 'ይህንን ልጥፍ እና ሁሉንም አስተያየቶቹን መሰረዝ እርግጠኛ ነዎት? ይህ ድርጊት ሊቀለበስ አይችልም።';

  @override
  String get deleteButton => 'ሰርዝ';

  @override
  String get postDeletedSuccess => 'ልጥፍ በተሳካ ሁኔታ ተሰርዟል!';

  @override
  String get postDeleteFailed => 'ልጥፍ መሰረዝ አልተሳካም።';

  @override
  String get commentPostedSuccess => 'አስተያየት ተለጥፏል!';

  @override
  String get commentPostFailed => 'አስተያየት መለጠፍ አልተሳካም።';

  @override
  String get replyPostedSuccess => 'መልስ ተለጥፏል!';

  @override
  String get replyPostFailed => 'መልስ መለጠፍ አልተሳካም።';

  @override
  String get updateGenericSuccess => 'ዝማኔው ተሳክቷል!';

  @override
  String get updateGenericFailed => 'ዝማኔው አልተሳካም።';

  @override
  String get deleteCommentTitle => 'አስተያየት ሰርዝ';

  @override
  String get deleteReplyTitle => 'መልስ ሰርዝ';

  @override
  String deleteItemConfirmation(String itemType) {
    return 'ይህንን $itemType መሰረዝ እርግጠኛ ነዎት? ይህ ድርጊት ሊቀለበስ አይችልም።';
  }

  @override
  String itemDeletedSuccess(String itemType) {
    return '$itemType በተሳካ ሁኔታ ተሰርዟል!';
  }

  @override
  String itemDeleteFailed(String itemType) {
    return '$itemType መሰረዝ አልተሳካም።';
  }

  @override
  String get commentsSectionHeader => 'አስተያየቶች';

  @override
  String get noCommentsYet => 'ምንም አስተያየቶች የሉም። የመጀመሪያ ይሁኑ!';

  @override
  String get writeCommentHint => 'አስተያየት ይጻፉ...';

  @override
  String get commentValidationEmpty => 'አስተያየት ባዶ መሆን አይችልም።';

  @override
  String get postCommentTooltip => 'አስተያየት ለጥፍ';

  @override
  String get replyButtonLabel => 'መልስ';

  @override
  String get cancelReplyButtonLabel => 'ሰርዝ';

  @override
  String get writeReplyHint => 'መልስ ይጻፉ...';

  @override
  String get replyValidationEmpty => 'መልስ ባዶ መሆን አይችልም።';

  @override
  String get editFieldValidationEmpty => 'ባዶ መሆን አይችልም';

  @override
  String get saveChangesButton => 'ለውጦችን አስቀምጥ';

  @override
  String viewAllReplies(String replyCount) {
    return 'ሁሉንም $replyCount መልሶች ይመልከቱ...';
  }

  @override
  String get commentItemDisplay => 'አስተያየት';

  @override
  String get replyItemDisplay => 'መልስ';

  @override
  String get darkModeLabel => 'ጨለማ ገፅታ';

  @override
  String get darkModeSubtitle => 'የጨለማ ገፅታን አንቃ ወይም አሰናክል';

  @override
  String get receiveNotificationsSubtitle => 'ጠቃሚ ዝመናዎችን ተቀበል';

  @override
  String get pushNotificationsEnabled => 'ማሳወቂያዎች ነቅተዋል';

  @override
  String get pushNotificationsDisabled => 'ማሳወቂያዎች ቆመዋል';

  @override
  String get viewPrivacyPolicyAction => 'የግላዊነት ፖሊሲ ይመልከቱ';

  @override
  String get viewTermsAction => 'የአገልግሎት ውሎችን ይመልከቱ';

  @override
  String actionNotImplemented(String featureName) {
    return '$featureName: ገና አልተተገበረም';
  }

  @override
  String couldNotLaunchUrl(String urlString) {
    return '$urlString መክፈት አልተቻለም።';
  }

  @override
  String get shareAppSubject => 'መጂወ አስጠኚ መተግበሪያ';

  @override
  String get emailSupportSubject => 'የመተግበሪያ ድጋፍ ጥያቄ';

  @override
  String get contactViaEmail => 'በኢሜል ያግኙን';

  @override
  String get callUs => 'ይደውሉልን';

  @override
  String get visitOurWebsite => 'ድረገጻችንን ይጎብኙ';

  @override
  String get refreshingData => 'ዳታ እየታደሰ ነው...';

  @override
  String get dataRefreshed => 'ዳታ ታድሷል!';

  @override
  String get errorRefreshingData => 'ዳታ በማደስ ላይ ስህተት ተፈጥሯል። እባክዎ የበይነመረብ ግንኙነትዎን ያረጋግጡ።';

  @override
  String get notesSectionTitle => 'ማስታወሻዎች';

  @override
  String get notesSectionDescription => 'ከአገር ዙሪያ ከተማሪዎች የሰበሰብናቸው ማስታወሻዎች።';

  @override
  String get notesComingSoon => 'የማስታወሻዎች ክፍል በቅርቡ ይመጣል!';

  @override
  String get coursesDetailsComingSoon => 'የኮርስ ዝርዝሮች በቅርቡ ይመጣሉ።';

  @override
  String semesterCardTapped(String semesterName, String semesterId) {
    return '$semesterName (ID: $semesterId) ተነክቷል';
  }

  @override
  String get enrollNowButton => 'አሁን ይመዝገቡ';

  @override
  String get currencySymbol => 'ብር';

  @override
  String get submitEnrollmentRequestButton => 'የምዝገባ ጥያቄ አስገባ';

  @override
  String get currentPasswordLabel => 'የአሁኑ የይለፍ ቃል';

  @override
  String get newPasswordLabel => 'አዲስ የይለፍ ቃል';

  @override
  String get confirmNewPasswordLabel => 'አዲስ የይለፍ ቃል አረጋግጥ';

  @override
  String get passwordsDoNotMatch => 'የይለፍ ቃሎች አይዛመዱም';

  @override
  String get newPhoneNumberLabel => 'አዲስ ስልክ ቁጥር';

  @override
  String get otpEnterPrompt => 'OTP ያስገቡ';

  @override
  String get otpValidationErrorRequired => 'እባክዎ OTP ያስገቡ';

  @override
  String get otpValidationErrorLength => 'OTP 6 አሃዝ መሆን አለበት';

  @override
  String get otpNewPhoneSameAsCurrentError => 'አዲስ ስልክ ቁጥር ከአሁኑ ጋር አንድ መሆን የለበትም';

  @override
  String get otpRequestButton => 'OTP ጠይቅ';

  @override
  String get otpVerifyButton => 'OTP አረጋግጥ';

  @override
  String get passwordChangedSuccess => 'የይለፍ ቃል በተሳካ ሁኔታ ተቀይሯል!';

  @override
  String get passwordChangeFailed => 'የይለፍ ቃል መቀየር አልተሳካም።';

  @override
  String get otpSentSuccess => 'OTP በተሳካ ሁኔታ ተልኳል።';

  @override
  String get otpRequestFailed => 'OTP መጠየቅ አልተሳካም።';

  @override
  String get phoneUpdateSuccess => 'ስልክ ቁጥር በተሳካ ሁኔታ ተዘምኗል።';

  @override
  String get phoneUpdateFailed => 'ስልክ ቁጥር ማዘመን አልተሳካም።';

  @override
  String get videoItemType => 'ቪዲዮ';

  @override
  String get documentItemType => 'ሰነድ';

  @override
  String get quizItemType => 'ፈተና';

  @override
  String get textItemType => 'ጽሑፍ';

  @override
  String get unknownItemType => 'ይዘት';

  @override
  String get noVideosAvailable => 'ምንም ቪዲዮዎች የሉም።';

  @override
  String get noDocumentsAvailable => 'ምንም ሰነዶች የሉም።';

  @override
  String get noTextLessonsAvailable => 'ምንም የጽሑፍ ትምህርቶች የሉም።';

  @override
  String get noQuizzesAvailable => 'ምንም ፈተናዎች የሉም።';

  @override
  String itemNotAvailable(String contentType) {
    return '$contentType የለም።';
  }

  @override
  String couldNotLaunchItem(String urlString) {
    return '$urlString መክፈት አልተቻለም';
  }

  @override
  String noLaunchableContent(String itemName) {
    return 'ለ $itemName ምንም ሊከፈት የሚችል ይዘት የለም';
  }

  @override
  String get chaptersTitle => 'ምዕራፎች';

  @override
  String failedToLoadChaptersError(String error) {
    return 'ምዕራፎችን መጫን አልተሳካም።\n$error';
  }

  @override
  String get noChaptersForCourse => 'ለዚህ ኮርስ ምንም ምዕራፎች አልተገኙም።';

  @override
  String failedToLoadLessonsError(String error) {
    return 'ትምህርቶችን መጫን አልተሳካም።\n$error';
  }

  @override
  String get noLessonsInChapter => 'በዚህ ምዕራፍ ምንም ትምህርቶች የሉም።';

  @override
  String get noCoursesAvailable => 'በአሁኑ ሰዓት ምንም ኮርሶች የሉም።';

  @override
  String get shareYourTestimonialTitle => 'ምስክርነትዎን ያጋሩ';

  @override
  String get titleLabel => 'ርዕስ';

  @override
  String get titleValidationPrompt => 'እባክዎ ርዕስ ያስገቡ';

  @override
  String get yourExperienceLabel => 'የእርስዎ ተሞክሮ';

  @override
  String get experienceValidationPrompt => 'እባክዎ ተሞክሮዎን ይግለጹ';

  @override
  String get submitButtonGeneral => 'አስገባ';

  @override
  String get testimonialSubmittedSuccess => 'ምስክርነት ገብቷል! ከማረጋገጫ በኋላ ይታያል።';
}
