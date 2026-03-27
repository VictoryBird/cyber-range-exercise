# 자산 #15: OT 운영자 PC (SCADA HMI 모니터링)

## 개요

| 항목 | 내용 |
|------|------|
| 자산 | 운영자 PC 2대 (SCADA HMI 모니터링 단말) |
| IP | 192.168.201.21 (PC1, Windows 10), 192.168.201.22 (PC2, Windows 11) |
| 호스트명 | OT-OP-PC01, OT-OP-PC02 |
| 역할 | 웹 브라우저로 SCADA-LTS HMI 화면 모니터링 |
| 도메인 | 도메인 미가입 (독립 운영) |
| 네트워크 존 | OT (192.168.201.0/24) |

## 배포 순서

### 각 PC에서 실행

```powershell
# 1. 운영자 PC 설정 (IP, 호스트명, 브라우저 자동실행 등)
#    PC 번호를 파라미터로 전달 (1 또는 2)
.\scripts\setup_operator_pc.ps1 -PCNumber 1   # PC1용
.\scripts\setup_operator_pc.ps1 -PCNumber 2   # PC2용

# 2. hosts 파일 설정 (관리자 CMD에서 실행)
.\scripts\setup_hosts.bat
```

## 접속 정보

| 항목 | 값 |
|------|-----|
| SCADA HMI URL | http://192.168.201.10:8080/ScadaLTS/ |
| PC1 로그인 | operator1 / operator1 |
| PC2 로그인 | operator2 / operator2 |
| Node-RED 대시보드 | http://192.168.201.10:1880/ui (보조) |
