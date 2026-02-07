# API/Service Documentation Template

Use this template when documenting a service, repository, or internal API.

**Location:** `docs/architecture/[service-name].md` or as a section within an existing architecture document.

---

## Template

```markdown
# [Service/API Name]

## Overview

[Brief description of what this service does. 1-2 sentences.]

**Access via:**
```dart
final service = ServiceProvider.[category].[serviceName];
```

## Methods

### `methodName`

[Description of what this method does.]

**Signature:**
```dart
Future<ReturnType> methodName({
  required Type param1,
  Type? param2,
  int count = 10,
}) async
```

**Parameters:**

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `param1` | `Type` | Yes | - | [Description] |
| `param2` | `Type?` | No | `null` | [Description] |
| `count` | `int` | No | `10` | [Description] |

**Returns:** `Future<ReturnType>` - [Description of return value]

**Throws:**

| Exception | When |
|-----------|------|
| `NotFoundException` | [When entity not found] |
| `ValidationException` | [When input invalid] |
| `GastrobrainException` | [When operation fails] |

**Example:**
```dart
try {
  final result = await service.methodName(
    param1: value,
    param2: optionalValue,
    count: 5,
  );
  // Use result
} on NotFoundException {
  // Handle not found
}
```

---

### `anotherMethod`

[Repeat the above structure for each public method]

---

## Data Types

### [TypeName]

[Description of this data type used by the service.]

```dart
class TypeName {
  /// [Field description]
  final String id;

  /// [Field description]
  final String name;

  /// [Field description, nullable because...]
  final OtherType? optional;
}
```

### Enums

```dart
/// [Enum description]
enum EnumName {
  value1, // [Description]
  value2, // [Description]
  value3, // [Description]
}
```

## Behavior Notes

### Caching

[Describe caching behavior if applicable]

- Cache key: [what determines cache hits]
- Invalidation: [when cache is cleared]
- TTL: [how long cached data is valid]

### Temporal Context

[If behavior changes based on time/context]

- **Weekdays:** [behavior]
- **Weekends:** [behavior]

### Error Handling

[How errors are propagated and what callers should expect]

```dart
// Error handling pattern for this service
try {
  await service.method();
} on NotFoundException {
  // Entity not found - show appropriate UI
} on ValidationException catch (e) {
  // Input validation failed - show e.message
} on GastrobrainException catch (e) {
  // General error - show generic error message
}
```

## Testing

### Mocking

```dart
// How to mock this service in tests
final mockService = MockServiceName();
when(mockService.methodName(any)).thenAnswer((_) async => testData);
```

### Key Test Scenarios

- [Scenario 1]: [What to test and why]
- [Scenario 2]: [What to test and why]
- [Scenario 3]: [Edge case to test]

## Related Documentation

- **Architecture:** [Link to component architecture doc]
- **Pattern:** [Link to pattern doc if applicable]
- **ADR:** [Link to decision record if applicable]
- **Tests:** `test/[path]/`
```

---

## Usage Notes

- Document every public method with full signature and examples
- Include actual exception types thrown, not generic ones
- Show real usage patterns from the codebase
- Keep examples minimal but complete (should compile)
- Update when method signatures change
- Cross-reference from architecture documentation
