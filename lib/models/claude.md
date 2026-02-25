# Watchdog — models/

Inherits root rules from `lib/CLAUDE.md`. The overrides and additions below
apply to all files in `lib/models/`.

---

## Threshold Overrides

| Smell | Threshold | Severity | Notes |
|---|---|---|---|
| File length | > 150 lines | 🟡 High | Models should be lean data containers |
| File length | > 250 lines | 🔴 Critical | |

---

## Model-Specific Smells

| Smell | Trigger | Severity |
|---|---|---|
| Business logic in model | Methods beyond `copyWith`, `toMap`, `fromMap`, `toString`, `==`, `hashCode` | 🟡 High |
| Missing `copyWith` | Model has 3+ fields but no `copyWith` method | 🟡 High |
| Primitive obsession | Grouped primitives (e.g. amount + currency, lat + lng) without a domain object | 🟡 High |
| Mutable fields | Model fields not declared `final` | 🟡 High |
| Direct DB coupling | Model contains SQL strings or database logic | 🔴 Critical |

---

## Healthy Model Pattern (reference)

```dart
class MyModel {
  final int id;
  final String name;

  const MyModel({required this.id, required this.name});

  MyModel copyWith({int? id, String? name}) => ...
  factory MyModel.fromMap(Map<String, dynamic> map) => ...
  Map<String, dynamic> toMap() => ...

  @override bool operator ==(Object other) => ...
  @override int get hashCode => ...
}
```