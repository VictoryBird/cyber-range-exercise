"""SQLAlchemy 데이터 모델"""

from sqlalchemy import Column, Integer, String, DateTime, Text, ForeignKey, BigInteger
from sqlalchemy.sql import func

from database import Base


class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    username = Column(String(50), unique=True, nullable=False, index=True)
    password_hash = Column(String(255), nullable=False)
    name = Column(String(100), nullable=False)
    email = Column(String(255))
    department = Column(String(100))
    role = Column(String(20), default="user")  # admin, user
    last_login = Column(DateTime)
    created_at = Column(DateTime, server_default=func.now())


class Document(Base):
    __tablename__ = "documents"

    id = Column(Integer, primary_key=True, index=True)
    filename = Column(String(500), nullable=False)
    original_filename = Column(String(500), nullable=False)
    file_path = Column(String(1000), nullable=False)
    file_size = Column(BigInteger)
    category = Column(String(100))
    classification = Column(String(50), default="일반")  # 일반, 대외비, 비밀, 극비
    description = Column(Text)
    uploaded_by = Column(String(50), ForeignKey("users.username"))
    uploaded_at = Column(DateTime, server_default=func.now())
    updated_at = Column(DateTime, onupdate=func.now())


class AuditLog(Base):
    __tablename__ = "audit_log"

    id = Column(Integer, primary_key=True, index=True)
    action = Column(String(50), nullable=False)  # login, download, upload, delete
    username = Column(String(50))
    target = Column(String(500))
    ip_address = Column(String(45))
    timestamp = Column(DateTime, server_default=func.now())
    details = Column(Text)
