# Dependency Injection in Gastrobrain

This document explains how dependency injection is implemented in the Gastrobrain application.

## Overview

Gastrobrain uses a lightweight service locator pattern for dependency injection. This approach:
- Centralizes service creation and management
- Makes testing easier by allowing mock services to be injected
- Reduces direct dependencies between components

## Usage

### Accessing Services

Services can be accessed through their respective providers:

```dart
// Get the database helper
final dbHelper = DatabaseProvider().dbHelper;

// Use the database helper
final recipes = await dbHelper.getAllRecipes();