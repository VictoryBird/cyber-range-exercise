import axios from 'axios'

const api = axios.create({
  baseURL: '/api',
  timeout: 30000,
  headers: {
    'Content-Type': 'application/json',
  },
})

// Request interceptor
api.interceptors.request.use(
  (config) => config,
  (error) => Promise.reject(error)
)

// Response interceptor — normalize errors
api.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response) {
      const msg = error.response.data?.detail || error.response.data?.message || 'An error occurred.'
      error.userMessage = msg
    } else if (error.request) {
      error.userMessage = 'Network error. Please check your connection and try again.'
    } else {
      error.userMessage = error.message || 'Unexpected error.'
    }
    return Promise.reject(error)
  }
)

// ---- Complaint endpoints ----

export const submitComplaint = (data) =>
  api.post('/complaint/submit', data)

export const uploadFile = (complaintId, file, onProgress) => {
  const formData = new FormData()
  formData.append('complaint_id', complaintId)
  formData.append('file', file)
  return api.post('/complaint/upload', formData, {
    headers: { 'Content-Type': 'multipart/form-data' },
    onUploadProgress: (evt) => {
      if (onProgress && evt.total) {
        onProgress(Math.round((evt.loaded * 100) / evt.total))
      }
    },
  })
}

export const getComplaint = (number) =>
  api.get(`/complaint/${encodeURIComponent(number)}`)

export const getDownloadUrl = (number, fileId) =>
  `/api/complaint/${encodeURIComponent(number)}/download?file_id=${fileId}`

export default api
