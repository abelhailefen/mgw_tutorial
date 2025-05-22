// lib/l10n/ti_material_localizations.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

// --- Amharic Material Localizations (for placeholders) ---
// These are sourced from Flutter's material_am.arb
// You will replace these with Tigrinya translations.
const _AmMaterialLocalizations amPlaceholders = _AmMaterialLocalizations();

class _AmMaterialLocalizations extends DefaultMaterialLocalizations {
  const _AmMaterialLocalizations();

  @override String get alertDialogLabel => r'ማንቂያ';
  @override String get anteMeridiemAbbreviation => r'ጥዋት';
  @override String get backButtonTooltip => r'ተመለስ';
  @override String get cancelButtonLabel => r'ሰርዝ';
  @override String get closeButtonLabel => r'ዝጋ';
  @override String get closeButtonTooltip => r'ዝጋ';
  @override String get collapsedIconTapHint => r'ዘርጋ';
  @override String get continueButtonLabel => r'ቀጥል';
  @override String get copyButtonLabel => r'ቅዳ';
  @override String get cutButtonLabel => r'ቁረጥ';
  @override String get deleteButtonTooltip => r'ሰርዝ';
  @override String get dialogLabel => r'መገናኛ';
  @override String get drawerLabel => r'የዳሰሳ ምናሌ';
  @override String get expandedIconTapHint => r'ሰብስብ';
  @override String get firstPageTooltip => r'የመጀመሪያ ገጽ';
  @override String get hideAccountsLabel => r'መለያዎችን ደብቅ';
  @override String get lastPageTooltip => r'የመጨረሻ ገጽ';
  @override String get licensesPageTitle => r'ፈቃዶች';
  @override String get modalBarrierDismissLabel => r'አሰናብት';
  @override String get nextMonthTooltip => r'የሚቀጥለው ወር';
  @override String get nextPageTooltip => r'ቀጣይ ገጽ';
  @override String get okButtonLabel => r'እሺ';
  @override String get openAppDrawerTooltip => r'የዳሰሳ ምናሌን ክፈት';
  @override String get pageRowsInfoTitleRaw => r'$firstRow–$lastRow ከ$rowCount';
  @override String get pageRowsInfoTitleApproximateRaw => r'$firstRow–$lastRow ከ ገደማ $rowCount';
  @override String get pasteButtonLabel => r'ለጥፍ';
  @override String get popupMenuLabel => r'የብቅ-ባይ ምናሌ';
  @override String get postMeridiemAbbreviation => r'ከሰዓት';
  @override String get previousMonthTooltip => r'ያለፈው ወር';
  @override String get previousPageTooltip => r'ያለፈው ገጽ';
  @override String get refreshIndicatorSemanticLabel => r'አድስ';
  @override String get remainingTextFieldCharacterCountFew => r'$remainingCount ሆሄያት ቀርተዋል';
  @override String get remainingTextFieldCharacterCountMany => r'$remainingCount ሆሄያት ቀርተዋል';
  @override String get remainingTextFieldCharacterCountOne => r'1 ሆሄ ቀርቷል';
  @override String get remainingTextFieldCharacterCountOther => r'$remainingCount ሆሄያት ቀርተዋል';
  @override String get remainingTextFieldCharacterCountTwo => r'$remainingCount ሆሄያት ቀርተዋል';
  @override String get remainingTextFieldCharacterCountZero => r'ምንም ሆሄ አልቀረም';
  @override String get reorderItemDown => r'ወደታች ውሰድ';
  @override String get reorderItemLeft => r'ወደ ግራ ውሰድ';
  @override String get reorderItemRight => r'ወደ ቀኝ ውሰድ';
  @override String get reorderItemToEnd => r'ወደ መጨረሻ ውሰድ';
  @override String get reorderItemToStart => r'ወደ መጀመሪያ ውሰድ';
  @override String get reorderItemUp => r'ወደላይ ውሰድ';
  @override String get rowsPerPageTitle => r'በገጽ ያሉ ረድፎች፦';
  @override String get saveButtonLabel => r'አስቀምጥ';
  @override ScriptCategory get scriptCategory => ScriptCategory.tall;
  @override String get searchFieldLabel => r'ፈልግ';
  @override String get selectAllButtonLabel => r'ሁሉንም ምረጥ';
  @override String get selectedRowCountTitleFew => r'$selectedRowCount ንጥሎች ተመርጠዋል';
  @override String get selectedRowCountTitleMany => r'$selectedRowCount ንጥሎች ተመርጠዋል';
  @override String get selectedRowCountTitleOne => r'1 ንጥል ተመርጧል';
  @override String get selectedRowCountTitleOther => r'$selectedRowCount ንጥሎች ተመርጠዋል';
  @override String get selectedRowCountTitleTwo => r'$selectedRowCount ንጥሎች ተመርጠዋል';
  @override String get selectedRowCountTitleZero => r'ምንም ንጥል አልተመረጠም';
  @override String get showAccountsLabel => r'መለያዎችን አሳይ';
  @override String get showMenuTooltip => r'ምናሌን አሳይ';
  @override String get signedInLabel => r'በመለያ ገብተዋል';
  @override String get tabLabelRaw => r'ትር $tabIndex ከ$tabCount';
  @override TimeOfDayFormat get timeOfDayFormatRaw => TimeOfDayFormat.H_colon_mm;
  @override String get timePickerHourModeAnnouncement => r'ሰዓቶችን ይምረጡ';
  @override String get timePickerMinuteModeAnnouncement => r'ደቂቃዎችን ይምረጡ';
  @override String get viewLicensesButtonLabel => r'ፈቃዶችን ይመልከቱ';
  @override String get moreButtonTooltip => r'ተጨማሪ';
  @override String get aboutListTileTitleRaw => r'$applicationName बारे में'; // This seems like Hindi placeholder in Amharic file, using generic English
  @override String get buffetRowsInfoTitleRaw => r'${rows.length} ${(rows.length == 1) ? "ንጥል" : "ንጥሎች"}';
  @override String get clearButtonTooltip => r'አጥራ';
  @override String get selectedDateOutOfRangeLabel => r'ከክልል ውጪ';
  // For keyboard keys, it's often fine to use English defaults or simple characters
  @override String get keyboardKeyAlt => r'Alt';
  @override String get keyboardKeyAltGraph => r'AltGr';
  @override String get keyboardKeyBackspace => r'Backspace';
  @override String get keyboardKeyCapsLock => r'Caps Lock';
  @override String get keyboardKeyChannelDown => r'Channel Down';
  @override String get keyboardKeyChannelUp => r'Channel Up';
  @override String get keyboardKeyControl => r'Ctrl';
  @override String get keyboardKeyDelete => r'Del';
  @override String get keyboardKeyEject => r'Eject';
  @override String get keyboardKeyEnd => r'End';
  @override String get keyboardKeyEscape => r'Esc';
  @override String get keyboardKeyFn => r'Fn';
  @override String get keyboardKeyHome => r'Home';
  @override String get keyboardKeyInsert => r'Insert';
  @override String get keyboardKeyMeta => r'Meta';
  @override String get keyboardKeyMetaMacOs => r'Command';
  @override String get keyboardKeyMetaWindows => r'Win';
  @override String get keyboardKeyNumLock => r'Num Lock';
  @override String get keyboardKeyNumpad0 => r'Num 0';
  @override String get keyboardKeyNumpad1 => r'Num 1';
  @override String get keyboardKeyNumpad2 => r'Num 2';
  @override String get keyboardKeyNumpad3 => r'Num 3';
  @override String get keyboardKeyNumpad4 => r'Num 4';
  @override String get keyboardKeyNumpad5 => r'Num 5';
  @override String get keyboardKeyNumpad6 => r'Num 6';
  @override String get keyboardKeyNumpad7 => r'Num 7';
  @override String get keyboardKeyNumpad8 => r'Num 8';
  @override String get keyboardKeyNumpad9 => r'Num 9';
  @override String get keyboardKeyNumpadAdd => r'Num +';
  @override String get keyboardKeyNumpadComma => r'Num ,';
  @override String get keyboardKeyNumpadDecimal => r'Num .';
  @override String get keyboardKeyNumpadDivide => r'Num /';
  @override String get keyboardKeyNumpadEnter => r'Num Enter';
  @override String get keyboardKeyNumpadEqual => r'Num =';
  @override String get keyboardKeyNumpadMultiply => r'Num *';
  @override String get keyboardKeyNumpadParenLeft => r'Num (';
  @override String get keyboardKeyNumpadParenRight => r'Num )';
  @override String get keyboardKeyNumpadSubtract => r'Num -';
  @override String get keyboardKeyPageDown => r'Page Down';
  @override String get keyboardKeyPageUp => r'Page Up';
  @override String get keyboardKeyPower => r'Power';
  @override String get keyboardKeyPowerOff => r'Power Off';
  @override String get keyboardKeyPrintScreen => r'Print Screen';
  @override String get keyboardKeyScrollLock => r'Scroll Lock';
  @override String get keyboardKeySelect => r'Select';
  @override String get keyboardKeyShift => r'Shift';
  @override String get keyboardKeySpace => r'Space';
}

// --- Tigrinya Material Localizations ---
// TODO_TI: Translate all Amharic placeholders below to Tigrinya
class _TiMaterialLocalizations extends DefaultMaterialLocalizations {
  const _TiMaterialLocalizations();

  @override String get moreButtonTooltip => r'ተወሳኺ'; // Example: Tigrinya for "More"
  @override String get aboutListTileTitleRaw => r'ብዛዕባ $applicationName'; // Example: 'ስለ $applicationName' (AM)
  @override String get alertDialogLabel => r' መጠንቀቕታ'; // Example: 'ማንቂያ' (AM)
  @override String get anteMeridiemAbbreviation => r'ቅ.ቀትሪ'; // 'ጥዋት' (AM)
  @override String get backButtonTooltip => r'ተመለስ'; // 'ተመለስ' (AM)
  @override String get cancelButtonLabel => r'ሰርዝ'; // 'ሰርዝ' (AM)
  @override String get closeButtonLabel => r'ዕጾ'; // 'ዝጋ' (AM)
  @override String get closeButtonTooltip => r'ዕጾ'; // 'ዝጋ' (AM)
  @override String get collapsedIconTapHint => r'ኣስፍሕ'; // 'ዘርጋ' (AM)
  @override String get continueButtonLabel => r'ቐጽል'; // 'ቀጥል' (AM)
  @override String get copyButtonLabel => r'ቅዳሕ'; // 'ቅዳ' (AM)
  @override String get cutButtonLabel => r'ቁረጽ'; // 'ቁረጥ' (AM)
  @override String get deleteButtonTooltip => r'ሰርዝ'; // 'ሰርዝ' (AM)
  @override String get dialogLabel => r'ዝርርብ'; // 'መገናኛ' (AM)
  @override String get drawerLabel => r'ናይ ዳህሳስ ሜኑ'; // 'የዳሰሳ ምናሌ' (AM)
  @override String get expandedIconTapHint => r'ጠቕልል'; // 'ሰብስብ' (AM)
  @override String get firstPageTooltip => r'ቀዳማይ ገጽ'; // 'የመጀመሪያ ገጽ' (AM)
  @override String get hideAccountsLabel => r'ሕሳባት ደብቕ'; // 'መለያዎችን ደብቅ' (AM)
  @override String get lastPageTooltip => r'ናይ መወዳእታ ገጽ'; // 'የመጨረሻ ገጽ' (AM)
  @override String get licensesPageTitle => r'ፍቓዳት'; // 'ፈቃዶች' (AM)
  @override String get modalBarrierDismissLabel => r'ኣሰናብት'; // 'አሰናብት' (AM)
  @override String get nextMonthTooltip => r'ዝቕጽል ወርሒ'; // 'የሚቀጥለው ወር' (AM)
  @override String get nextPageTooltip => r'ዝቕጽል ገጽ'; // 'ቀጣይ ገጽ' (AM)
  @override String get okButtonLabel => r'ሕራይ'; // 'እሺ' (AM)
  @override String get openAppDrawerTooltip => r'ናይ ዳህሳስ ሜኑ ክፈት'; // 'የዳሰሳ ምናሌን ክፈት' (AM)
  @override String get pageRowsInfoTitleRaw => r'$firstRow–$lastRow ካብ $rowCount'; // '$firstRow–$lastRow ከ$rowCount' (AM)
  @override String get pageRowsInfoTitleApproximateRaw => r'$firstRow–$lastRow ካብ ኣስታት $rowCount'; // '$firstRow–$lastRow ከ ገደማ $rowCount' (AM)
  @override String get pasteButtonLabel => r'ለጥፍ'; // 'ለጥፍ' (AM)
  @override String get popupMenuLabel => r'ፖፕኣፕ ሜኑ'; // 'የብቅ-ባይ ምናሌ' (AM)
  @override String get postMeridiemAbbreviation => r'ድ.ቀትሪ'; // 'ከሰዓት' (AM)
  @override String get previousMonthTooltip => r'ዝሓለፈ ወርሒ'; // 'ያለፈው ወር' (AM)
  @override String get previousPageTooltip => r'ዝሓለፈ ገጽ'; // 'ያለፈው ገጽ' (AM)
  @override String get refreshIndicatorSemanticLabel => r'ሓድስ'; // 'አድስ' (AM)
  @override String get remainingTextFieldCharacterCountFew => r'$remainingCount ፊደላት ተሪፎም'; // '$remainingCount ሆሄያት ቀርተዋል' (AM) - Note: Pluralization rules might differ
  @override String get remainingTextFieldCharacterCountMany => r'$remainingCount ፊደላት ተሪፎም'; // '$remainingCount ሆሄያት ቀርተዋል' (AM)
  @override String get remainingTextFieldCharacterCountOne => r'1 ፊደል ተሪፉ'; // '1 ሆሄ ቀርቷል' (AM)
  @override String get remainingTextFieldCharacterCountOther => r'$remainingCount ፊደላት ተሪፎም'; // '$remainingCount ሆሄያት ቀርተዋል' (AM)
  @override String get remainingTextFieldCharacterCountTwo => r'$remainingCount ፊደላት ተሪፎም'; // '$remainingCount ሆሄያት ቀርተዋል' (AM)
  @override String get remainingTextFieldCharacterCountZero => r'ዝተረፈ ፊደል የለን'; // 'ምንም ሆሄ አልቀረም' (AM)
  @override String get reorderItemDown => r'ንታሕቲ ኣግዕዝ'; // 'ወደታች ውሰድ' (AM)
  @override String get reorderItemLeft => r'ንጸጋም ኣግዕዝ'; // 'ወደ ግራ ውሰድ' (AM)
  @override String get reorderItemRight => r'ንየማን ኣግዕዝ'; // 'ወደ ቀኝ ውሰድ' (AM)
  @override String get reorderItemToEnd => r'ናብ መወዳእታ ኣግዕዝ'; // 'ወደ መጨረሻ ውሰድ' (AM)
  @override String get reorderItemToStart => r'ናብ መጀመርታ ኣግዕዝ'; // 'ወደ መጀመሪያ ውሰድ' (AM)
  @override String get reorderItemUp => r'ንላዕሊ ኣግዕዝ'; // 'ወደላይ ውሰድ' (AM)
  @override String get rowsPerPageTitle => r'ረድፍታት ኣብ ገጽ:'; // 'በገጽ ያሉ ረድፎች፦' (AM)
  @override String get saveButtonLabel => r'ኣቐምጥ'; // 'አስቀምጥ' (AM)
  @override ScriptCategory get scriptCategory => ScriptCategory.tall; // Ge'ez is a tall script
  @override String get searchFieldLabel => r'ድለ'; // 'ፈልግ' (AM)
  @override String get selectAllButtonLabel => r'ኩሉ ምረጽ'; // 'ሁሉንም ምረጥ' (AM)
  @override String get selectedRowCountTitleFew => r'$selectedRowCount ኣካላት ተመሪጾም'; // '$selectedRowCount ንጥሎች ተመርጠዋል' (AM)
  @override String get selectedRowCountTitleMany => r'$selectedRowCount ኣካላት ተመሪጾም'; // '$selectedRowCount ንጥሎች ተመርጠዋል' (AM)
  @override String get selectedRowCountTitleOne => r'1 ኣካል ተመሪጹ'; // '1 ንጥል ተመርጧል' (AM)
  @override String get selectedRowCountTitleOther => r'$selectedRowCount ኣካላት ተመሪጾም'; // '$selectedRowCount ንጥሎች ተመርጠዋል' (AM)
  @override String get selectedRowCountTitleTwo => r'$selectedRowCount ኣካላት ተመሪጾም'; // '$selectedRowCount ንጥሎች ተመርጠዋል' (AM)
  @override String get selectedRowCountTitleZero => r'ምንም ኣይተመርጸን'; // 'ምንም ንጥል አልተመረጠም' (AM)
  @override String get showAccountsLabel => r'ሕሳባት ኣርኢ'; // 'መለያዎችን አሳይ' (AM)
  @override String get showMenuTooltip => r'ሜኑ ኣርኢ'; // 'ምናሌን አሳይ' (AM)
  @override String get signedInLabel => r'ኣቲኻ ኣለኻ'; // 'በመለያ ገብተዋል' (AM)
  @override String get tabLabelRaw => r'ታብ $tabIndex ካብ $tabCount'; // 'ትር $tabIndex ከ$tabCount' (AM)
  @override TimeOfDayFormat get timeOfDayFormatRaw => TimeOfDayFormat.h_colon_mm_space_a; // Match this with how Tigrinya time is usually displayed
  @override String get timePickerHourModeAnnouncement => r'ሰዓታት ምረጽ'; // 'ሰዓቶችን ይምረጡ' (AM)
  @override String get timePickerMinuteModeAnnouncement => r'ደቓይቕ ምረጽ'; // 'ደቂቃዎችን ይምረጡ' (AM)
  @override String get viewLicensesButtonLabel => r'ፍቓዳት ርአ'; // 'ፈቃዶችን ይመልከቱ' (AM)

  // For these, we'll use the Amharic placeholders for now.
  // TODO_TI: Translate these Amharic placeholders to Tigrinya
  @override String get buffetRowsInfoTitleRaw => amPlaceholders.buffetRowsInfoTitleRaw;
  @override String get clearButtonTooltip => amPlaceholders.clearButtonTooltip;
  @override String get selectedDateOutOfRangeLabel => amPlaceholders.selectedDateOutOfRangeLabel;

  // Keyboard keys can often remain in English or use simple character representations.
  // Using Amharic placeholders here for consistency, but English might be fine.
  // TODO_TI: Decide if these need Tigrinya specific versions or if Amharic/English is acceptable.
  @override String get keyboardKeyAlt => amPlaceholders.keyboardKeyAlt;
  @override String get keyboardKeyAltGraph => amPlaceholders.keyboardKeyAltGraph;
  @override String get keyboardKeyBackspace => amPlaceholders.keyboardKeyBackspace;
  @override String get keyboardKeyCapsLock => amPlaceholders.keyboardKeyCapsLock;
  @override String get keyboardKeyChannelDown => amPlaceholders.keyboardKeyChannelDown;
  @override String get keyboardKeyChannelUp => amPlaceholders.keyboardKeyChannelUp;
  @override String get keyboardKeyControl => amPlaceholders.keyboardKeyControl;
  @override String get keyboardKeyDelete => amPlaceholders.keyboardKeyDelete;
  @override String get keyboardKeyEject => amPlaceholders.keyboardKeyEject;
  @override String get keyboardKeyEnd => amPlaceholders.keyboardKeyEnd;
  @override String get keyboardKeyEscape => amPlaceholders.keyboardKeyEscape;
  @override String get keyboardKeyFn => amPlaceholders.keyboardKeyFn;
  @override String get keyboardKeyHome => amPlaceholders.keyboardKeyHome;
  @override String get keyboardKeyInsert => amPlaceholders.keyboardKeyInsert;
  @override String get keyboardKeyMeta => amPlaceholders.keyboardKeyMeta;
  @override String get keyboardKeyMetaMacOs => amPlaceholders.keyboardKeyMetaMacOs;
  @override String get keyboardKeyMetaWindows => amPlaceholders.keyboardKeyMetaWindows;
  @override String get keyboardKeyNumLock => amPlaceholders.keyboardKeyNumLock;
  @override String get keyboardKeyNumpad0 => amPlaceholders.keyboardKeyNumpad0;
  @override String get keyboardKeyNumpad1 => amPlaceholders.keyboardKeyNumpad1;
  @override String get keyboardKeyNumpad2 => amPlaceholders.keyboardKeyNumpad2;
  @override String get keyboardKeyNumpad3 => amPlaceholders.keyboardKeyNumpad3;
  @override String get keyboardKeyNumpad4 => amPlaceholders.keyboardKeyNumpad4;
  @override String get keyboardKeyNumpad5 => amPlaceholders.keyboardKeyNumpad5;
  @override String get keyboardKeyNumpad6 => amPlaceholders.keyboardKeyNumpad6;
  @override String get keyboardKeyNumpad7 => amPlaceholders.keyboardKeyNumpad7;
  @override String get keyboardKeyNumpad8 => amPlaceholders.keyboardKeyNumpad8;
  @override String get keyboardKeyNumpad9 => amPlaceholders.keyboardKeyNumpad9;
  @override String get keyboardKeyNumpadAdd => amPlaceholders.keyboardKeyNumpadAdd;
  @override String get keyboardKeyNumpadComma => amPlaceholders.keyboardKeyNumpadComma;
  @override String get keyboardKeyNumpadDecimal => amPlaceholders.keyboardKeyNumpadDecimal;
  @override String get keyboardKeyNumpadDivide => amPlaceholders.keyboardKeyNumpadDivide;
  @override String get keyboardKeyNumpadEnter => amPlaceholders.keyboardKeyNumpadEnter;
  @override String get keyboardKeyNumpadEqual => amPlaceholders.keyboardKeyNumpadEqual;
  @override String get keyboardKeyNumpadMultiply => amPlaceholders.keyboardKeyNumpadMultiply;
  @override String get keyboardKeyNumpadParenLeft => amPlaceholders.keyboardKeyNumpadParenLeft;
  @override String get keyboardKeyNumpadParenRight => amPlaceholders.keyboardKeyNumpadParenRight;
  @override String get keyboardKeyNumpadSubtract => amPlaceholders.keyboardKeyNumpadSubtract;
  @override String get keyboardKeyPageDown => amPlaceholders.keyboardKeyPageDown;
  @override String get keyboardKeyPageUp => amPlaceholders.keyboardKeyPageUp;
  @override String get keyboardKeyPower => amPlaceholders.keyboardKeyPower;
  @override String get keyboardKeyPowerOff => amPlaceholders.keyboardKeyPowerOff;
  @override String get keyboardKeyPrintScreen => amPlaceholders.keyboardKeyPrintScreen;
  @override String get keyboardKeyScrollLock => amPlaceholders.keyboardKeyScrollLock;
  @override String get keyboardKeySelect => amPlaceholders.keyboardKeySelect;
  @override String get keyboardKeyShift => amPlaceholders.keyboardKeyShift;
  @override String get keyboardKeySpace => amPlaceholders.keyboardKeySpace;
}

class TiMaterialLocalizationsDelegate extends LocalizationsDelegate<MaterialLocalizations> {
  const TiMaterialLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'ti';

  @override
  Future<MaterialLocalizations> load(Locale locale) {
    return SynchronousFuture<MaterialLocalizations>(const _TiMaterialLocalizations());
  }

  @override
  bool shouldReload(TiMaterialLocalizationsDelegate old) => false;

  @override
  String toString() => 'TiMaterialLocalizations.delegate(ti)';
}