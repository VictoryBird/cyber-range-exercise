/**
 * Asset #13 SCADA 서버 - Node-RED settings.js
 * 경로: /home/nodered/.node-red/settings.js
 *
 * [취약점] VULN-13-02: Node-RED 인증 비활성화
 * adminAuth, httpNodeAuth, httpStaticAuth가 모두 주석 처리되어 있어
 * 누구나 포트 1880으로 접속하여 플로우를 조회/수정/배포할 수 있다.
 *
 * [올바른 설정] adminAuth를 활성화하고 bcrypt 해시된 비밀번호를 사용해야 한다.
 *   adminAuth: {
 *       type: "credentials",
 *       users: [{
 *           username: "admin",
 *           password: "$2b$08$...(bcrypt hash)...",
 *           permissions: "*"
 *       }]
 *   },
 *   httpNodeAuth: {user:"apiuser", pass:"$2b$08$..."},
 *   httpStaticAuth: {user:"staticuser", pass:"$2b$08$..."},
 */

module.exports = {
    uiPort: process.env.PORT || 1880,

    // [취약점] VULN-13-02: 모든 인터페이스에서 수신 (0.0.0.0)
    // [올바른 설정] OT 존 내부만 허용하려면 127.0.0.1 또는 특정 IP 바인딩
    uiHost: "0.0.0.0",

    // [취약점] VULN-13-02: adminAuth 주석 처리 — Node-RED 편집기 인증 없음
    // [올바른 설정] 아래 블록의 주석을 해제하고 bcrypt 해시 비밀번호를 설정
    // adminAuth: {
    //     type: "credentials",
    //     users: [{
    //         username: "admin",
    //         password: "$2b$08$wuR9mLHnVgKrecgSAIJfaOOShWGEBOmXpOBsOkqp0oXKPHueZIBOy",
    //         permissions: "*"
    //     }]
    // },

    // [취약점] VULN-13-02: httpNodeAuth 미설정 — HTTP 노드 엔드포인트 인증 없음
    // [올바른 설정] httpNodeAuth: {user:"user", pass:"$2b$08$..."},

    // [취약점] VULN-13-02: httpStaticAuth 미설정 — 정적 파일 인증 없음
    // [올바른 설정] httpStaticAuth: {user:"user", pass:"$2b$08$..."},

    functionGlobalContext: {
        SCADA_URL: "http://192.168.201.10:8080",
        PLC_API: "http://192.168.201.11:5000"
    },

    logging: {
        console: {
            level: "info",
            metrics: false,
            // [취약점] 감사 로그 비활성화 — 침입 흔적 추적 불가
            // [올바른 설정] audit: true
            audit: false
        }
    },

    exportGlobalContextKeys: false,

    editorTheme: {
        projects: {
            enabled: false
        }
    }
};
