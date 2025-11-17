#!/usr/bin/env python3
"""Parse LCOV coverage data and generate comprehensive report."""

import sys
from pathlib import Path
from collections import defaultdict

def parse_lcov(lcov_file):
    """Parse LCOV file and return coverage data by directory."""
    coverage_by_file = {}
    current_file = None
    lines_found = 0
    lines_hit = 0

    with open(lcov_file, 'r') as f:
        for line in f:
            line = line.strip()
            if line.startswith('SF:'):
                # New source file
                current_file = line[3:]  # Remove 'SF:' prefix
            elif line.startswith('LF:'):
                # Lines found (total lines)
                lines_found = int(line[3:])
            elif line.startswith('LH:'):
                # Lines hit (covered lines)
                lines_hit = int(line[3:])
            elif line == 'end_of_record':
                # End of file record
                if current_file and lines_found > 0:
                    coverage_pct = (lines_hit / lines_found) * 100
                    coverage_by_file[current_file] = {
                        'lines_found': lines_found,
                        'lines_hit': lines_hit,
                        'coverage': coverage_pct
                    }
                current_file = None
                lines_found = 0
                lines_hit = 0

    return coverage_by_file

def categorize_by_directory(coverage_data):
    """Categorize files by directory."""
    by_directory = defaultdict(lambda: {'lines_found': 0, 'lines_hit': 0, 'files': []})

    for file_path, data in coverage_data.items():
        # Extract directory (e.g., lib/models/, lib/services/)
        parts = Path(file_path).parts
        if len(parts) >= 2 and parts[0] == 'lib':
            directory = f"{parts[0]}/{parts[1]}/"
        else:
            directory = "other/"

        by_directory[directory]['lines_found'] += data['lines_found']
        by_directory[directory]['lines_hit'] += data['lines_hit']
        by_directory[directory]['files'].append({
            'path': file_path,
            'coverage': data['coverage'],
            'lines_found': data['lines_found'],
            'lines_hit': data['lines_hit']
        })

    # Calculate directory coverage percentages
    for directory, data in by_directory.items():
        if data['lines_found'] > 0:
            data['coverage'] = (data['lines_hit'] / data['lines_found']) * 100
        else:
            data['coverage'] = 0.0

    return by_directory

def main():
    lcov_file = Path('coverage/lcov.info')

    if not lcov_file.exists():
        print("ERROR: coverage/lcov.info not found", file=sys.stderr)
        sys.exit(1)

    # Parse coverage data
    coverage_data = parse_lcov(lcov_file)

    # Categorize by directory
    by_directory = categorize_by_directory(coverage_data)

    # Calculate overall coverage
    total_lines_found = sum(data['lines_found'] for data in coverage_data.values())
    total_lines_hit = sum(data['lines_hit'] for data in coverage_data.values())
    overall_coverage = (total_lines_hit / total_lines_found * 100) if total_lines_found > 0 else 0.0

    # Print overall summary
    print("=" * 80)
    print("COVERAGE ANALYSIS SUMMARY")
    print("=" * 80)
    print(f"\nOverall Coverage: {overall_coverage:.2f}% ({total_lines_hit}/{total_lines_found} lines)")
    print(f"Threshold: ≥85%")
    print(f"Status: {'✅ PASS' if overall_coverage >= 85 else '❌ FAIL'}")

    # Print per-directory coverage
    print("\n" + "=" * 80)
    print("PER-DIRECTORY COVERAGE")
    print("=" * 80)

    directories = ['lib/models/', 'lib/services/', 'lib/screens/', 'lib/widgets/', 'lib/utils/']
    for directory in directories:
        if directory in by_directory:
            data = by_directory[directory]
            cov = data['coverage']
            threshold_msg = "≥85%" if directory != 'lib/utils/' else "(no threshold)"
            status = ""
            if directory != 'lib/utils/':
                status = " ✅" if cov >= 85 else " ❌"
            print(f"\n{directory}: {cov:.2f}% ({data['lines_hit']}/{data['lines_found']} lines) {threshold_msg}{status}")

            # Show files in this directory
            files = sorted(data['files'], key=lambda x: x['coverage'])
            for file_info in files:
                file_status = ""
                if directory != 'lib/utils/' and file_info['coverage'] < 85:
                    file_status = " ⚠️  BELOW THRESHOLD"
                print(f"  - {file_info['path']}: {file_info['coverage']:.2f}% ({file_info['lines_hit']}/{file_info['lines_found']}){file_status}")
        else:
            print(f"\n{directory}: No files found")

    # Identify files below 85% threshold
    print("\n" + "=" * 80)
    print("FILES BELOW 85% THRESHOLD")
    print("=" * 80)

    below_threshold = []
    for file_path, data in coverage_data.items():
        # Skip utils directory
        if not file_path.startswith('lib/utils/'):
            if data['coverage'] < 85:
                below_threshold.append({
                    'path': file_path,
                    'coverage': data['coverage'],
                    'gap': 85 - data['coverage']
                })

    if below_threshold:
        below_threshold.sort(key=lambda x: x['coverage'])
        for item in below_threshold:
            print(f"  ❌ {item['path']}: {item['coverage']:.2f}% (need {item['gap']:.2f}% more)")
    else:
        print("  ✅ No files below 85% threshold")

    print("\n" + "=" * 80)

    # Exit with status code
    if overall_coverage >= 85 and not below_threshold:
        sys.exit(0)
    else:
        sys.exit(1)

if __name__ == '__main__':
    main()
