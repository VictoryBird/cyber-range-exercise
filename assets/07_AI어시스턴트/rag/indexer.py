#!/usr/bin/env python3
"""
RAG 문서 인덱서 — AI 어시스턴트 (자산 07)

Nextcloud 공유문서를 ChromaDB에 색인하는 스크립트.
실제 환경에서는 WebDAV로 Nextcloud에 접속하여 문서를 가져오지만,
훈련 환경에서는 로컬 시드 파일을 사용한다.

[취약점] VULN-07-02: /공유문서/ 하위 전체를 색인 대상으로 지정
  → /군협력/ 디렉토리의 군사 관련 민감 문서까지 색인됨
[올바른 구현] include_paths/exclude_paths로 색인 범위를 제한해야 함
"""

import os
import sys
import logging
from pathlib import Path
from datetime import datetime

from dotenv import load_dotenv
from langchain.text_splitter import RecursiveCharacterTextSplitter
from langchain_community.embeddings import OllamaEmbeddings
import chromadb
from chromadb.config import Settings

# 프로젝트 루트 경로 설정
PROJECT_ROOT = Path(__file__).resolve().parent.parent
load_dotenv(PROJECT_ROOT / ".env")

from rag.config import RAGConfig

# 로깅 설정
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    handlers=[
        logging.StreamHandler(sys.stdout),
        logging.FileHandler("/opt/ai-assistant/logs/rag_ingest.log", mode="a")
        if os.path.isdir("/opt/ai-assistant/logs")
        else logging.StreamHandler(sys.stdout),
    ],
)
logger = logging.getLogger(__name__)


def load_documents(base_path: str) -> list[dict]:
    """
    로컬 시드 문서를 로드한다.

    [취약점] VULN-07-02: base_path 하위 모든 디렉토리를 재귀 탐색
    /군협력/ 하위 문서도 포함하여 수집함.
    [올바른 구현] exclude 목록으로 /군협력/ 디렉토리를 제외해야 함:
        if "군협력" in str(file_path):
            continue
    """
    documents = []
    base = Path(base_path)

    if not base.exists():
        logger.error(f"문서 경로가 존재하지 않습니다: {base_path}")
        return documents

    # [취약점] 모든 하위 디렉토리를 재귀 탐색 — 군협력 폴더 포함
    for file_path in sorted(base.rglob("*.txt")):
        try:
            content = file_path.read_text(encoding="utf-8")
            relative_path = file_path.relative_to(base)
            category = relative_path.parts[0] if len(relative_path.parts) > 1 else "미분류"

            documents.append({
                "content": content,
                "metadata": {
                    "source_file": str(relative_path),
                    "category": category,
                    "file_name": file_path.name,
                    "ingested_at": datetime.now().isoformat(),
                    "file_size": file_path.stat().st_size,
                },
            })
            logger.info(f"문서 로드 완료: {relative_path} ({len(content)} chars)")
        except Exception as e:
            logger.error(f"문서 로드 실패: {file_path} — {e}")

    logger.info(f"총 {len(documents)}개 문서 로드 완료")
    return documents


def chunk_documents(documents: list[dict]) -> list[dict]:
    """LangChain RecursiveCharacterTextSplitter로 문서를 청크 단위로 분할"""
    splitter = RecursiveCharacterTextSplitter(
        chunk_size=RAGConfig.CHUNK_SIZE,
        chunk_overlap=RAGConfig.CHUNK_OVERLAP,
        separators=RAGConfig.CHUNK_SEPARATORS,
    )

    chunks = []
    for doc in documents:
        splits = splitter.split_text(doc["content"])
        for idx, chunk_text in enumerate(splits):
            chunks.append({
                "content": chunk_text,
                "metadata": {
                    **doc["metadata"],
                    "chunk_index": idx,
                    "total_chunks": len(splits),
                },
            })

    logger.info(f"총 {len(chunks)}개 청크 생성 (원본 문서 {len(documents)}개)")
    return chunks


def create_embeddings_and_store(chunks: list[dict]) -> None:
    """Ollama 임베딩으로 벡터 생성 후 ChromaDB에 저장"""

    # 임베딩 모델 초기화
    embeddings = OllamaEmbeddings(
        model=RAGConfig.EMBEDDING_MODEL,
        base_url=RAGConfig.OLLAMA_URL,
    )

    # ChromaDB 클라이언트 초기화
    persist_dir = RAGConfig.CHROMA_PERSIST_DIR
    os.makedirs(persist_dir, exist_ok=True)

    client = chromadb.PersistentClient(
        path=persist_dir,
        settings=Settings(anonymized_telemetry=False),
    )

    # 기존 컬렉션 삭제 후 재생성
    try:
        client.delete_collection(RAGConfig.CHROMA_COLLECTION)
        logger.info(f"기존 컬렉션 '{RAGConfig.CHROMA_COLLECTION}' 삭제")
    except ValueError:
        pass

    collection = client.create_collection(
        name=RAGConfig.CHROMA_COLLECTION,
        metadata={"hnsw:space": RAGConfig.DISTANCE_METRIC},
    )

    # 배치 단위로 임베딩 생성 및 저장
    batch_size = RAGConfig.EMBEDDING_BATCH_SIZE
    total = len(chunks)

    for i in range(0, total, batch_size):
        batch = chunks[i : i + batch_size]
        texts = [c["content"] for c in batch]
        metadatas = [c["metadata"] for c in batch]
        ids = [f"chunk_{i + j}" for j in range(len(batch))]

        try:
            vectors = embeddings.embed_documents(texts)
            collection.add(
                ids=ids,
                embeddings=vectors,
                documents=texts,
                metadatas=metadatas,
            )
            logger.info(
                f"배치 {i // batch_size + 1}/{(total + batch_size - 1) // batch_size} "
                f"저장 완료 ({len(batch)}개 청크)"
            )
        except Exception as e:
            logger.error(f"임베딩/저장 실패 (배치 {i // batch_size + 1}): {e}")
            raise

    logger.info(
        f"ChromaDB 색인 완료: {total}개 청크 → "
        f"컬렉션 '{RAGConfig.CHROMA_COLLECTION}'"
    )


def main():
    """메인 실행 함수"""
    logger.info("=" * 60)
    logger.info("RAG 문서 인덱싱 시작")
    logger.info(f"문서 경로: {RAGConfig.DOCUMENT_BASE_PATH}")
    logger.info(f"ChromaDB: {RAGConfig.CHROMA_PERSIST_DIR}")
    logger.info(f"임베딩 모델: {RAGConfig.EMBEDDING_MODEL}")
    logger.info("=" * 60)

    # 1. 문서 로드
    documents = load_documents(RAGConfig.DOCUMENT_BASE_PATH)
    if not documents:
        logger.error("로드된 문서가 없습니다. 종료합니다.")
        sys.exit(1)

    # 2. 청킹
    chunks = chunk_documents(documents)

    # 3. 임베딩 및 ChromaDB 저장
    create_embeddings_and_store(chunks)

    logger.info("=" * 60)
    logger.info("RAG 문서 인덱싱 완료")
    logger.info("=" * 60)


if __name__ == "__main__":
    main()
