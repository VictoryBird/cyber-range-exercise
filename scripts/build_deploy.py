#!/usr/bin/env python3
"""
build_deploy.py — 모든 주석 제거 빌드 스크립트

assets/ 디렉토리의 파일에서 모든 주석을 제거하여 deploy/ 디렉토리에 출력한다.
코드와 설정값은 보존하고, 주석만 제거한다.

사용법:
    python3 scripts/build_deploy.py                      # 전체 빌드
    python3 scripts/build_deploy.py --asset 01_외부포털서버  # 단일 자산
    python3 scripts/build_deploy.py --dry-run              # 미리보기
    python3 scripts/build_deploy.py --report               # 상세 리포트
"""

import argparse
import os
import re
import shutil
import stat
import sys
from pathlib import Path

# ─── 파일 타입별 주석 구문 ──────────────────────────────────────

# 단일 줄 주석 접두사
COMMENT_PREFIXES = {
    '.py': ['#'], '.sh': ['#'], '.conf': ['#', ';'], '.cfg': ['#'],
    '.ps1': ['#'], '.env': ['#'], '.example': ['#'],
    '.php': ['//', '#'], '.js': ['//'], '.jsx': ['//'],
    '.java': ['//'], '.ts': ['//'], '.tsx': ['//'],
    '.sql': ['--'], '.jsp': ['//'],
    '.cf': ['#'], '.ext': ['#'],
    '.service': ['#'], '.timer': ['#'], '.txt': ['#'],
    '.yml': ['#'], '.yaml': ['#'], '.properties': ['#'],
    '.ini': ['#'], '.css': ['//'],
}

# 블록 주석 지원 파일 타입
BLOCK_COMMENT_TYPES = {
    'c_style': {'.js', '.jsx', '.java', '.php', '.ts', '.tsx', '.css', '.jsp'},
    'xml_style': {'.xml', '.xcu', '.html', '.htm', '.xsl'},
    'python_docstring': {'.py'},
}

# 텍스트로 처리할 확장자
TEXT_EXTENSIONS = {
    '.py', '.sh', '.conf', '.cfg', '.ps1', '.php', '.js', '.jsx',
    '.java', '.ts', '.tsx', '.sql', '.xml', '.xcu', '.html', '.htm',
    '.css', '.yaml', '.yml', '.json', '.md', '.txt', '.env',
    '.example', '.ini', '.toml', '.properties', '.service',
    '.timer', '.desktop', '.xsl', '.jsp', '.cf', '.ext',
}

# 주석 제거 제외 대상 (shebang, encoding 선언 등)
KEEP_PATTERNS = [
    re.compile(r'^#!'),           # shebang (#!/bin/bash, #!/usr/bin/env python3)
    re.compile(r'^#.*coding[:=]'), # -*- coding: utf-8 -*-
]


def is_text_file(path: Path) -> bool:
    if path.suffix.lower() in TEXT_EXTENSIONS:
        return True
    if path.name in {'.env.example', 'Makefile', 'Dockerfile', 'Vagrantfile'}:
        return True
    if not path.suffix:
        try:
            with open(path, 'r', encoding='utf-8') as f:
                f.read(1024)
                return True
        except (UnicodeDecodeError, OSError, PermissionError):
            pass
    return False


def should_keep_line(line: str) -> bool:
    """shebang 등 보존해야 할 줄인지 확인."""
    stripped = line.strip()
    return any(p.match(stripped) for p in KEEP_PATTERNS)


def is_pure_comment_line(line: str, ext: str) -> bool:
    """줄 전체가 주석인지 확인."""
    stripped = line.strip()
    if not stripped:
        return False

    # 단일 줄 주석
    prefixes = COMMENT_PREFIXES.get(ext, [])
    for prefix in prefixes:
        if stripped.startswith(prefix):
            return True

    # C-style 블록 주석 줄 (* 로 시작하는 줄)
    if ext in BLOCK_COMMENT_TYPES.get('c_style', set()):
        if stripped.startswith('*') or stripped.startswith('/*') or stripped.startswith('*/'):
            return True

    # XML 주석 줄
    if ext in BLOCK_COMMENT_TYPES.get('xml_style', set()):
        if stripped.startswith('<!--') or stripped.startswith('-->'):
            return True

    return False


def strip_inline_comment(line: str, ext: str) -> str:
    """코드 뒤의 인라인 주석을 제거하고 코드 부분만 반환."""
    prefixes = COMMENT_PREFIXES.get(ext, [])
    for prefix in prefixes:
        pattern = re.compile(r'^(.+?\S)\s+(' + re.escape(prefix) + r'\s.*)$')
        m = pattern.match(line)
        if m:
            code_part = m.group(1)
            # 문자열 내부의 # 오탐 방지
            if ext == '.py':
                for q in ['"', "'"]:
                    if code_part.count(q) % 2 != 0:
                        continue
            return code_part
    return line


def strip_all_comments(content: str, ext: str) -> tuple[str, int]:
    """파일 내용에서 모든 주석을 제거. 반환: (처리된 내용, 제거된 줄 수)"""
    lines = content.split('\n')
    result = []
    stripped_count = 0
    in_block_comment = False
    in_docstring = False

    i = 0
    while i < len(lines):
        line = lines[i]
        stripped = line.strip()

        # ── 보존 대상 (shebang 등) ──
        if i < 3 and should_keep_line(line):
            result.append(line)
            i += 1
            continue

        # ── C-style 블록 주석 (/* ... */) ──
        if ext in BLOCK_COMMENT_TYPES.get('c_style', set()):
            if in_block_comment:
                stripped_count += 1
                if '*/' in line:
                    in_block_comment = False
                    # */ 뒤에 코드가 있으면 보존
                    after = line[line.index('*/') + 2:]
                    if after.strip():
                        result.append(after)
                i += 1
                continue

            if '/*' in stripped:
                if '*/' in stripped:
                    # 한 줄 블록 주석
                    before = line[:line.index('/*')]
                    after = line[line.index('*/') + 2:]
                    combined = (before + after).rstrip()
                    if combined.strip():
                        result.append(combined)
                    stripped_count += 1
                    i += 1
                    continue
                else:
                    # 블록 주석 시작
                    before = line[:line.index('/*')]
                    if before.strip():
                        result.append(before.rstrip())
                    in_block_comment = True
                    stripped_count += 1
                    i += 1
                    continue

        # ── XML 블록 주석 (<!-- ... -->) ──
        if ext in BLOCK_COMMENT_TYPES.get('xml_style', set()):
            if in_block_comment:
                stripped_count += 1
                if '-->' in line:
                    in_block_comment = False
                    after = line[line.index('-->') + 3:]
                    if after.strip():
                        result.append(after)
                i += 1
                continue

            if '<!--' in stripped:
                if '-->' in stripped:
                    before = line[:line.index('<!--')]
                    after = line[line.index('-->') + 3:]
                    combined = (before + after).rstrip()
                    if combined.strip():
                        result.append(combined)
                    stripped_count += 1
                    i += 1
                    continue
                else:
                    before = line[:line.index('<!--')]
                    if before.strip():
                        result.append(before.rstrip())
                    in_block_comment = True
                    stripped_count += 1
                    i += 1
                    continue

        # ── Python 독스트링 (""" ... """) ──
        if ext == '.py':
            if in_docstring:
                stripped_count += 1
                if '"""' in stripped or "'''" in stripped:
                    in_docstring = False
                i += 1
                continue

            if stripped.startswith('"""') or stripped.startswith("'''"):
                quote = stripped[:3]
                if stripped.count(quote) >= 2 and len(stripped) > 3:
                    # 한 줄 독스트링
                    stripped_count += 1
                    i += 1
                    continue
                else:
                    in_docstring = True
                    stripped_count += 1
                    i += 1
                    continue

        # ── 순수 주석 줄 ──
        if is_pure_comment_line(line, ext) and not should_keep_line(line):
            stripped_count += 1
            i += 1
            continue

        # ── 인라인 주석 제거 ──
        cleaned = strip_inline_comment(line, ext)
        if cleaned != line:
            stripped_count += 1
            result.append(cleaned)
            i += 1
            continue

        # ── 일반 줄: 유지 ──
        result.append(line)
        i += 1

    # 연속 빈 줄 3줄 이상 → 2줄로 축소
    output = '\n'.join(result)
    output = re.sub(r'\n{4,}', '\n\n\n', output)

    return output, stripped_count


def process_file(src: Path, dst: Path, stats: dict) -> None:
    dst.parent.mkdir(parents=True, exist_ok=True)

    if not is_text_file(src):
        shutil.copy2(src, dst)
        stats['copied'] += 1
        return

    try:
        content = src.read_text(encoding='utf-8')
    except (UnicodeDecodeError, PermissionError):
        shutil.copy2(src, dst)
        stats['copied'] += 1
        return

    ext = src.suffix.lower()
    processed, count = strip_all_comments(content, ext)

    dst.write_text(processed, encoding='utf-8')

    src_stat = src.stat()
    if src_stat.st_mode & stat.S_IXUSR:
        dst.chmod(dst.stat().st_mode | stat.S_IXUSR | stat.S_IXGRP | stat.S_IXOTH)

    if count > 0:
        stats['stripped_files'] += 1
        stats['stripped_lines'] += count
        stats['details'].append((str(src.relative_to(stats['base'])), count))
    else:
        stats['unchanged'] += 1


def build_deploy(source_dir: Path, output_dir: Path,
                 asset_filter: str = None, dry_run: bool = False,
                 report: bool = False) -> dict:
    stats = {
        'base': source_dir,
        'stripped_files': 0,
        'stripped_lines': 0,
        'unchanged': 0,
        'copied': 0,
        'details': [],
    }

    if not dry_run:
        if output_dir.exists():
            shutil.rmtree(output_dir)
        output_dir.mkdir(parents=True)

    asset_dirs = sorted(source_dir.iterdir())
    if asset_filter:
        asset_dirs = [d for d in asset_dirs if d.name == asset_filter]
        if not asset_dirs:
            print(f"[ERROR] Asset not found: {asset_filter}")
            sys.exit(1)

    for asset_dir in asset_dirs:
        if not asset_dir.is_dir():
            continue

        print(f"  Processing: {asset_dir.name}")

        for src_file in sorted(asset_dir.rglob('*')):
            if not src_file.is_file():
                continue
            if any(part.startswith('.') and part != '.env.example'
                   for part in src_file.relative_to(source_dir).parts):
                continue

            rel = src_file.relative_to(source_dir)
            dst_file = output_dir / rel

            if dry_run:
                if is_text_file(src_file):
                    try:
                        content = src_file.read_text(encoding='utf-8')
                        ext = src_file.suffix.lower()
                        _, count = strip_all_comments(content, ext)
                        if count > 0:
                            stats['stripped_files'] += 1
                            stats['stripped_lines'] += count
                            stats['details'].append((str(rel), count))
                        else:
                            stats['unchanged'] += 1
                    except (UnicodeDecodeError, PermissionError):
                        stats['copied'] += 1
                else:
                    stats['copied'] += 1
            else:
                process_file(src_file, dst_file, stats)

    print()
    print("=" * 50)
    print(f"  Comment stripping {'(DRY-RUN) ' if dry_run else ''}complete")
    print("=" * 50)
    print(f"  Files stripped: {stats['stripped_files']}")
    print(f"  Lines removed:  {stats['stripped_lines']}")
    print(f"  Unchanged:      {stats['unchanged']}")
    print(f"  Binary copied:  {stats['copied']}")
    print()

    if report or dry_run:
        print("--- Detail Report ---")
        for path, count in sorted(stats['details'], key=lambda x: -x[1]):
            print(f"  {count:4d} lines  {path}")
        print()

    if not dry_run and stats['details']:
        report_path = output_dir / '.strip-report.txt'
        with open(report_path, 'w', encoding='utf-8') as f:
            f.write(f"# Comment stripping report\n")
            f.write(f"# {stats['stripped_files']} files, "
                    f"{stats['stripped_lines']} lines removed\n\n")
            for path, count in sorted(stats['details'], key=lambda x: -x[1]):
                f.write(f"{count:4d}  {path}\n")

    return stats


def main():
    parser = argparse.ArgumentParser(description='Strip all comments from source files')
    parser.add_argument('--source', default='assets/', help='Source directory (default: assets/)')
    parser.add_argument('--output', default='deploy/', help='Output directory (default: deploy/)')
    parser.add_argument('--asset', default=None, help='Process single asset (e.g. 01_외부포털서버)')
    parser.add_argument('--dry-run', action='store_true', help='Preview only, no file output')
    parser.add_argument('--report', action='store_true', help='Show detailed report')
    args = parser.parse_args()

    project_root = Path(__file__).resolve().parent.parent
    source = project_root / args.source
    output = project_root / args.output

    if not source.exists():
        print(f"[ERROR] Source directory not found: {source}")
        sys.exit(1)

    print(f"Source: {source}")
    print(f"Output: {output}")
    if args.asset:
        print(f"Asset:  {args.asset}")
    print()

    build_deploy(source, output, args.asset, args.dry_run, args.report)


if __name__ == '__main__':
    main()
