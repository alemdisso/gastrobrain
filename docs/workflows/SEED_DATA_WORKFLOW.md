# Seed Data Workflow

How to update the recipe seed data that ships with fresh installs.

---

## Key files

| File | Purpose |
|---|---|
| `tools/seed_recipe_list.txt` | Canonical include list — one UUID per line |
| `tools/analyze_recipe_export.dart` | Analyzes exports, generates/diffs include lists |
| `tools/convert_export_to_seed.dart` | Generates `assets/recipes.json` and `assets/ingredients.json` from export + include list |

---

## When to update seed data

At the end of each milestone, after curating new recipes in the app.

---

## Workflow

### 1. Export from the app
Use the app's export feature. Copy the resulting file to `assets/`.

### 2. Analyze the new export
```
dart run tools/analyze_recipe_export.dart assets/recipe_export_<timestamp>.json
```
Review the **Complete** section — these are candidates for seeding.

### 3. See what's new since last seed
```
dart run tools/analyze_recipe_export.dart assets/recipe_export_<timestamp>.json --delta tools/seed_recipe_list.txt
```
Outputs UUIDs + names for complete recipes not yet in the include list.

### 4. Update the include list

**To add recipes:** copy lines from the `--delta` output into `tools/seed_recipe_list.txt` under a new milestone comment:
```
## added in 0.2.2
<uuid>  # recipe name
```

**To remove a recipe:** delete its line from `tools/seed_recipe_list.txt`.

### 5. Regenerate seed assets
```
dart run tools/convert_export_to_seed.dart assets/recipe_export_<timestamp>.json
```
This writes `assets/recipes.json` and `assets/ingredients.json`.

### 6. Verify and commit
Review the output counts. Commit `seed_recipe_list.txt`, `recipes.json`, `ingredients.json`, and the new export file.

---

## Notes

- UUIDs are stable across recipe renames. If a recipe is deleted and recreated in the app, its UUID changes — update the include list accordingly.
- The include list is the curation record. Git history shows which recipes were added or removed at each milestone.
- Seed data only affects fresh installs. Existing user data is never touched.
