# Localization (l10n) Protocol

## Overview
This project uses Flutter's built-in internationalization support with ARB (Application Resource Bundle) files. All user-facing strings must be localized to support both English and Portuguese.

## L10n Workflow Protocol

### 1. Before Adding Any User-Facing String

**ALWAYS** follow this checklist before implementing any UI text:

```dart
// ❌ NEVER do this - hardcoded strings
Text('Add Recipe')

// ✅ ALWAYS do this - localized strings
Text(AppLocalizations.of(context)!.addRecipe)
```

### 2. Adding New Localized Strings

When adding any new user-facing text, follow this **mandatory 4-step process**:

**Step 1: Add to English ARB file** (`lib/l10n/app_en.arb`)
```json
{
  "myNewString": "My New String",
  "@myNewString": {
    "description": "Clear description of what this string is used for"
  }
}
```

**Step 2: Add to Portuguese ARB file** (`lib/l10n/app_pt.arb`)
```json
{
  "myNewString": "Minha Nova String",
  "@myNewString": {
    "description": "Descrição clara do que esta string é usada"
  }
}
```

**Step 3: Regenerate localization files**
```bash
flutter gen-l10n
```

**Step 4: Use in code**
```dart
import '../l10n/app_localizations.dart';

// In your widget:
Text(AppLocalizations.of(context)!.myNewString)
```

### 3. String Types and Naming Conventions

**Simple Strings:**
```json
"buttonSave": "Save",
"labelEmail": "Email Address",
"errorNetwork": "Network connection failed"
```

**Strings with Parameters:**
```json
"welcomeMessage": "Welcome back, {userName}!",
"@welcomeMessage": {
  "description": "Welcome message with user's name",
  "placeholders": {
    "userName": {
      "type": "String",
      "description": "The user's display name"
    }
  }
}
```

**Pluralized Strings:**
```json
"itemCount": "{count,plural, =0{No items} =1{1 item} other{{count} items}}",
"@itemCount": {
  "description": "Count of items with proper pluralization",
  "placeholders": {
    "count": {
      "type": "int",
      "description": "Number of items"
    }
  }
}
```

### 4. Naming Conventions

Follow these patterns for consistent key naming:

- **UI Elements**: `button{Action}`, `label{Field}`, `title{Screen}`
  - Examples: `buttonSave`, `labelEmail`, `titleSettings`

- **Error Messages**: `error{Context}`, `validation{Field}`
  - Examples: `errorNetwork`, `validationEmail`

- **Categories**: `category{Type}{Item}`, `measurement{Type}{Unit}`
  - Examples: `categoryIngredientVegetable`, `measurementUnitCup`

- **Time/Dates**: `time{Context}`, `date{Context}`
  - Examples: `timeContextCurrent`, `dateLastCooked`

### 5. Validation Checklist

Before considering localization work complete, verify:

- [ ] String added to **both** `app_en.arb` and `app_pt.arb`
- [ ] Proper description provided in `@` metadata
- [ ] Parameters defined with correct types if applicable
- [ ] `flutter gen-l10n` executed successfully
- [ ] `flutter analyze` shows no errors
- [ ] String used correctly with `AppLocalizations.of(context)!.stringKey`
- [ ] Import added: `import '../l10n/app_localizations.dart';`

### 6. Error Prevention

**Always run these commands after adding localizations:**

```bash
# Generate updated localization files
flutter gen-l10n

# Check for any missing localizations or errors
flutter analyze

# Verify app builds without issues
flutter build apk --debug
```

### 7. Common Pitfalls to Avoid

❌ **DON'T:**
- Add strings to only one ARB file
- Forget to run `flutter gen-l10n` after changes
- Use hardcoded strings in UI code
- Mix different naming conventions
- Skip placeholder definitions for parameterized strings

✅ **DO:**
- Always add to both English and Portuguese ARB files
- Regenerate localizations immediately after ARB changes
- Use descriptive keys and metadata
- Follow established naming patterns
- Test both languages in the app

### 8. Maintenance Commands

**Check localization status:**
```bash
# Generate with untranslated messages report
flutter gen-l10n
```

**Find missing localizations:**
```bash
# Analyze for undefined getter errors
flutter analyze | grep "isn't defined for the type 'AppLocalizations'"
```

**Validate ARB files:**
```bash
# Check ARB file syntax
flutter gen-l10n --verify-only
```

### 9. Emergency Recovery

If you encounter massive localization errors (like the 124 errors we just fixed):

1. **Identify missing keys** from `flutter analyze` output
2. **Add all missing keys** to both ARB files systematically
3. **Group by category** (UI elements, errors, categories, etc.)
4. **Regenerate** with `flutter gen-l10n`
5. **Verify** with `flutter analyze`

### 10. File Locations

- **English ARB**: `lib/l10n/app_en.arb`
- **Portuguese ARB**: `lib/l10n/app_pt.arb`
- **Generated files**: `lib/l10n/app_localizations*.dart` (auto-generated, don't edit)
- **Configuration**: `l10n.yaml` (project root)

## Important Notes

- **Generated files are auto-generated** - never edit `app_localizations*.dart` files directly
- **ARB files are source of truth** - all changes must be made in `.arb` files
- **Both languages must be maintained** - incomplete translations will cause runtime errors
- **Always test both languages** - switch device language to verify translations

This protocol ensures that localization remains complete and prevents the accumulation of missing translation errors.
