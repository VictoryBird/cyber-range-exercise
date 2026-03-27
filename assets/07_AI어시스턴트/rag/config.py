"""
RAG 인덱서 설정 — AI 어시스턴트 (자산 07)
"""

import os
from dotenv import load_dotenv

load_dotenv()


class RAGConfig:
    """RAG 파이프라인 설정"""

    # --- Nextcloud WebDAV ---
    NEXTCLOUD_URL = os.getenv("NEXTCLOUD_URL", "https://192.168.100.12")
    NEXTCLOUD_WEBDAV_PATH = os.getenv(
        "NEXTCLOUD_WEBDAV_PATH",
        "/remote.php/dav/files/ai-service/공유문서/"
    )
    NEXTCLOUD_USERNAME = os.getenv("NEXTCLOUD_USERNAME", "ai-service")
    NEXTCLOUD_PASSWORD = os.getenv("NEXTCLOUD_PASSWORD", "AiSvc2024!@#")

    # --- 문서 수집 경로 ---
    # [취약점] VULN-07-02: 전체 /공유문서/ 디렉토리를 색인 대상으로 지정
    # /군협력/ 하위 문서까지 포함되어 군 관련 민감 정보가 RAG에 색인됨
    # [올바른 구현] include_paths와 exclude_paths로 색인 범위를 제한해야 함
    # INCLUDE_PATHS = ["/공유문서/일반/"]
    # EXCLUDE_PATHS = ["/공유문서/군협력/"]
    DOCUMENT_BASE_PATH = os.getenv(
        "DOCUMENT_BASE_PATH",
        "/opt/ai-assistant/seed/documents"
    )

    # --- 청킹(Chunking) 설정 ---
    CHUNK_SIZE = int(os.getenv("RAG_CHUNK_SIZE", "1000"))
    CHUNK_OVERLAP = int(os.getenv("RAG_CHUNK_OVERLAP", "200"))
    CHUNK_SEPARATORS = ["\n\n", "\n", ".", " "]

    # --- 임베딩 설정 ---
    EMBEDDING_MODEL = os.getenv("EMBEDDING_MODEL", "nomic-embed-text")
    OLLAMA_URL = os.getenv("OLLAMA_URL", "http://localhost:11434")
    EMBEDDING_BATCH_SIZE = 32
    EMBEDDING_DIMENSIONS = 768

    # --- ChromaDB ---
    CHROMA_PERSIST_DIR = os.getenv(
        "CHROMA_PERSIST_DIR",
        "/opt/ai-assistant/data/chromadb"
    )
    CHROMA_COLLECTION = os.getenv("CHROMA_COLLECTION", "mois_documents")
    DISTANCE_METRIC = "cosine"

    # --- 검색 설정 ---
    TOP_K = int(os.getenv("RAG_TOP_K", "5"))
    SCORE_THRESHOLD = float(os.getenv("RAG_SCORE_THRESHOLD", "0.3"))
    # [취약점] VULN-07-03: 검색 결과에 소스 파일명 포함, 원본 청크 텍스트 그대로 반환
    # [올바른 구현] 소스 파일명 숨기기, 민감 키워드 필터링 적용
    INCLUDE_SOURCE = True
    RETURN_RAW_CHUNKS = True

    # --- 생성 설정 ---
    LLM_MODEL = os.getenv("LLM_MODEL", "llama3")
    TEMPERATURE = 0.3
    MAX_TOKENS = 2048
    SYSTEM_PROMPT_FILE = os.getenv(
        "SYSTEM_PROMPT_FILE",
        "/opt/ai-assistant/rag/system_prompt.txt"
    )

    # --- 쿼리 필터링 ---
    # [취약점] VULN-07-03: 쿼리 필터링/분류 없음 — 군사 키워드 필터 미적용
    # [올바른 구현] 아래와 같이 차단 키워드를 설정해야 함
    # BLOCKED_KEYWORDS = ["VPN", "군", "비밀번호", "접속정보", "사번"]
    BLOCKED_KEYWORDS = None  # 필터 없음
    QUERY_FILTER_ENABLED = False
