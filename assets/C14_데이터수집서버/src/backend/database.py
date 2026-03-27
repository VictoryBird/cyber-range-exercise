"""
C14 데이터 수집·관리 서버 — 데이터베이스 모듈
파일 경로: /opt/datacollector/app/database.py
"""

import sqlalchemy as sa
from sqlalchemy import create_engine, MetaData, Table, Column, Integer, String, Float, Boolean, DateTime, Text, JSON
from sqlalchemy.orm import sessionmaker
from datetime import datetime

from config import DATABASE_URL

engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(bind=engine)
metadata = MetaData()

events_table = Table(
    "events", metadata,
    Column("id", Integer, primary_key=True, autoincrement=True),
    Column("type", String(50), nullable=False),
    Column("unit", String(100)),
    Column("location_lat", Float),
    Column("location_lng", Float),
    Column("timestamp", DateTime, default=datetime.utcnow),
    Column("priority", String(10), default="medium"),
    Column("source", String(20), default="relay"),
    Column("verified", Boolean, default=False),
    Column("description", Text),
    Column("metadata", JSON, default={}),
    Column("created_at", DateTime, default=datetime.utcnow),
    Column("updated_at", DateTime, default=datetime.utcnow),
)

metadata.create_all(engine)
