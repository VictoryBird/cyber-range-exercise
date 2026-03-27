# 자산 #C16: C4I 작전용 PC 1~5

## 개요

| 항목 | 내용 |
|------|------|
| 자산 | 작전용 PC 5대 (도메인 미가입, 독립 운영) |
| IP | 192.168.130.21 ~ 192.168.130.25 |
| OS | Windows 10/11 Pro |
| 호스트명 | C4I-OPS-PC-{1~5} |
| 역할 | COP 상황도 열람 + AI 브리핑 확인 (전술 단말) |
| 네트워크 존 | C4I (192.168.130.0/24) |

## 배포 순서

```powershell
# 각 PC에서 실행 (PC 번호를 파라미터로 전달)
.\scripts\setup_tactical_pc.ps1 -PCNumber 1   # PC-1 (작전과장)
.\scripts\setup_tactical_pc.ps1 -PCNumber 2   # PC-2 (정보과장)
.\scripts\setup_tactical_pc.ps1 -PCNumber 3   # PC-3 (화력과장)
.\scripts\setup_tactical_pc.ps1 -PCNumber 4   # PC-4 (군수과장)
.\scripts\setup_tactical_pc.ps1 -PCNumber 5   # PC-5 (당직사관)
```

## PC별 구성

| PC | IP | 사용자 | 역할 |
|----|----|--------|------|
| PC-1 | 192.168.130.21 | 작전과장 | 작전 현황 종합 모니터링 |
| PC-2 | 192.168.130.22 | 정보과장 | 적 동향 분석 |
| PC-3 | 192.168.130.23 | 화력과장 | 포병/화력 운용 현황 |
| PC-4 | 192.168.130.24 | 군수과장 | 보급/군수 현황 |
| PC-5 | 192.168.130.25 | 당직사관 | 상황 보고 종합 |

## 접속 정보

| 항목 | URL |
|------|-----|
| COP 상황도 | http://cop.c4i.local:8080/map.jsp |
| AI 브리핑 | http://summary.c4i.local:8001/api/summary/latest |
| 이벤트 현황 | http://data.c4i.local:8000/api/stats |

## 로컬 계정

| 계정 | 비밀번호 | 용도 |
|------|----------|------|
| operator | Op3rator!C4I | 일반 운용 |
| c4i-admin | C4I!Admin#2024 | 관리자 |

## 참고

이 PC들은 직접적인 취약점이 없으며, 상위 서버(C13 COP, C14 데이터, C15 AI)의 데이터 오염에 의한 간접 피해를 받는 최종 피해 대상입니다.
