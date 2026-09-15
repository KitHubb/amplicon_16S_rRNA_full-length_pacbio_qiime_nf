#!/usr/bin/env python3
"""Reject mismatched tags and emit only the matching changelog section."""
import re
import sys
from pathlib import Path

tag = sys.argv[1]
version = re.search(r"version = '([^']+)'", Path('nextflow.config').read_text()).group(1)
if tag != f'v{version}':
    sys.exit(f'Tag {tag} does not match manifest version {version}')
match = re.search(rf'^## \[{re.escape(version)}\][^\n]*\n(.*?)(?=^## |\Z)',
                  Path('CHANGELOG.md').read_text(), re.M | re.S)
if not match or not match.group(1).strip():
    sys.exit(f'Missing release notes for {version}')
print(match.group(1).strip())
