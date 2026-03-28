/**
 * MOIS Portal API Client
 * Asset 01: External Portal Server
 *
 * [취약점] VULN-01-04: Debug information leakage
 * - Hardcoded API base URL visible in client bundle
 * - console.log in interceptors exposes request/response details
 * - No CSRF token handling
 *
 * 올바른 구현:
 * - Use relative URLs or environment variables for API base
 * - Remove all console.log in production
 * - Implement CSRF protection headers
 */

import axios from "axios";

// [취약점] VULN-01-04: API URL visible in client bundle — attackers can discover backend structure
// 올바른 구현: use environment variable, not hardcoded
// Note: Nginx proxies /api/* to FastAPI at 192.168.92.201:8000
//       Port 8000 is also directly accessible (VULN-01-01)
const API_BASE_URL = "/api";

const api = axios.create({
  baseURL: API_BASE_URL,
  timeout: 10000,
  headers: {
    "Content-Type": "application/json",
  },
  // [취약점] VULN-01-04: No CSRF token in requests
  // 올바른 구현: withCredentials: true, plus CSRF header from cookie
});

// [취약점] VULN-01-04: Debug logging in request interceptor
// 올바른 구현: remove console.log entirely in production builds
api.interceptors.request.use(
  (config) => {
    console.log(`[MOIS API] ${config.method?.toUpperCase()} ${config.baseURL}${config.url}`, {
      params: config.params,
      data: config.data,
    });
    return config;
  },
  (error) => {
    console.error("[MOIS API] Request error:", error);
    return Promise.reject(error);
  }
);

// [취약점] VULN-01-04: Debug logging in response interceptor
// 올바른 구현: remove console.log entirely in production builds
api.interceptors.response.use(
  (response) => {
    console.log(`[MOIS API] Response ${response.status}:`, response.data);
    return response;
  },
  (error) => {
    console.error("[MOIS API] Error response:", {
      status: error.response?.status,
      data: error.response?.data,
      url: error.config?.url,
    });
    return Promise.reject(error);
  }
);

/**
 * Fetch paginated notice list.
 */
export async function fetchNotices({ page = 1, size = 20, category = null } = {}) {
  const params = { page, size };
  if (category) params.category = category;
  const { data } = await api.get("/notices", { params });
  return data;
}

/**
 * Fetch single notice by ID.
 */
export async function fetchNotice(id) {
  const { data } = await api.get(`/notices/${id}`);
  return data;
}

/**
 * Search notices and inquiries.
 */
export async function searchPortal({ q, type = null, page = 1, size = 20 } = {}) {
  const params = { q, page, size };
  if (type) params.type = type;
  const { data } = await api.get("/search", { params });
  return data;
}

/**
 * Look up inquiry status by tracking number.
 */
export async function fetchInquiry(trackingNumber) {
  const { data } = await api.get(`/inquiry/${trackingNumber}`);
  return data;
}

export default api;
