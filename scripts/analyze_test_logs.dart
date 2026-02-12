#!/usr/bin/env dart

/// Analyzes integration test logs to identify patterns in intermittent failures
///
/// Usage: dart scripts/analyze_test_logs.dart <log_directory>

import 'dart:io';

void main(List<String> args) {
  if (args.isEmpty) {
    print('Usage: dart analyze_test_logs.dart <log_directory>');
    print(
        'Example: dart analyze_test_logs.dart test_logs/integration_20260211_143022');
    exit(1);
  }

  final logDir = Directory(args[0]);
  if (!logDir.existsSync()) {
    print('Error: Directory not found: ${args[0]}');
    exit(1);
  }

  final analyzer = TestLogAnalyzer(logDir);
  analyzer.analyze();
  analyzer.printReport();
}

class TestFailure {
  final String testName;
  final String fileName;
  final String errorMessage;
  final String? stackTrace;
  final int runNumber;
  final String timestamp;

  TestFailure({
    required this.testName,
    required this.fileName,
    required this.errorMessage,
    this.stackTrace,
    required this.runNumber,
    required this.timestamp,
  });
}

class TestLogAnalyzer {
  final Directory logDir;
  final List<TestFailure> failures = [];
  int totalRuns = 0;
  int passedRuns = 0;
  int failedRuns = 0;

  TestLogAnalyzer(this.logDir);

  void analyze() {
    print('📊 Analyzing test logs in: ${logDir.path}\n');

    final logFiles = logDir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.log'))
        .toList()
      ..sort((a, b) => a.path.compareTo(b.path));

    totalRuns = logFiles.length;

    logFiles.forEach(_analyzeLogFile);
  }

  void _analyzeLogFile(File logFile) {
    final content = logFile.readAsStringSync();
    final lines = content.split('\n');

    // Extract metadata
    int? runNumber;
    int? exitCode;
    String? timestamp;

    for (final line in lines) {
      if (line.startsWith('Run: ')) {
        runNumber = int.tryParse(line.substring(5).trim());
      } else if (line.startsWith('Exit Code: ')) {
        exitCode = int.tryParse(line.substring(11).trim());
      } else if (line.startsWith('Timestamp: ')) {
        timestamp = line.substring(11).trim();
      }
    }

    if (exitCode == 0) {
      passedRuns++;
      return; // No failures to parse
    }

    failedRuns++;

    // Parse test failures
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];

      // Look for Flutter test failure pattern: "FAILED: <test name>"
      if (line.contains('✗') || line.contains('FAILED')) {
        final testName = _extractTestName(line, lines, i);
        final errorDetails = _extractErrorDetails(lines, i);

        if (testName != null) {
          failures.add(TestFailure(
            testName: testName,
            fileName: _extractFileName(lines, i),
            errorMessage: errorDetails['error'] ?? 'Unknown error',
            stackTrace: errorDetails['stackTrace'],
            runNumber: runNumber ?? 0,
            timestamp: timestamp ?? 'unknown',
          ));
        }
      }
    }
  }

  String? _extractTestName(String line, List<String> lines, int index) {
    // Try to extract from current line first
    if (line.contains('✗')) {
      final match = RegExp(r'✗\s+(.+?)(?:\s+\(|$)').firstMatch(line);
      if (match != null) return match.group(1)?.trim();
    }

    // Look backwards for test name
    for (int i = index - 1; i >= 0 && i >= index - 10; i--) {
      if (lines[i].contains('00:')) {
        final parts = lines[i].split(':');
        if (parts.length >= 3) {
          return parts.sublist(2).join(':').trim();
        }
      }
    }

    return null;
  }

  String _extractFileName(List<String> lines, int index) {
    // Look for file path in nearby lines
    for (int i = index; i < lines.length && i < index + 20; i++) {
      final line = lines[i];
      if (line.contains('integration_test/')) {
        final match =
            RegExp(r'integration_test/[^\s:]+\.dart').firstMatch(line);
        if (match != null) return match.group(0)!;
      }
    }
    return 'unknown';
  }

  Map<String, String> _extractErrorDetails(List<String> lines, int index) {
    final error = StringBuffer();
    final stackTrace = StringBuffer();
    bool inStackTrace = false;

    for (int i = index + 1; i < lines.length && i < index + 50; i++) {
      final line = lines[i];

      // Stop at next test or section
      if (line.contains('00:') && line.contains('+')) break;
      if (line.startsWith('===')) break;

      if (line.contains('package:') || line.contains('.dart:')) {
        inStackTrace = true;
        stackTrace.writeln(line);
      } else if (!inStackTrace && line.trim().isNotEmpty) {
        if (line.contains('Expected:') ||
            line.contains('Actual:') ||
            line.contains('Which:') ||
            line.contains('Warning:')) {
          error.writeln(line.trim());
        }
      }
    }

    return {
      'error': error.toString().trim(),
      'stackTrace': stackTrace.toString().trim(),
    };
  }

  void printReport() {
    print('=' * 80);
    print('TEST RUN SUMMARY');
    print('=' * 80);
    print('Total runs:  $totalRuns');
    print('Passed:      $passedRuns (${_percentage(passedRuns, totalRuns)}%)');
    print('Failed:      $failedRuns (${_percentage(failedRuns, totalRuns)}%)');
    print('');

    if (failures.isEmpty) {
      print('✅ No failures detected!');
      return;
    }

    // Group failures by test name
    final failuresByTest = <String, List<TestFailure>>{};
    for (final failure in failures) {
      failuresByTest.putIfAbsent(failure.testName, () => []).add(failure);
    }

    print('=' * 80);
    print('FAILURE ANALYSIS');
    print('=' * 80);
    print('');

    // Sort by failure count (most frequent first)
    final sortedTests = failuresByTest.entries.toList()
      ..sort((a, b) => b.value.length.compareTo(a.value.length));

    for (final entry in sortedTests) {
      final testName = entry.key;
      final testFailures = entry.value;
      final failureRate = _percentage(testFailures.length, totalRuns);

      print('🔴 Test: $testName');
      print('   File: ${testFailures.first.fileName}');
      print(
          '   Failures: ${testFailures.length}/$totalRuns runs ($failureRate%)');
      print(
          '   Failed on runs: ${testFailures.map((f) => f.runNumber).join(', ')}');
      print('');
      print('   Error:');
      for (final line in testFailures.first.errorMessage.split('\n')) {
        if (line.isNotEmpty) print('   $line');
      }
      print('');

      // Show if error is consistent
      final uniqueErrors =
          testFailures.map((f) => f.errorMessage).toSet().length;
      if (uniqueErrors == 1) {
        print('   ℹ️  Error message is CONSISTENT across all failures');
      } else {
        print('   ⚠️  Error message VARIES ($uniqueErrors different messages)');
      }
      print('');
      print('-' * 80);
      print('');
    }

    // Pattern analysis
    print('=' * 80);
    print('PATTERN ANALYSIS');
    print('=' * 80);
    _analyzePatterns(failuresByTest);
  }

  void _analyzePatterns(Map<String, List<TestFailure>> failuresByTest) {
    // Pattern 1: Consecutive failures
    print('\n🔍 Checking for consecutive failure patterns...');
    for (final entry in failuresByTest.entries) {
      final runs = entry.value.map((f) => f.runNumber).toList()..sort();
      final consecutive = _findConsecutive(runs);
      if (consecutive.length >= 2) {
        print('   ⚠️  ${entry.key}: Failed on consecutive runs $consecutive');
      }
    }

    // Pattern 2: Tests failing together
    print('\n🔍 Checking for tests that fail together...');
    final runFailures = <int, Set<String>>{};
    for (final failure in failures) {
      runFailures
          .putIfAbsent(failure.runNumber, () => {})
          .add(failure.testName);
    }

    final coFailures = <String, int>{};
    for (final failedTests in runFailures.values) {
      if (failedTests.length > 1) {
        final pair = failedTests.toList()..sort();
        final key = pair.join(' + ');
        coFailures[key] = (coFailures[key] ?? 0) + 1;
      }
    }

    if (coFailures.isNotEmpty) {
      for (final entry in coFailures.entries) {
        print('   ⚠️  "${entry.key}" failed together ${entry.value} time(s)');
      }
    } else {
      print('   ✓ No consistent pattern of tests failing together');
    }

    // Pattern 3: Time-based patterns
    print('\n🔍 Failure distribution...');
    if (failures.length > 1) {
      final firstFailRun =
          failures.map((f) => f.runNumber).reduce((a, b) => a < b ? a : b);
      final lastFailRun =
          failures.map((f) => f.runNumber).reduce((a, b) => a > b ? a : b);
      print('   First failure: Run $firstFailRun');
      print('   Last failure: Run $lastFailRun');
      print('   Spread: ${lastFailRun - firstFailRun} runs');
    }
  }

  List<int> _findConsecutive(List<int> numbers) {
    if (numbers.length < 2) return [];

    final consecutive = <int>[numbers[0]];
    for (int i = 1; i < numbers.length; i++) {
      if (numbers[i] == numbers[i - 1] + 1) {
        consecutive.add(numbers[i]);
      } else if (consecutive.length >= 2) {
        return consecutive;
      } else {
        consecutive.clear();
        consecutive.add(numbers[i]);
      }
    }

    return consecutive.length >= 2 ? consecutive : [];
  }

  String _percentage(int value, int total) {
    if (total == 0) return '0';
    return ((value / total) * 100).toStringAsFixed(1);
  }
}
