#!/usr/bin/env python3
"""
Fix markdown formatting issues in CODE_REVIEW.md
- Fix dividers (-- to ---)
- Convert *text* to **text** for bold
- Add proper checkboxes
- Add blank lines around headers
- Add dividers between major task sections
- Fix inconsistent list formatting
"""

import re

def fix_markdown(content):
    lines = content.split('\n')
    fixed_lines = []
    i = 0
    
    while i < len(lines):
        line = lines[i]
        
        # Fix double dash dividers to triple dash
        if line.strip() == '--':
            fixed_lines.append('---')
            i += 1
            continue
        
        # Fix bold formatting: *text:* to **text:**
        if line.startswith('*') and line.endswith('*') and ':' in line:
            # e.g., "*Task 1.1:*" -> "**Task 1.1:**"
            line = line.replace('*', '**', 2)
        
        # Fix checkbox syntax: -[ ] to - [ ]
        if re.match(r'^-\[', line):
            line = line.replace('-[', '- [', 1)
        
        # Add blank line before headers (if not already there)
        if line.startswith('#'):
            if fixed_lines and fixed_lines[-1].strip() != '' and not fixed_lines[-1].startswith('#'):
                fixed_lines.append('')
        
        # Add blank line after headers (if not already there)
        if i > 0 and lines[i-1].startswith('#'):
            if line.strip() != '' and not line.startswith('#'):
                # Check if we need a blank line
                if not (i > 1 and lines[i-2].startswith('#')):
                    fixed_lines.insert(len(fixed_lines), '')
        
        # Add divider after Task sections (before next Task or Phase)
        if re.match(r'^Task \d+\.\d+:', line) or re.match(r'^PHASE \d+:', line):
            # Look ahead to see if next non-empty line is also a Task/Phase
            for j in range(i+1, min(i+20, len(lines))):
                if lines[j].strip() == '':
                    continue
                if re.match(r'^(Task \d+\.\d+:|PHASE \d+:)', lines[j]):
                    # Add divider before next task
                    break
                break
        
        fixed_lines.append(line)
        i += 1
    
    # Join and do global replacements
    content = '\n'.join(fixed_lines)
    
    # Fix specific bold patterns
    content = re.sub(r'\*✅ Strengths:\*', '**✅ Strengths:**', content)
    content = re.sub(r'\*❌ Critical Gaps:\*', '**❌ Critical Gaps:**', content)
    content = re.sub(r'\*Task (\d+\.\d+):', r'**Task \1:', content)
    content = re.sub(r'\*Success Criteria:\*', '**Success Criteria:**', content)
    content = re.sub(r'\*Test Scenarios', r'**Test Scenarios', content)
    content = re.sub(r'\*Subtasks:\*', '**Subtasks:**', content)
    content = re.sub(r'\*Implementation:\*', '**Implementation:**', content)
    content = re.sub(r'\*Integration Points:\*', '**Integration Points:**', content)
    content = re.sub(r'\*Features:\*', '**Features:**', content)
    content = re.sub(r'\*Files to modify:\*', '**Files to modify:**', content)
    content = re.sub(r'\*UI Changes:\*', '**UI Changes:**', content)
    content = re.sub(r'\*Achievement Ideas:\*', '**Achievement Ideas:**', content)
    content = re.sub(r'\*Fixes:\*', '**Fixes:**', content)
    
    # Add dividers between PHASE sections
    content = re.sub(r'\n(PHASE \d+:)', r'\n---\n\n\1', content)
    
    # Add dividers between major Task groups
    content = re.sub(
        r'(Success Criteria:\n(?:.*\n)*?)\n(Task \d+\.\d+:)',
        r'\1\n---\n\n\2',
        content
    )
    
    # Clean up multiple consecutive blank lines
    content = re.sub(r'\n{3,}', '\n\n', content)
    
    return content

def main():
    input_file = 'CODE_REVIEW.md'
    output_file = 'CODE_REVIEW.md'
    
    print(f"Reading {input_file}...")
    with open(input_file, 'r', encoding='utf-8') as f:
        content = f.read()
    
    print("Fixing markdown formatting...")
    fixed_content = fix_markdown(content)
    
    print(f"Writing to {output_file}...")
    with open(output_file, 'w', encoding='utf-8') as f:
        f.write(fixed_content)
    
    print("✅ Done! Markdown formatting fixed.")
    print("\nChanges made:")
    print("- Fixed dividers (-- → ---)")
    print("- Fixed bold formatting (*text* → **text**)")
    print("- Fixed checkbox syntax (-[ ] → - [ ])")
    print("- Added blank lines around headers")
    print("- Added dividers between major sections")
    print("- Cleaned up multiple blank lines")

if __name__ == '__main__':
    main()
