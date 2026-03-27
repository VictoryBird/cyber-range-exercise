import axios from 'axios'

// [취약점] API 주소가 소스코드에 하드코딩 — 이 자산 고유 취약점
const api = axios.create({
  baseURL: 'http://203.238.140.12:8000',
  timeout: 30000,
})

export default api
