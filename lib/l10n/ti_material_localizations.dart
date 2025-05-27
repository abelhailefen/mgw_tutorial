// lib/l10n/ti_material_localizations.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class _TiMaterialLocalizations extends DefaultMaterialLocalizations {
  const _TiMaterialLocalizations();

  @override String get moreButtonTooltip => r'ተወሳኺ';
  @override String get aboutListTileTitleRaw => r'ብዛዕባ $applicationName';
  @override String get alertDialogLabel => r'ማሳወቂያ'; // Tigrinya for Alert/Notification
  @override String get anteMeridiemAbbreviation => r'ቅ.ቀ'; // Before noon
  @override String get backButtonTooltip => r'ተመለስ';
  @override String get cancelButtonLabel => r'ሰርዝ';
  @override String get closeButtonLabel => r'ዕጾ';
  @override String get closeButtonTooltip => r'ዕጾ';
  @override String get collapsedIconTapHint => r'ዘርጋሕ'; // Expand
  @override String get continueButtonLabel => r'ቀጽል';
  @override String get copyButtonLabel => r'ቅዳሕ';
  @override String get cutButtonLabel => r'ቁረጽ';
  @override String get deleteButtonTooltip => r'ሰርዝ';
  @override String get dialogLabel => r'ዲያሎግ'; // Dialog
  @override String get drawerLabel => r'ናይ ዳህሳስ ሜኑ'; // Navigation Drawer
  @override String get expandedIconTapHint => r'ዕጸፍ'; // Collapse
  @override String get firstPageTooltip => r'ቀዳማይ ገጽ';
  @override String get hideAccountsLabel => r'ሕሳባት ደብቕ'; // Hide accounts
  @override String get lastPageTooltip => r'ናይ መወዳእታ ገጽ';
  @override String get licensesPageTitle => r'ፍቓዳት'; // Licenses
  @override String get modalBarrierDismissLabel => r'ኣሰናብት'; // Dismiss
  @override String get nextMonthTooltip => r'ዝቕጽል ወርሒ';
  @override String get nextPageTooltip => r'ዝቕጽል ገጽ';
  @override String get okButtonLabel => r'ሕራይ'; // OK
  @override String get openAppDrawerTooltip => r'ናይ ዳህሳስ ሜኑ ክፈት'; // Open navigation drawer
  @override String get pageRowsInfoTitleRaw => r'$firstRow–$lastRow ካብ $rowCount';
  @override String get pageRowsInfoTitleApproximateRaw => r'$firstRow–$lastRow ካብ ኣስታት $rowCount'; // Approx count
  @override String get pasteButtonLabel => r'ለጥፍ'; // Paste
  @override String get popupMenuLabel => r'ፖፕኣፕ ሜኑ'; // Popup menu
  @override String get postMeridiemAbbreviation => r'ድ.ቀ'; // After noon
  @override String get previousMonthTooltip => r'ዝሓለፈ ወርሒ';
  @override String get previousPageTooltip => r'ዝሓለፈ ገጽ';
  @override String get refreshIndicatorSemanticLabel => r'ኣሕድስ'; // Refresh
  // Note: Pluralization rules can be complex. Using a simple form for 'other'/'few'/'many'.
  @override String get remainingTextFieldCharacterCountFew => r'$remainingCount ፊደላት ተሪፎም';
  @override String get remainingTextFieldCharacterCountMany => r'$remainingCount ፊደላት ተሪፎም';
  @override String get remainingTextFieldCharacterCountOne => r'1 ፊደል ተሪፉ';
  @override String get remainingTextFieldCharacterCountOther => r'$remainingCount ፊደላት ተሪፎም';
  @override String get remainingTextFieldCharacterCountTwo => r'$remainingCount ፊደላት ተሪፎም';
  @override String get remainingTextFieldCharacterCountZero => r'ምንም ፊደል ኣይተረፈን';
  @override String get reorderItemDown => r'ንታሕቲ ኣግዕዝ'; // Move down
  @override String get reorderItemLeft => r'ንጸጋም ኣግዕዝ'; // Move left
  @override String get reorderItemRight => r'ንየማን ኣግዕዝ'; // Move right
  @override String get reorderItemToEnd => r'ናብ መወዳእታ ኣግዕዝ'; // Move to end
  @override String get reorderItemToStart => r'ናብ መጀመርታ ኣግዕዝ'; // Move to start
  @override String get reorderItemUp => r'ንላዕሊ ኣግዕዝ'; // Move up
  @override String get rowsPerPageTitle => r'ረድፍታት ኣብ ገጽ:'; // Rows per page
  @override String get saveButtonLabel => r'ኣቐምጥ'; // Save
  @override ScriptCategory get scriptCategory => ScriptCategory.tall; // Ge'ez is a tall script
  @override String get searchFieldLabel => r'ድለ'; // Search
  @override String get selectAllButtonLabel => r'ኩሉ ምረጽ'; // Select all
   // Note: Pluralization rules can be complex. Using a simple form.
  @override String get selectedRowCountTitleFew => r'$selectedRowCount ኣካላት ተመሪጾም'; // Items selected
  @override String get selectedRowCountTitleMany => r'$selectedRowCount ኣካላት ተመሪጾም';
  @override String get selectedRowCountTitleOne => r'1 ኣካል ተመሪጹ'; // 1 item selected
  @override String get selectedRowCountTitleOther => r'$selectedRowCount ኣካላት ተመሪጾም';
  @override String get selectedRowCountTitleTwo => r'$selectedRowCount ኣካላት ተመሪጾም';
  @override String get selectedRowCountTitleZero => r'ምንም ኣይተመርጸን'; // No items selected
  @override String get showAccountsLabel => r'ሕሳባት ኣርኢ'; // Show accounts
  @override String get showMenuTooltip => r'ሜኑ ኣርኢ'; // Show menu
  @override String get signedInLabel => r'ኣቲኻ ኣለኻ'; // Signed in
  @override String get tabLabelRaw => r'ታብ $tabIndex ካብ $tabCount'; // Tab X of Y
  @override TimeOfDayFormat get timeOfDayFormatRaw => TimeOfDayFormat.h_colon_mm_space_a; // e.g., 1:30 AM/PM
  @override String get timePickerHourModeAnnouncement => r'ሰዓታት ምረጽ'; // Select hours
  @override String get timePickerMinuteModeAnnouncement => r'ደቓይቕ ምረጽ'; // Select minutes
  @override String get viewLicensesButtonLabel => r'ፍቓዳት ርአ'; // View licenses

  // Add translations for other necessary strings as needed, or leave as default/English if not critical.
  // Here are a few more commonly overridden ones, translated:
  @override String get buffetRowsInfoTitleRaw => r'${rows.length} ${(rows.length == 1) ? "ኣካል" : "ኣካላት"}'; // X item(s)
  @override String get clearButtonTooltip => r'ኣጥሪ'; // Clear
  @override String get selectedDateOutOfRangeLabel => r'ካብ ክልል ወጻኢ'; // Out of range

  // Keyboard keys - often left in English or simple characters.
  // You can translate these if needed, but keeping English is common.
  // For simplicity, I'll keep English names for special keys or use common symbols.
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
  @override String get keyboardKeyNumpad0 => r'0';
  @override String get keyboardKeyNumpad1 => r'1';
  @override String get keyboardKeyNumpad2 => r'2';
  @override String get keyboardKeyNumpad3 => r'3';
  @override String get keyboardKeyNumpad4 => r'4';
  @override String get keyboardKeyNumpad5 => r'5';
  @override String get keyboardKeyNumpad6 => r'6';
  @override String get keyboardKeyNumpad7 => r'7';
  @override String get keyboardKeyNumpad8 => r'8';
  @override String get keyboardKeyNumpad9 => r'9';
  @override String get keyboardKeyNumpadAdd => r'+';
  @override String get keyboardKeyNumpadComma => r',';
  @override String get keyboardKeyNumpadDecimal => r'.';
  @override String get keyboardKeyNumpadDivide => r'/';
  @override String get keyboardKeyNumpadEnter => r'Enter';
  @override String get keyboardKeyNumpadEqual => r'=';
  @override String get keyboardKeyNumpadMultiply => r'*';
  @override String get keyboardKeyNumpadParenLeft => r'(';
  @override String get keyboardKeyNumpadParenRight => r')';
  @override String get keyboardKeyNumpadSubtract => r'-';
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

class TiMaterialLocalizationsDelegate extends LocalizationsDelegate<MaterialLocalizations> {
  const TiMaterialLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'ti'; // Supports Tigrigna

  @override
  Future<MaterialLocalizations> load(Locale locale) {
    // Return a SynchronousFuture here because the data is already loaded.
    return SynchronousFuture<MaterialLocalizations>(const _TiMaterialLocalizations());
  }

  @override
  bool shouldReload(TiMaterialLocalizationsDelegate old) => false;

  @override
  String toString() => 'TiMaterialLocalizations.delegate(ti)';
}