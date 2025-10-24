# The "de" Nightmare in Portuguese Ingredient Parsing

## The Challenge

Portuguese ingredient lists use "de" (meaning "of") in multiple contexts, making regex-based parsing extremely fragile.

## All "de" Contexts Found

### 1. Inside Compound Units ✅ (Must Keep)
**Pattern:** `[unit word] de [unit word]`

Examples:
- `colher de sopa` → tablespoon
- `colher de chá` → teaspoon  
- `colher de sobremesa` → dessert spoon

**Parsing:** These must be recognized as SINGLE unit tokens before any other processing.

---

### 2. Between Unit and Ingredient ❌ (Must Strip)
**Pattern:** `[quantity] [unit] de [ingredient]`

Examples:
- `2 kg de mangas` → unit=kg, ingredient=mangas
- `200g de farinha` → unit=g, ingredient=farinha
- `2 colheres de sopa de azeite` → unit=tbsp, ingredient=azeite

**Parsing:** Strip the "de" that immediately follows a recognized unit.

---

### 3. Inside Ingredient Names ✅ (Must Keep)
**Pattern:** `[ingredient word] de [ingredient word]`

Examples:
- `pão de forma` → ingredient name (sandwich bread)
- `queijo de cabra` → ingredient name (goat cheese)
- `pasta de tamarindo` → ingredient name (tamarind paste)
- `molho de tomate` → ingredient name (tomato sauce)
- `leite de coco` → ingredient name (coconut milk)

**Parsing:** These "de"s are essential parts of the ingredient name and must be preserved.

---

### 4. Inside Descriptor Phrases ✅ (Must Keep)
**Pattern:** `[descriptor] de [descriptor]`

Examples:
- `em ponto de bala` → descriptor (at hard ball stage - cooking term)
- `em ponto de neve` → descriptor (at stiff peaks - meringue)
- `em ponto de fio` → descriptor (at thread stage - syrup)

**Parsing:** These are preparation state descriptors that must be preserved in the notes field.

---

## The Complete Nightmare Example

```
2 colheres de sopa de pasta de tamarindo em ponto de bala
```

**Breaking it down:**
- `2` → quantity ✓
- `colheres de sopa` → compound unit (contains "de" #1) ✓
- `de` → after unit, should be stripped ❌
- `pasta de tamarindo` → ingredient name (contains "de" #3) ✓
- `em ponto de bala` → descriptor (contains "de" #4) ✓

**Expected result:**
- Quantity: 2
- Unit: tbsp
- Name: pasta de tamarindo
- Notes: em ponto de bala

---

## Why Regex Fails

A regex trying to handle all these cases simultaneously becomes:
1. **Overly complex** - multiple lookaheads/lookbehinds
2. **Fragile** - breaks on edge cases
3. **Unmaintainable** - impossible to understand
4. **Incomplete** - always missing some context

Example of what the regex would need to handle:
```regex
# This is a NIGHTMARE:
^(\d+(?:[.,]\d+)?)\s+
  # Unit can be simple OR compound with "de"
  (?:([a-z]+)|([a-z]+\s+de\s+[a-z]+))\s+
  # Maybe "de" after unit (strip it)
  (?:de\s+)?
  # Rest is ingredient + descriptors
  # But ingredient might contain "de"
  # And descriptors might contain "de"
  # And we need to distinguish between them
  # ... IMPOSSIBLE
```

---

## The Solution: Context-Aware Parsing

**Step 1:** Load all known units from `MeasurementUnit` model
```
Known units: kg, g, colher de sopa, colher de chá, xícara, ...
```

**Step 2:** Parse in order
```
Input: "2 colheres de sopa de pasta de tamarindo em ponto de bala"

1. Extract quantity: "2"
   Remaining: "colheres de sopa de pasta de tamarindo em ponto de bala"

2. Match against known units (longest first):
   Found: "colheres de sopa"
   Remaining: "de pasta de tamarindo em ponto de bala"

3. Strip "de" if immediately after unit:
   Remaining: "pasta de tamarindo em ponto de bala"

4. Everything else is ingredient + descriptors:
   Use fuzzy matching: "pasta de tamarindo" matches existing ingredient
   Remaining: "em ponto de bala" → goes to notes
```

**Step 3:** Simple rule for "de" handling
```
IF next_token == "de" AND previous_token == recognized_unit:
    strip_it()
ELSE:
    keep_it()  // Part of ingredient name or descriptor
```

---

## Key Insight

**The only "de" we should remove is the one immediately after a unit.**

All other "de"s are legitimate parts of:
- Compound units (handled by matching full unit strings)
- Ingredient names (preserved)
- Descriptors (preserved)

This simple rule only works if we:
1. Know what the valid units are (from `MeasurementUnit` model)
2. Match units FIRST before trying to identify anything else
3. Don't try to guess what's a unit vs. what's an ingredient using regex

---

## Additional Portuguese Cooking Terms

For future reference, other multi-word descriptors with "de":

**Consistency descriptors:**
- `em ponto de bala` (hard ball stage)
- `em ponto de neve` (stiff peaks)
- `em ponto de fio` (thread stage)
- `em ponto de caramelo` (caramel stage)

**Preparation state:**
- `em temperatura ambiente` (room temperature)
- `bem gelado` (very cold)
- `em cubos` (in cubes)
- `em rodelas` (in rounds/slices)

None of these contain "de" except the "ponto de" family, but they show the complexity of descriptors that might need to be extracted to the notes field.
