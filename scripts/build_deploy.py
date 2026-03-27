#!/usr/bin/env python3
"""
build_deploy.py — 취약점 주석 제거 빌드 스크립트

assets/ 디렉토리의 파일에서 취약점 관련 주석만 선택적으로 제거하여
deploy/ 디렉토리에 출력한다. 일반 주석과 코드는 보존된다.

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

# ─── 취약점 마커 패턴 ───────────────────────────────────────────

# 줄 내에서 취약점 관련 여부를 판별하는 정규식
VULN_MARKERS = re.compile(
    r'\[취약'             # [취약점], [취약점 #1], [취약 설정], [취약 설정 힌트], [취약: ...] 등
    r'|VULN-\w+-?\d+'    # VULN-06-01, VULN-AdminAPI 등
    r'|\[올바른'          # [올바른 구현], [올바른 설정] 등
    r'|올바른 구현[:\s\]]' # 올바른 구현: ...
    r'|올바른 설정[:\s\]]' # 올바른 설정: ...
    r'|올바른 값[:\s\]]'   # 올바른 값: ...
    r'|안전한 구현[:\s]'  # 안전한 구현: ...
    r'|안전 버전[:\s]'    # 안전 버전: ...
    r'|정상 구현[:\s]'    # 정상 구현: ...
)

# 출력 명령(echo, Write-Host, console.log, print)에서 취약점 힌트 감지
ECHO_VULN = re.compile(
    r'(echo\s|Write-Host\s|console\.log\s*\(|print\s*\()'
    r'.*(★\s*주의.*VULN|\[취약)', re.IGNORECASE
)

# 연속 주석에서 올바른 구현 후속 줄 패턴 (들여쓰기된 설명)
CONTINUATION_HINT = re.compile(
    r'^\s*(#|//|--|\*|<!--)\s*'
    r'([-·]\s|예[:\s]|예시[:\s]|정상[:\s]|안전[:\s]|올바른[:\s]'
    r'|from\s|import\s|permission_classes|IsAuthenticated'
    r'|slowapi|bcrypt|prepared\s|parameterized'
    r'|seccomp|chroot|sandbox|격리|마스킹|해시|필터)'
)

# ─── 파일 타입별 주석 구문 ──────────────────────────────────────

# 단일 줄 주석 접두사 (확장자 → 접두사 리스트)
LINE_COMMENT_PREFIXES = {
    '.py': ['#'], '.sh': ['#'], '.conf': ['#', ';'], '.cfg': ['#'],
    '.ps1': ['#'], '.env': ['#'], '.example': ['#'],
    '.php': ['//', '#'], '.js': ['//'], '.jsx': ['//'],
    '.java': ['//'], '.ts': ['//'], '.tsx': ['//'],
    '.sql': ['--'],
    '.jsp': ['//'], '.cf': ['#'], '.ext': ['#'],
    '.service': ['#'], '.timer': ['#'], '.txt': ['#'],
    '.yml': ['#'], '.yaml': ['#'], '.properties': ['#'],
    '.ini': ['#'], '.html': ['//'],
}

# 텍스트로 처리할 확장자 (이외는 바이너리로 복사)
TEXT_EXTENSIONS = {
    '.py', '.sh', '.conf', '.cfg', '.ps1', '.php', '.js', '.jsx',
    '.java', '.ts', '.tsx', '.sql', '.xml', '.xcu', '.html', '.htm',
    '.css', '.yaml', '.yml', '.json', '.md', '.txt', '.env',
    '.example', '.ini', '.toml', '.properties', '.service',
    '.timer', '.desktop', '.xsl',
    '.jsp', '.cf', '.ext',
}

# ─── 유틸리티 ───────────────────────────────────────────────────

def is_text_file(path: Path) -> bool:
    """확장자 기반으로 텍스트 파일 여부 판별."""
    if path.suffix.lower() in TEXT_EXTENSIONS:
        return True
    if path.name in {'.env.example', 'Makefile', 'Dockerfile', 'Vagrantfile'}:
        return True
    # 확장자 없는 파일: UTF-8 디코딩 시도
    if not path.suffix:
        try:
            with open(path, 'r', encoding='utf-8') as f:
                f.read(1024)
                return True
        except (UnicodeDecodeError, OSError, PermissionError):
            pass
    return False


def has_vuln_marker(line: str) -> bool:
    """줄에 취약점 마커가 포함되어 있는지 확인."""
    return bool(VULN_MARKERS.search(line))


def is_echo_vuln(line: str) -> bool:
    """echo 줄이 취약점 경고인지 확인."""
    return bool(ECHO_VULN.search(line))


def is_comment_line(line: str, ext: str) -> bool:
    """줄 전체가 주석인지 확인 (코드 없이 주석만 있는 줄)."""
    stripped = line.strip()
    if not stripped:
        return False

    prefixes = LINE_COMMENT_PREFIXES.get(ext, [])
    for prefix in prefixes:
        if stripped.startswith(prefix):
            return True

    # XML/HTML 주석
    if ext in ('.xml', '.xcu', '.html', '.htm', '.xsl'):
        if stripped.startswith('<!--') or stripped.startswith('*') or stripped.startswith('-->'):
            return True

    # JS/Java/PHP/JSP 블록 주석 줄
    if ext in ('.js', '.jsx', '.java', '.php', '.ts', '.tsx', '.css', '.jsp'):
        if stripped.startswith('*') or stripped.startswith('/*') or stripped.startswith('*/'):
            return True

    return False


def get_inline_comment_split(line: str, ext: str):
    """
    코드 + 인라인 주석 줄을 (코드 부분, 주석 부분)으로 분리.
    인라인 주석이 없으면 None 반환.
    """
    prefixes = LINE_COMMENT_PREFIXES.get(ext, [])
    for prefix in prefixes:
        # 코드 뒤에 공백 + 주석 패턴 찾기
        pattern = re.compile(
            r'^(.+?\S)\s+(' + re.escape(prefix) + r'\s*.*)$'
        )
        m = pattern.match(line)
        if m:
            code_part = m.group(1)
            comment_part = m.group(2)
            # 문자열 리터럴 내부의 # 오탐 방지: 코드에 열린 따옴표가 있으면 건너뜀
            if ext == '.py':
                quote_count = code_part.count("'") + code_part.count('"')
                if quote_count % 2 != 0:
                    continue
            return code_part, comment_part
    return None


def is_continuation_of_stripped(line: str, ext: str) -> bool:
    """이전 취약점 주석의 연속 줄인지 확인."""
    if not is_comment_line(line, ext):
        return False
    return bool(CONTINUATION_HINT.search(line))


# ─── 메인 처리 ──────────────────────────────────────────────────

def strip_vuln_comments(content: str, ext: str) -> tuple[str, int]:
    """
    파일 내용에서 취약점 관련 주석을 제거.
    반환: (처리된 내용, 제거된 줄 수)
    """
    lines = content.split('\n')
    result = []
    stripped_count = 0
    prev_stripped = False
    in_vuln_block_comment = False

    i = 0
    while i < len(lines):
        line = lines[i]

        # ── XML/HTML 블록 주석 처리 ──
        if ext in ('.xml', '.xcu', '.html', '.htm', '.xsl'):
            if '<!--' in line and '-->' not in line:
                # 블록 주석 시작 — 끝까지 수집
                block = [line]
                j = i + 1
                while j < len(lines) and '-->' not in lines[j]:
                    block.append(lines[j])
                    j += 1
                if j < len(lines):
                    block.append(lines[j])

                block_text = '\n'.join(block)
                if has_vuln_marker(block_text):
                    stripped_count += len(block)
                    i = j + 1
                    prev_stripped = True
                    continue
                else:
                    result.extend(block)
                    i = j + 1
                    prev_stripped = False
                    continue

            # 한 줄 XML 주석
            if '<!--' in line and '-->' in line and has_vuln_marker(line):
                stripped_count += 1
                i += 1
                prev_stripped = True
                continue

        # ── JS/Java/PHP/JSP 블록 주석 처리 ──
        if ext in ('.js', '.jsx', '.java', '.php', '.ts', '.tsx', '.css', '.jsp'):
            stripped_line = line.strip()
            if stripped_line.startswith('/*') and '*/' not in stripped_line:
                block = [line]
                j = i + 1
                while j < len(lines) and '*/' not in lines[j]:
                    block.append(lines[j])
                    j += 1
                if j < len(lines):
                    block.append(lines[j])

                block_text = '\n'.join(block)
                if has_vuln_marker(block_text):
                    stripped_count += len(block)
                    i = j + 1
                    prev_stripped = True
                    continue
                else:
                    result.extend(block)
                    i = j + 1
                    prev_stripped = False
                    continue

        # ── Python 독스트링 처리 ──
        if ext == '.py':
            stripped_line_py = line.strip()
            # 한 줄 독스트링: """...[취약점]...""" → [취약점] 부분 제거
            if stripped_line_py.startswith('"""') and stripped_line_py.endswith('"""') and len(stripped_line_py) > 6:
                if has_vuln_marker(line):
                    cleaned = re.sub(r'\s*\[취약[^\]]*\][^\"]*', '', line)
                    cleaned = re.sub(r'\s*—\s*$', '', cleaned)
                    result.append(cleaned)
                    stripped_count += 1
                    i += 1
                    prev_stripped = False
                    continue
                result.append(line)
                i += 1
                prev_stripped = False
                continue
            if stripped_line_py.startswith('"""') and (stripped_line_py == '"""' or not stripped_line_py.endswith('"""')):
                # 독스트링 시작 → 끝까지 수집
                block = [line]
                j = i + 1
                while j < len(lines) and '"""' not in lines[j]:
                    block.append(lines[j])
                    j += 1
                if j < len(lines):
                    block.append(lines[j])

                block_text = '\n'.join(block)
                if has_vuln_marker(block_text):
                    # 독스트링 내에서 취약점 줄만 제거, 나머지 유지
                    filtered_block = []
                    skip_continuation = False
                    for bline in block:
                        if has_vuln_marker(bline):
                            stripped_count += 1
                            skip_continuation = True
                            continue
                        bline_stripped = bline.strip()
                        # 빈 줄은 skip_continuation 유지한 채로 통과
                        if skip_continuation and not bline_stripped:
                            stripped_count += 1
                            continue
                        if skip_continuation:
                            if (bline_stripped.startswith('올바른') or
                                bline_stripped.startswith('안전') or
                                bline_stripped.startswith('정상') or
                                bline_stripped.startswith('- ') and any(
                                    kw in bline for kw in ['올바른', '안전', '정상', 'prepared',
                                                           'sandbox', 'seccomp', 'fastapi',
                                                           'slowapi', 'exclude', 'include'])):
                                stripped_count += 1
                                continue
                            if bline_stripped.startswith(('-', '·', 'from ', 'import ',
                                                         'permission', 'exclude', 'include')):
                                stripped_count += 1
                                continue
                            skip_continuation = False
                        filtered_block.append(bline)
                    result.extend(filtered_block)
                    i = j + 1
                    prev_stripped = False
                    continue
                else:
                    result.extend(block)
                    i = j + 1
                    prev_stripped = False
                    continue

        # ── echo/print 취약점 경고 줄 ──
        if is_echo_vuln(line):
            stripped_count += 1
            i += 1
            prev_stripped = True
            continue

        # ── echo 줄에 [취약점] 태그 ──
        stripped_line = line.strip()
        if stripped_line.startswith('echo') and has_vuln_marker(line):
            stripped_count += 1
            i += 1
            prev_stripped = True
            continue

        # ── 주석 전용 줄 + 취약점 마커 ──
        if is_comment_line(line, ext) and has_vuln_marker(line):
            stripped_count += 1
            i += 1
            prev_stripped = True
            continue

        # ── 순수 텍스트 줄 (독스트링/주석 블록 외부)에서 취약점 마커 ──
        # 코드가 아닌 빈 공백+마커만 있는 줄 (독스트링 내부 등)
        if has_vuln_marker(line) and stripped_line and not any(
            c.isalnum() and c not in '취약점설정올바른안전정상구현값VULNCWEcwe'
            for word in stripped_line.split()[:1]
            for c in word
            if not stripped_line.startswith(('[취약', 'VULN', '올바른', '안전', '정상'))
        ):
            # 줄이 취약점 마커로 시작하면 제거
            if (stripped_line.startswith('[취약') or
                stripped_line.startswith('VULN') or
                stripped_line.startswith('올바른') or
                stripped_line.startswith('안전') or
                stripped_line.startswith('정상')):
                stripped_count += 1
                i += 1
                prev_stripped = True
                continue

        # ── 이전 줄이 삭제된 후 연속 주석 ──
        if prev_stripped and is_continuation_of_stripped(line, ext):
            stripped_count += 1
            i += 1
            continue

        # ── 이전 줄이 삭제된 후 연속 주석 (범용) ──
        if prev_stripped and has_vuln_marker(line):
            stripped_count += 1
            i += 1
            continue

        # ── 이전 줄이 삭제된 후 연속 텍스트 줄 (독스트링 내부) ──
        if prev_stripped and stripped_line:
            if (stripped_line.startswith('올바른') or
                stripped_line.startswith('안전') or
                stripped_line.startswith('정상') or
                stripped_line.startswith('- ') and any(
                    kw in line for kw in ['올바른', '안전', '정상', 'prepared',
                                           'sandbox', 'seccomp', 'bcrypt'])):
                stripped_count += 1
                i += 1
                continue

        # ── 인라인 주석에 취약점 마커 → 주석만 제거 ──
        split = get_inline_comment_split(line, ext)
        if split:
            code_part, comment_part = split
            if has_vuln_marker(comment_part):
                result.append(code_part)
                stripped_count += 1
                i += 1
                prev_stripped = False
                continue

        # ── 범용 폴백: 주석 접두사(#, //, *, --, <!--) + 취약점 마커 ──
        # 파일 확장자와 무관하게 모든 텍스트 파일에서 적용
        if has_vuln_marker(line):
            s = stripped_line if 'stripped_line' in dir() else line.strip()
            # 주석 접두사로 시작하는 줄
            if any(s.startswith(p) for p in ('#', '//', '*', '--', '<!--', 'echo', ';', '{/*')):
                stripped_count += 1
                i += 1
                prev_stripped = True
                continue

        # ── 일반 줄: 유지 ──
        result.append(line)
        prev_stripped = False
        i += 1

    # 연속 빈 줄 3줄 이상 → 2줄로 축소
    output = '\n'.join(result)
    output = re.sub(r'\n{4,}', '\n\n\n', output)

    return output, stripped_count


def process_file(src: Path, dst: Path, stats: dict) -> None:
    """파일 하나를 처리하여 출력 경로에 기록."""
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
    processed, count = strip_vuln_comments(content, ext)

    dst.write_text(processed, encoding='utf-8')

    # 실행 권한 보존
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
    """메인 빌드 함수."""
    stats = {
        'base': source_dir,
        'stripped_files': 0,
        'stripped_lines': 0,
        'unchanged': 0,
        'copied': 0,
        'details': [],
    }

    # 출력 디렉토리 준비
    if not dry_run:
        if output_dir.exists():
            shutil.rmtree(output_dir)
        output_dir.mkdir(parents=True)

    # 자산 디렉토리 목록
    asset_dirs = sorted(source_dir.iterdir())
    if asset_filter:
        asset_dirs = [d for d in asset_dirs if d.name == asset_filter]
        if not asset_dirs:
            print(f"[ERROR] 자산을 찾을 수 없음: {asset_filter}")
            sys.exit(1)

    for asset_dir in asset_dirs:
        if not asset_dir.is_dir():
            continue

        print(f"  처리 중: {asset_dir.name}")

        for src_file in sorted(asset_dir.rglob('*')):
            if not src_file.is_file():
                continue
            # 숨김 파일/디렉토리 건너뛰기 (.git 등)
            if any(part.startswith('.') and part != '.env.example'
                   for part in src_file.relative_to(source_dir).parts):
                continue

            rel = src_file.relative_to(source_dir)
            dst_file = output_dir / rel

            if dry_run:
                # dry-run: 제거될 줄만 카운트
                if is_text_file(src_file):
                    try:
                        content = src_file.read_text(encoding='utf-8')
                        ext = src_file.suffix.lower()
                        _, count = strip_vuln_comments(content, ext)
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

    # 리포트 출력
    print()
    print("=" * 50)
    print(f"  주석 제거 빌드 {'(DRY-RUN) ' if dry_run else ''}완료")
    print("=" * 50)
    print(f"  제거된 파일 수: {stats['stripped_files']}")
    print(f"  제거된 줄 수:   {stats['stripped_lines']}")
    print(f"  변경 없는 파일: {stats['unchanged']}")
    print(f"  바이너리 복사:  {stats['copied']}")
    print()

    if report or dry_run:
        print("─── 상세 리포트 ───")
        for path, count in sorted(stats['details'], key=lambda x: -x[1]):
            print(f"  {count:4d}줄 제거  {path}")
        print()

    # 리포트 파일 저장
    if not dry_run and stats['details']:
        report_path = output_dir / '.strip-report.txt'
        with open(report_path, 'w', encoding='utf-8') as f:
            f.write("# 취약점 주석 제거 리포트\n")
            f.write(f"# 총 {stats['stripped_files']}개 파일에서 "
                    f"{stats['stripped_lines']}줄 제거\n\n")
            for path, count in sorted(stats['details'], key=lambda x: -x[1]):
                f.write(f"{count:4d}줄  {path}\n")

    return stats


# ─── CLI ────────────────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(
        description='취약점 주석 제거 빌드 스크립트')
    parser.add_argument('--source', default='assets/',
                        help='소스 디렉토리 (기본: assets/)')
    parser.add_argument('--output', default='deploy/',
                        help='출력 디렉토리 (기본: deploy/)')
    parser.add_argument('--asset', default=None,
                        help='특정 자산만 처리 (예: 01_외부포털서버)')
    parser.add_argument('--dry-run', action='store_true',
                        help='미리보기 (파일 미생성)')
    parser.add_argument('--report', action='store_true',
                        help='상세 리포트 출력')
    args = parser.parse_args()

    # 프로젝트 루트 기준 경로
    project_root = Path(__file__).resolve().parent.parent
    source = project_root / args.source
    output = project_root / args.output

    if not source.exists():
        print(f"[ERROR] 소스 디렉토리 없음: {source}")
        sys.exit(1)

    print(f"소스: {source}")
    print(f"출력: {output}")
    if args.asset:
        print(f"자산: {args.asset}")
    print()

    build_deploy(source, output, args.asset, args.dry_run, args.report)


if __name__ == '__main__':
    main()
