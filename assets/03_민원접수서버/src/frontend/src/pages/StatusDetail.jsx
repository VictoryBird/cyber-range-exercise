import { useState, useEffect } from 'react'
import { useParams, Link } from 'react-router-dom'
import api from '../api'

const STATUS_MAP = {
  received: { label: '접수', badge: 'badge-received' },
  processing: { label: '처리중', badge: 'badge-processing' },
  completed: { label: '처리완료', badge: 'badge-completed' },
  rejected: { label: '반려', badge: 'badge-rejected' },
}

export default function StatusDetail() {
  const { id } = useParams()
  const [complaint, setComplaint] = useState(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(null)

  useEffect(() => {
    api.get(`/api/complaint/${id}`)
      .then(res => setComplaint(res.data))
      .catch(() => setError('민원을 찾을 수 없습니다.'))
      .finally(() => setLoading(false))
  }, [id])

  if (loading) return <div className="text-center py-20 text-gray-400">조회 중...</div>
  if (error) return (
    <div className="max-w-2xl mx-auto px-4 py-16 text-center">
      <div className="text-5xl mb-4">❌</div>
      <p className="text-gray-600 mb-4">{error}</p>
      <Link to="/status" className="btn-outline">다시 조회</Link>
    </div>
  )

  const st = STATUS_MAP[complaint.status] || { label: complaint.status, badge: 'badge-received' }

  return (
    <div className="max-w-3xl mx-auto px-4 py-10">
      <div className="flex items-center gap-3 mb-6">
        <Link to="/status" className="text-gov-600 hover:text-gov-800">← 조회 화면</Link>
      </div>

      <div className="card animate-fade-up">
        <div className="flex items-center justify-between mb-6">
          <div>
            <p className="text-sm text-gray-400">접수번호</p>
            <p className="text-xl font-bold text-gov-700">{complaint.complaint_id}</p>
          </div>
          <span className={`badge ${st.badge}`}>{st.label}</span>
        </div>

        <hr className="mb-6" />

        <div className="space-y-4 text-sm">
          <div className="grid grid-cols-[100px_1fr] gap-2">
            <span className="text-gray-500">제목</span>
            <span className="font-medium">{complaint.title}</span>
          </div>
          <div className="grid grid-cols-[100px_1fr] gap-2">
            <span className="text-gray-500">분류</span>
            <span>{complaint.category}</span>
          </div>
          <div className="grid grid-cols-[100px_1fr] gap-2">
            <span className="text-gray-500">내용</span>
            <span className="whitespace-pre-wrap">{complaint.content}</span>
          </div>
          <div className="grid grid-cols-[100px_1fr] gap-2">
            <span className="text-gray-500">신청인</span>
            <span>{complaint.submitter_name}</span>
          </div>
          {complaint.submitter_phone && (
            <div className="grid grid-cols-[100px_1fr] gap-2">
              <span className="text-gray-500">연락처</span>
              <span>{complaint.submitter_phone}</span>
            </div>
          )}
          <div className="grid grid-cols-[100px_1fr] gap-2">
            <span className="text-gray-500">접수일</span>
            <span>{new Date(complaint.created_at).toLocaleString('ko-KR')}</span>
          </div>
        </div>

        {complaint.files && complaint.files.length > 0 && (
          <div className="mt-6">
            <h3 className="font-bold text-sm mb-3">첨부파일</h3>
            <div className="space-y-2">
              {complaint.files.map(f => (
                <a
                  key={f.file_id}
                  href={f.download_url}
                  className="flex items-center gap-3 bg-gray-50 rounded-lg px-4 py-3 hover:bg-gray-100 transition-colors"
                >
                  <span>📄</span>
                  <span className="text-sm text-gov-700 font-medium">{f.filename}</span>
                  <span className="text-xs text-gray-400 ml-auto">다운로드</span>
                </a>
              ))}
            </div>
          </div>
        )}
      </div>
    </div>
  )
}
