#!/usr/bin/env python3
"""
Sprint Commit Analyzer

Analyzes git commits to measure actual effort per issue for sprint retrospectives.
Uses weighted days based on lines of code changed when multiple issues share a day.

Usage:
    python scripts/analyze_sprint_commits.py --since 2025-12-02 --branch develop
    python scripts/analyze_sprint_commits.py --since 2025-12-02 --until 2025-12-17

Options:
    --since     Start date (YYYY-MM-DD) - required
    --until     End date (YYYY-MM-DD) - optional, defaults to today
    --branch    Branch to analyze - optional, defaults to current branch
    --issues    Comma-separated issue numbers to track (e.g., "223,228,124")
                If not provided, extracts all issues from commits
"""

import argparse
import re
import subprocess
from collections import defaultdict
from datetime import datetime


def get_commits_with_stats(since: str, until: str = None, branch: str = None) -> list[dict]:
    """Get commits from git log with line change stats."""
    cmd = ["git", "log", "--format=COMMIT_START%n%ad%n%s", "--date=short", "--stat"]

    if branch:
        cmd.append(branch)

    cmd.append(f"--since={since}")

    if until:
        cmd.append(f"--until={until}")

    result = subprocess.run(cmd, capture_output=True, text=True, check=True)

    commits = []
    current_commit = None

    for line in result.stdout.split('\n'):
        if line == 'COMMIT_START':
            if current_commit:
                commits.append(current_commit)
            current_commit = {"date": None, "msg": None, "lines": 0}
        elif current_commit:
            if current_commit["date"] is None:
                current_commit["date"] = line.strip()
            elif current_commit["msg"] is None:
                current_commit["msg"] = line.strip()
            else:
                # Parse stat lines like "8 files changed, 454 insertions(+), 99 deletions(-)"
                match = re.search(r'(\d+) insertion', line)
                if match:
                    current_commit["lines"] += int(match.group(1))
                match = re.search(r'(\d+) deletion', line)
                if match:
                    current_commit["lines"] += int(match.group(1))

    if current_commit:
        commits.append(current_commit)

    return [c for c in commits if c["date"] and c["msg"]]


def extract_issues_weighted(commits: list[dict]) -> tuple[dict, list, dict]:
    """
    Group commits by issue number with weighted day calculation.

    Returns:
        - issue_data: dict with issue stats
        - untagged: list of untagged commits
        - daily_breakdown: dict showing issues worked per day with weights
    """
    issue_data = defaultdict(lambda: {
        "dates": set(),
        "commits": 0,
        "lines": 0,
        "messages": [],
        "lines_by_date": defaultdict(int)
    })
    untagged = []
    daily_totals = defaultdict(lambda: {"issues": defaultdict(int), "total_lines": 0})

    for commit in commits:
        date = commit["date"]
        msg = commit["msg"]
        lines = commit["lines"]

        issues = re.findall(r'#(\d+)', msg)

        if issues:
            for issue in issues:
                issue_data[issue]["dates"].add(date)
                issue_data[issue]["commits"] += 1
                issue_data[issue]["lines"] += lines
                issue_data[issue]["messages"].append(msg[:60])
                issue_data[issue]["lines_by_date"][date] += lines

                daily_totals[date]["issues"][issue] += lines
                daily_totals[date]["total_lines"] += lines
        else:
            untagged.append((date, msg, lines))

    # Calculate weighted days for each issue
    for issue, data in issue_data.items():
        weighted_days = 0.0
        for date in data["dates"]:
            day_total = daily_totals[date]["total_lines"]
            issue_lines = daily_totals[date]["issues"][issue]
            if day_total > 0:
                # Weight is proportion of lines changed that day
                weight = issue_lines / day_total
                weighted_days += weight
            else:
                weighted_days += 1.0  # Full day if no line data
        data["weighted_days"] = round(weighted_days, 2)

    return dict(issue_data), untagged, dict(daily_totals)


def print_analysis(issue_data: dict, untagged: list, daily_totals: dict):
    """Print analysis in markdown-friendly format."""

    print("=" * 90)
    print("SPRINT COMMIT ANALYSIS (Weighted by Lines Changed)")
    print("=" * 90)

    # Summary table
    print("\n### Commits by Issue\n")
    print("| Issue | First | Last | Active Days | Weighted Days | Lines | Commits |")
    print("|-------|-------|------|-------------|---------------|-------|---------|")

    sorted_issues = sorted(issue_data.keys(), key=lambda x: min(issue_data[x]["dates"]))

    total_weighted = 0
    total_lines = 0
    total_commits = 0

    for issue in sorted_issues:
        data = issue_data[issue]
        dates = sorted(data["dates"])
        first = dates[0]
        last = dates[-1]
        active_days = len(dates)
        weighted_days = data["weighted_days"]
        lines = data["lines"]
        commits = data["commits"]

        total_weighted += weighted_days
        total_lines += lines
        total_commits += commits

        shared_marker = "*" if weighted_days < active_days else ""
        print(f"| #{issue} | {first} | {last} | {active_days} | {weighted_days}{shared_marker} | {lines} | {commits} |")

    print(f"| **TOTAL** | | | | **{total_weighted:.1f}** | **{total_lines}** | **{total_commits}** |")
    print("\n*\\* Weighted < Active Days indicates day shared with other issues*")

    # Daily breakdown
    print("\n### Daily Breakdown (Shared Days)\n")
    print("| Date | Issues | Lines Distribution |")
    print("|------|--------|-------------------|")

    for date in sorted(daily_totals.keys()):
        day = daily_totals[date]
        if len(day["issues"]) > 1:
            issues_str = ", ".join([f"#{i}" for i in day["issues"].keys()])
            dist = ", ".join([f"#{i}: {l} ({l/day['total_lines']*100:.0f}%)"
                             for i, l in day["issues"].items()])
            print(f"| {date} | {issues_str} | {dist} |")

    # Untagged commits
    if untagged:
        print("\n### Untagged Commits (need attribution)\n")
        print("| Date | Lines | Message |")
        print("|------|-------|---------|")
        for date, msg, lines in untagged:
            print(f"| {date} | {lines} | {msg[:50]}{'...' if len(msg) > 50 else ''} |")

    # Working days summary
    all_dates = set()
    for data in issue_data.values():
        all_dates.update(data["dates"])

    if all_dates:
        print("\n### Working Days Summary\n")
        print(f"- **Total unique working days:** {len(all_dates)}")
        print(f"- **Total weighted days:** {total_weighted:.1f}")
        print(f"- **Date range:** {min(all_dates)} to {max(all_dates)}")

        start = datetime.strptime(min(all_dates), '%Y-%m-%d')
        end = datetime.strptime(max(all_dates), '%Y-%m-%d')
        calendar_days = (end - start).days + 1
        utilization = len(all_dates) / calendar_days * 100

        print(f"- **Calendar days:** {calendar_days}")
        print(f"- **Utilization:** {utilization:.0f}%")

        # Daily activity
        print("\n### Daily Activity\n")
        print("```")
        for date in sorted(all_dates):
            day_issues = []
            for issue, data in issue_data.items():
                if date in data["dates"]:
                    day_lines = data["lines_by_date"][date]
                    day_issues.append((issue, day_lines))

            day_issues.sort(key=lambda x: -x[1])  # Sort by lines desc
            issues_str = ", ".join([f"#{i}({l})" for i, l in day_issues])
            total_day_lines = sum(l for _, l in day_issues)
            bar = "█" * min(total_day_lines // 100, 20)
            print(f"{date}: {bar} {issues_str}")
        print("```")


def main():
    parser = argparse.ArgumentParser(
        description="Analyze sprint commits for retrospective (weighted by lines changed)"
    )
    parser.add_argument("--since", required=True, help="Start date (YYYY-MM-DD)")
    parser.add_argument("--until", help="End date (YYYY-MM-DD)")
    parser.add_argument("--branch", help="Branch to analyze")
    parser.add_argument("--issues", help="Comma-separated issue numbers to focus on")

    args = parser.parse_args()

    # Get commits with stats
    commits = get_commits_with_stats(args.since, args.until, args.branch)

    if not commits:
        print("No commits found in the specified range.")
        return

    print(f"Found {len(commits)} commits from {args.since}" +
          (f" to {args.until}" if args.until else " to now"))

    # Extract and analyze with weighting
    issue_data, untagged, daily_totals = extract_issues_weighted(commits)

    # Filter to specific issues if requested
    if args.issues:
        focus_issues = set(args.issues.split(","))
        issue_data = {k: v for k, v in issue_data.items() if k in focus_issues}

    # Print analysis
    print_analysis(issue_data, untagged, daily_totals)

    print("\n" + "=" * 90)
    print("Copy the tables above into docs/Sprint-Estimation-Diary.md")
    print("=" * 90)


if __name__ == "__main__":
    main()
