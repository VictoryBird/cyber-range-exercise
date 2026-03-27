# I6 - 군 내부 업무 포털 (eGovframework)

## 개요

- 자산 ID: I6
- IP: 192.168.110.10
- 도메인: intranet.mnd.local
- OS: Rocky Linux 9
- 기술 스택: eGovframework 4.x + Spring Boot 3.x + PostgreSQL 15

## 구현 상태

이 자산은 eGovframework 기반으로, 구현 난이도가 높아 **마지막에 구현** 예정이다.
현재는 플레이스홀더 상태이며, 상세 설계는 `자산설계_I6_내부업무포털_군.md`를 참조한다.

## 계획된 취약점

| ID | 취약점 | 유형 |
|----|--------|------|
| VULN-I6-01 | 인증 우회 | /api/admin/* 인증 미적용 |
| VULN-I6-02 | SQL Injection | /api/search?keyword= |
| VULN-I6-03 | 파일 업로드 | 확장자 검증 미흡 |
| VULN-I6-04 | IDOR | /api/user/{id}/profile |

## 주요 기능 (구현 예정)

- 로그인/인증 (AD LDAP 연동 SSO)
- 대시보드 (부서별 업무 현황, 공지사항)
- 공지사항 등록/열람
- 전자 결재
- 문서 관리
- 사용자/조직 관리
