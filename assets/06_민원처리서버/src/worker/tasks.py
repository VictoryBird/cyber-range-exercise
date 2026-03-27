"""
민원 첨부파일 처리 Celery 작업 모듈.

이 파일은 공격 체인의 핵심 실행 지점을 포함한다.
파일 변환 과정에서 발생하는 RCE가 전체 훈련의 메인 공격 벡터이다.

처리 흐름:
  1. MinIO에서 파일 다운로드
  2. python-magic + 확장자로 파일 타입 감지
  3. 문서: LibreOffice 6.4.7로 PDF 변환 [취약: 매크로 실행]
  4. 이미지: Pillow 8.4.0으로 리사이즈/썸네일 [취약: CVE]
  5. 결과를 MinIO에 업로드, DB에 기록

[취약점] VULN-06-05: 파일 처리 시 샌드박싱 없음, 서비스 사용자 권한으로 직접 실행
  올바른 구현: 격리된 컨테이너/chroot 환경에서 파일 처리, seccomp 필터 적용
[취약점] VULN-06-06: 서비스 계정이 INT 전체 서브넷에 접근 가능
  올바른 구현: 네트워크 네임스페이스 격리, 필요한 대상만 허용
"""

import os
import time
import shutil
import logging
import subprocess
import traceback
from datetime import datetime
from typing import Dict, Any, List, Optional

import magic
from PIL import Image
from celery_app import app
from storage import MinIOClient
from database import update_complaint_status, record_processing_result

logger = logging.getLogger("complaint_worker")

# ---------------------------------------------------------------------------
# 파일 타입 매핑
# ---------------------------------------------------------------------------
# [취약점] 확장자 기반 매핑으로, 실제 파일 내용과 무관하게 처리 방식 결정
EXTENSION_TO_HANDLER = {
    # 문서 파일 -> LibreOffice PDF 변환
    ".doc": "document",
    ".docx": "document",
    ".hwp": "document",
    ".hwpx": "document",
    ".odt": "document",
    ".rtf": "document",
    ".xls": "document",
    ".xlsx": "document",
    ".ppt": "document",
    ".pptx": "document",
    # 이미지 파일 -> Pillow 리사이즈/썸네일
    ".jpg": "image",
    ".jpeg": "image",
    ".png": "image",
    ".gif": "image",
    ".bmp": "image",
    ".tiff": "image",
    ".tif": "image",
    # PDF -> 변환 불필요, 썸네일만 생성
    ".pdf": "pdf",
}

# 이미지 리사이즈 설정
MAX_IMAGE_WIDTH = 1920
MAX_IMAGE_HEIGHT = 1080
THUMBNAIL_SIZE = (300, 300)

# LibreOffice 경로
LIBREOFFICE_PATH = os.getenv("LIBREOFFICE_PATH", "/usr/bin/soffice")


# ===========================================================================
# 파일 타입 감지
# ===========================================================================
def detect_file_type(file_path: str) -> str:
    """
    파일 타입을 감지한다.

    [취약점] 확장자를 우선하여 핸들러를 결정한다.
    MIME 타입은 로깅 목적으로만 사용하며, 확장자와 불일치해도 경고만 출력한다.
    올바른 구현: MIME 타입과 확장자를 교차 검증하고, 불일치 시 처리 거부
    """
    _, ext = os.path.splitext(file_path)
    ext = ext.lower()

    # 확장자 기반 핸들러 조회 (우선)
    handler = EXTENSION_TO_HANDLER.get(ext)

    if handler:
        # [취약점] 확장자만으로 핸들러 결정, MIME 타입은 로깅 목적으로만 사용
        # 올바른 구현: MIME 타입과 확장자 교차 검증
        try:
            mime_type = magic.from_file(file_path, mime=True)
            logger.info(f"파일 MIME 타입: {mime_type} (확장자: {ext})")
        except Exception as e:
            logger.warning(f"MIME 타입 감지 실패: {e}")
        return handler

    # 확장자가 매핑에 없는 경우: MIME 타입 기반 fallback
    try:
        mime_type = magic.from_file(file_path, mime=True)
        if mime_type.startswith("image/"):
            return "image"
        elif mime_type == "application/pdf":
            return "pdf"
        elif mime_type in (
            "application/msword",
            "application/vnd.openxmlformats-officedocument",
            "application/x-hwp",
        ):
            return "document"
    except Exception:
        pass

    return "unknown"


# ===========================================================================
# 문서 -> PDF 변환 (LibreOffice)
# ===========================================================================
def convert_document_to_pdf(file_path: str, work_dir: str) -> Optional[str]:
    """
    LibreOffice를 사용하여 문서를 PDF로 변환한다.

    [취약점] VULN-06-01: LibreOffice 6.4.7 매크로 자동 실행 (CVE-2021-25631 등)
    - --headless만 지정, 매크로 실행 차단 옵션(--infilter) 없음
    - MacroSecurityLevel이 0으로 설정되어 모든 매크로 무조건 실행
    - /tmp/processing이 신뢰 경로에 포함되어 매크로 자동 실행
    - shell=True로 명령 인젝션 가능
    - 환경변수 격리 없음 (워커의 모든 환경변수 접근 가능)
    올바른 구현:
    - 최신 LibreOffice 사용
    - --infilter=writer_pdf_Export 로 매크로 차단
    - shell=False + 리스트 형태 명령어
    - 격리된 환경(env, cwd)에서 실행
    """
    output_dir = os.path.join(work_dir, "converted")
    os.makedirs(output_dir, exist_ok=True)

    # [취약점] VULN-06-01: 파일명을 셸 명령에 직접 삽입 (명령 인젝션 가능)
    # [취약점] VULN-06-01: --infilter 미사용으로 매크로 실행 차단 안 됨
    # [취약점] VULN-06-01: --env:UserInstallation 미지정으로 공유 프로파일 사용
    # 올바른 구현:
    # cmd = [
    #     LIBREOFFICE_PATH,
    #     '--headless', '--norestore', '--nolockcheck', '--nologo',
    #     '--infilter=writer_pdf_Export',
    #     '--env:UserInstallation=file:///tmp/lo_sandbox_' + str(os.getpid()),
    #     '--convert-to', 'pdf',
    #     '--outdir', output_dir,
    #     file_path
    # ]
    # result = subprocess.run(cmd, shell=False, capture_output=True,
    #                         text=True, timeout=60,
    #                         env={"HOME": "/tmp/lo_sandbox"}, cwd="/tmp")
    cmd = (
        f'{LIBREOFFICE_PATH} --headless --norestore '
        f'--convert-to pdf '
        f'--outdir "{output_dir}" '
        f'"{file_path}"'
    )

    logger.info(f"LibreOffice 변환 시작: {cmd}")

    try:
        # [취약점] VULN-06-01: shell=True로 서브프로세스 실행 — 명령 인젝션 가능
        # [취약점] VULN-06-05: cwd, env 미지정으로 워커 환경 그대로 상속
        result = subprocess.run(
            cmd,
            shell=True,             # [취약점] VULN-06-01: 셸 인젝션
            capture_output=True,
            text=True,
            timeout=300,            # 5분 타임아웃
        )

        if result.returncode != 0:
            logger.error(f"LibreOffice 변환 실패: {result.stderr}")
            return None

        # 출력 파일 경로 생성
        base_name = os.path.splitext(os.path.basename(file_path))[0]
        pdf_path = os.path.join(output_dir, f"{base_name}.pdf")

        if os.path.exists(pdf_path):
            logger.info(f"PDF 변환 완료: {pdf_path}")
            return pdf_path
        else:
            logger.error("PDF 변환 결과 파일을 찾을 수 없음")
            return None

    except subprocess.TimeoutExpired:
        logger.error("LibreOffice 변환 타임아웃")
        return None
    except Exception as e:
        logger.error(f"LibreOffice 변환 중 오류: {e}")
        return None


# ===========================================================================
# 이미지 처리 (Pillow)
# ===========================================================================
def process_image(file_path: str, work_dir: str) -> List[str]:
    """
    이미지 파일을 처리한다 (리사이즈 + 썸네일 생성).

    [취약점] VULN-06-02: Pillow 8.4.0의 알려진 CVE
    - CVE-2022-22815: path 초기화 시 널 포인터 역참조
    - CVE-2022-22816: path 초기화 시 버퍼 오버리드
    - CVE-2022-22817: PIL.ImageMath.eval()을 통한 임의 코드 실행
    - Image.open()이 조작된 이미지 파일을 파싱할 때 버퍼 오버플로 발생 가능
    - img.verify() 미호출 — 손상된 파일 헤더 검증 없음
    올바른 구현: Pillow>=10.0.0 사용, img.verify() 호출, 파일 크기/해상도 제한
    """
    output_files = []
    resized_dir = os.path.join(work_dir, "converted")
    thumb_dir = os.path.join(work_dir, "thumbnails")
    os.makedirs(resized_dir, exist_ok=True)
    os.makedirs(thumb_dir, exist_ok=True)

    base_name = os.path.splitext(os.path.basename(file_path))[0]
    ext = os.path.splitext(file_path)[1].lower()

    try:
        # [취약점] VULN-06-02: Image.open()이 악성 파일을 파싱할 때 버퍼 오버플로 가능
        # [취약점] VULN-06-02: 이미지 파일 유효성 검증 없이 바로 open() 호출
        # 올바른 구현: img.verify() 호출 후, 다시 open()하여 처리
        img = Image.open(file_path)

        # 리사이즈 (최대 크기 제한)
        original_width, original_height = img.size
        if original_width > MAX_IMAGE_WIDTH or original_height > MAX_IMAGE_HEIGHT:
            ratio = min(
                MAX_IMAGE_WIDTH / original_width,
                MAX_IMAGE_HEIGHT / original_height,
            )
            new_size = (int(original_width * ratio), int(original_height * ratio))
            # [취약점] VULN-06-02: resize() 과정에서 조작된 이미지 데이터가
            #   디코딩되며 힙 오버플로 트리거 가능
            resized = img.resize(new_size, Image.LANCZOS)
        else:
            resized = img.copy()

        resized_path = os.path.join(resized_dir, f"{base_name}_resized{ext}")
        resized.save(resized_path)
        output_files.append(resized_path)
        logger.info(f"이미지 리사이즈 완료: {resized_path}")

        # 썸네일 생성
        thumb = img.copy()
        thumb.thumbnail(THUMBNAIL_SIZE, Image.LANCZOS)
        thumb_path = os.path.join(thumb_dir, f"{base_name}_thumb{ext}")
        thumb.save(thumb_path)
        output_files.append(thumb_path)
        logger.info(f"썸네일 생성 완료: {thumb_path}")

    except Exception as e:
        # [취약점] 예외 처리가 모든 예외를 잡으므로
        # RCE가 발생해도 워커가 크래시하지 않고 계속 실행될 수 있음
        logger.error(f"이미지 처리 실패: {e}")

    return output_files


# ===========================================================================
# PDF 썸네일 생성
# ===========================================================================
def generate_pdf_thumbnail(pdf_path: str, work_dir: str) -> Optional[str]:
    """
    PDF 파일의 첫 페이지 썸네일을 생성한다.

    [취약점] shell=True + 파일명 직접 삽입 (명령 인젝션 가능)
    올바른 구현: shell=False + 리스트 형태 명령어
    """
    thumb_dir = os.path.join(work_dir, "thumbnails")
    os.makedirs(thumb_dir, exist_ok=True)
    base_name = os.path.splitext(os.path.basename(pdf_path))[0]
    thumb_path = os.path.join(thumb_dir, f"{base_name}_thumb.png")

    try:
        # [취약점] shell=True + 파일명 직접 삽입
        cmd = f'pdftoppm -png -f 1 -l 1 -r 150 "{pdf_path}" "{thumb_dir}/{base_name}_page"'
        subprocess.run(cmd, shell=True, capture_output=True, timeout=60)

        # 생성된 이미지 파일 찾기
        page_file = os.path.join(thumb_dir, f"{base_name}_page-1.png")
        if os.path.exists(page_file):
            img = Image.open(page_file)
            img.thumbnail(THUMBNAIL_SIZE, Image.LANCZOS)
            img.save(thumb_path)
            os.remove(page_file)
            logger.info(f"PDF 썸네일 생성 완료: {thumb_path}")
            return thumb_path

    except Exception as e:
        logger.error(f"PDF 썸네일 생성 실패: {e}")

    return None


# ===========================================================================
# 파일 처리 파이프라인 (통합)
# ===========================================================================
def process_pipeline(file_path: str, work_dir: str) -> Dict[str, Any]:
    """
    파일을 처리하는 메인 파이프라인.

    파일 타입을 감지하고 적절한 변환을 수행한다.
    """
    start_time = time.time()
    output_files = []

    # 1단계: 파일 타입 감지
    detected_type = detect_file_type(file_path)
    logger.info(f"파일 타입 감지: {file_path} -> {detected_type}")

    # 2단계: 타입별 처리 분기
    if detected_type == "document":
        # [취약점] VULN-06-01: LibreOffice 매크로 실행
        pdf_path = convert_document_to_pdf(file_path, work_dir)
        if pdf_path:
            output_files.append(pdf_path)
            thumb = generate_pdf_thumbnail(pdf_path, work_dir)
            if thumb:
                output_files.append(thumb)

    elif detected_type == "image":
        # [취약점] VULN-06-02: Pillow 버퍼 오버플로
        resized = process_image(file_path, work_dir)
        if resized:
            output_files.extend(resized)

    elif detected_type == "pdf":
        thumb = generate_pdf_thumbnail(file_path, work_dir)
        if thumb:
            output_files.append(thumb)
        output_files.append(file_path)

    else:
        # [취약점] 알 수 없는 파일 타입도 그대로 저장 (차단하지 않음)
        logger.warning(f"알 수 없는 파일 타입, 변환 없이 저장: {file_path}")
        output_files.append(file_path)

    processing_time = time.time() - start_time

    return {
        "detected_type": detected_type,
        "output_files": output_files,
        "processing_time": round(processing_time, 2),
    }


# ===========================================================================
# Celery 태스크
# ===========================================================================
@app.task(
    bind=True,
    name="worker.tasks.process_file",
    queue="file_convert",
    max_retries=3,
    default_retry_delay=60,
)
def process_file(self, complaint_id: str, filename: str):
    """
    민원 첨부파일을 처리하는 메인 Celery 작업.

    1. MinIO에서 파일 다운로드
    2. 파일 타입 감지 + 적절한 변환 수행
    3. 결과를 MinIO에 업로드
    4. DB에 처리 결과 기록

    [취약점] VULN-06-05: 파일 내용 검증 없이 직접 변환 도구에 전달
    [취약점] VULN-06-06: 서비스 계정의 과도한 네트워크 접근 권한
    """
    work_dir = os.path.join(
        os.getenv("PROCESSING_TEMP_DIR", "/tmp/processing"),
        complaint_id,
    )
    os.makedirs(os.path.join(work_dir, "original"), exist_ok=True)
    os.makedirs(os.path.join(work_dir, "converted"), exist_ok=True)
    os.makedirs(os.path.join(work_dir, "thumbnails"), exist_ok=True)

    local_path = os.path.join(work_dir, "original", filename)
    s3_key = f"complaints/{complaint_id}/{filename}"

    try:
        logger.info(f"[{complaint_id}] 파일 처리 시작: {filename}")
        update_complaint_status(complaint_id, "processing")

        # 1단계: MinIO에서 파일 다운로드
        minio_client = MinIOClient()
        minio_client.download_file(s3_key, local_path)
        file_size = os.path.getsize(local_path)
        logger.info(f"[{complaint_id}] 파일 다운로드 완료: {file_size} bytes")

        # 2단계: 파일 처리 파이프라인 실행
        # [취약점] VULN-06-05: 파일 내용을 검증하지 않고 변환 도구에 직접 전달
        result = process_pipeline(local_path, work_dir)

        # 3단계: 변환 결과를 MinIO에 업로드
        for output_file in result.get("output_files", []):
            output_key = (
                f"complaints/{complaint_id}/processed/"
                f"{os.path.basename(output_file)}"
            )
            minio_client.upload_file(output_file, output_key)
            logger.info(f"[{complaint_id}] 변환 결과 업로드: {output_key}")

        # 4단계: DB에 결과 기록
        record_processing_result(
            complaint_id=complaint_id,
            original_filename=filename,
            original_size=file_size,
            converted_files=result.get("output_files", []),
            file_type=result.get("detected_type", "unknown"),
            processing_time=result.get("processing_time", 0),
            status="completed",
        )

        update_complaint_status(complaint_id, "processed")
        logger.info(f"[{complaint_id}] 파일 처리 완료")

        return {
            "complaint_id": complaint_id,
            "status": "completed",
            "output_files": result.get("output_files", []),
        }

    except Exception as e:
        logger.error(f"[{complaint_id}] 파일 처리 실패: {str(e)}")
        logger.error(traceback.format_exc())

        update_complaint_status(complaint_id, "failed")

        # [취약점] 에러 메시지에 내부 경로와 상세 정보 노출
        # 올바른 구현: 사용자에게는 일반적인 에러 메시지만 전달
        record_processing_result(
            complaint_id=complaint_id,
            original_filename=filename,
            original_size=0,
            converted_files=[],
            file_type="unknown",
            processing_time=0,
            status="failed",
            error_message=str(e),  # 전체 에러 메시지 저장
        )

        # 재시도
        raise self.retry(exc=e)

    finally:
        # [취약점] VULN-06-05: 임시 파일 정리가 finally에서 수행되나,
        #   RCE 발생 시 이 코드에 도달하지 못할 수 있음
        try:
            shutil.rmtree(work_dir, ignore_errors=True)
        except Exception:
            pass
