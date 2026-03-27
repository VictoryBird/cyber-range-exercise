import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import StepIndicator from '../components/StepIndicator'
import FileUpload from '../components/FileUpload'
import api from '../api'

const CATEGORIES = [
  { id: 'infrastructure', label: '도로/교통', icon: '🚧' },
  { id: 'environment', label: '환경', icon: '🌿' },
  { id: 'living', label: '생활불편', icon: '🏘️' },
  { id: 'welfare', label: '복지', icon: '🤝' },
  { id: 'other', label: '기타', icon: '📋' },
]

export default function Submit() {
  const navigate = useNavigate()
  const [step, setStep] = useState(1)
  const [form, setForm] = useState({
    category: '', title: '', content: '',
    submitter_name: '', submitter_phone: '', submitter_email: '',
  })
  const [files, setFiles] = useState([])
  const [submitting, setSubmitting] = useState(false)
  const [result, setResult] = useState(null)

  const set = (field) => (e) => setForm(prev => ({ ...prev, [field]: e.target.value }))

  const canNext = () => {
    if (step === 1) return form.category
    if (step === 2) return form.title && form.content
    if (step === 3) return form.submitter_name
    return true
  }

  const handleSubmit = async () => {
    setSubmitting(true)
    try {
      const formData = new FormData()
      Object.entries(form).forEach(([k, v]) => formData.append(k, v))

      const res = await api.post('/api/complaint/submit', formData)
      const complaintId = res.data.complaint_id

      for (const file of files) {
        const fd = new FormData()
        fd.append('complaint_id', complaintId)
        fd.append('file', file)
        await api.post('/api/complaint/upload', fd)
      }

      setResult(res.data)
      setStep(6)
    } catch (err) {
      alert('민원 접수 중 오류가 발생했습니다.')
    } finally {
      setSubmitting(false)
    }
  }

  return (
    <div className="max-w-3xl mx-auto px-4 py-10">
      <h1 className="text-2xl font-bold text-center mb-2">민원 접수</h1>
      <p className="text-gray-500 text-center mb-8">아래 절차에 따라 민원을 접수해 주세요.</p>

      {step <= 5 && <StepIndicator current={step} />}

      <div className="card animate-scale-in">
        {/* Step 1: 분류 */}
        {step === 1 && (
          <div>
            <h2 className="font-bold text-lg mb-4">민원 분류를 선택해 주세요</h2>
            <div className="grid grid-cols-2 md:grid-cols-3 gap-3">
              {CATEGORIES.map(({ id, label, icon }) => (
                <button
                  key={id}
                  onClick={() => setForm(p => ({ ...p, category: id }))}
                  className={`p-4 rounded-xl border-2 text-center transition-all ${
                    form.category === id
                      ? 'border-gov-700 bg-gov-50 shadow-sm'
                      : 'border-gray-200 hover:border-gov-400'
                  }`}
                >
                  <div className="text-2xl mb-1">{icon}</div>
                  <div className="text-sm font-medium">{label}</div>
                </button>
              ))}
            </div>
          </div>
        )}

        {/* Step 2: 내용 */}
        {step === 2 && (
          <div className="space-y-4">
            <h2 className="font-bold text-lg mb-4">민원 내용을 작성해 주세요</h2>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">제목 *</label>
              <input
                value={form.title}
                onChange={set('title')}
                placeholder="민원 제목을 입력하세요"
                className="w-full border border-gray-300 rounded-lg px-4 py-3 focus:ring-2 focus:ring-gov-500 focus:border-transparent outline-none"
              />
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">내용 *</label>
              <textarea
                value={form.content}
                onChange={set('content')}
                rows={6}
                placeholder="민원 내용을 상세히 작성해 주세요"
                className="w-full border border-gray-300 rounded-lg px-4 py-3 focus:ring-2 focus:ring-gov-500 focus:border-transparent outline-none resize-none"
              />
            </div>
          </div>
        )}

        {/* Step 3: 신청인 */}
        {step === 3 && (
          <div className="space-y-4">
            <h2 className="font-bold text-lg mb-4">신청인 정보</h2>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">성명 *</label>
              <input value={form.submitter_name} onChange={set('submitter_name')}
                placeholder="홍길동" className="w-full border border-gray-300 rounded-lg px-4 py-3 focus:ring-2 focus:ring-gov-500 outline-none" />
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">연락처</label>
              <input value={form.submitter_phone} onChange={set('submitter_phone')}
                placeholder="010-1234-5678" className="w-full border border-gray-300 rounded-lg px-4 py-3 focus:ring-2 focus:ring-gov-500 outline-none" />
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">이메일</label>
              <input value={form.submitter_email} onChange={set('submitter_email')}
                placeholder="example@email.com" className="w-full border border-gray-300 rounded-lg px-4 py-3 focus:ring-2 focus:ring-gov-500 outline-none" />
            </div>
          </div>
        )}

        {/* Step 4: 파일 첨부 */}
        {step === 4 && (
          <div>
            <h2 className="font-bold text-lg mb-4">파일 첨부 (선택)</h2>
            <FileUpload files={files} setFiles={setFiles} />
          </div>
        )}

        {/* Step 5: 확인 */}
        {step === 5 && (
          <div>
            <h2 className="font-bold text-lg mb-4">민원 내용 확인</h2>
            <div className="space-y-3 text-sm">
              <div className="flex"><span className="w-24 text-gray-500">분류</span><span className="font-medium">{CATEGORIES.find(c => c.id === form.category)?.label}</span></div>
              <div className="flex"><span className="w-24 text-gray-500">제목</span><span className="font-medium">{form.title}</span></div>
              <div className="flex"><span className="w-24 text-gray-500">내용</span><span className="font-medium whitespace-pre-wrap">{form.content}</span></div>
              <hr />
              <div className="flex"><span className="w-24 text-gray-500">성명</span><span className="font-medium">{form.submitter_name}</span></div>
              <div className="flex"><span className="w-24 text-gray-500">연락처</span><span className="font-medium">{form.submitter_phone || '-'}</span></div>
              <div className="flex"><span className="w-24 text-gray-500">이메일</span><span className="font-medium">{form.submitter_email || '-'}</span></div>
              {files.length > 0 && (
                <>
                  <hr />
                  <div className="flex"><span className="w-24 text-gray-500">첨부파일</span><span className="font-medium">{files.length}개</span></div>
                </>
              )}
            </div>
          </div>
        )}

        {/* Step 6: 완료 */}
        {step === 6 && result && (
          <div className="text-center py-8">
            <div className="text-5xl mb-4">✅</div>
            <h2 className="text-xl font-bold mb-2">민원이 접수되었습니다</h2>
            <p className="text-gray-500 mb-4">접수번호를 기억해 주세요.</p>
            <div className="bg-gov-50 border border-gov-200 rounded-lg py-4 px-6 inline-block">
              <p className="text-sm text-gray-500">접수번호</p>
              <p className="text-2xl font-bold text-gov-700">{result.complaint_id}</p>
            </div>
            <div className="mt-6 flex gap-3 justify-center">
              <button onClick={() => navigate(`/status/${result.complaint_id}`)} className="btn-primary">처리현황 조회</button>
              <button onClick={() => { setStep(1); setForm({ category:'', title:'', content:'', submitter_name:'', submitter_phone:'', submitter_email:'' }); setFiles([]); setResult(null) }} className="btn-outline">새 민원 접수</button>
            </div>
          </div>
        )}

        {/* 네비게이션 버튼 */}
        {step <= 5 && (
          <div className="flex justify-between mt-8">
            <button
              onClick={() => setStep(s => Math.max(1, s - 1))}
              disabled={step === 1}
              className="px-6 py-2 text-gray-500 hover:text-gray-700 disabled:opacity-30"
            >
              이전
            </button>
            {step < 5 ? (
              <button onClick={() => setStep(s => s + 1)} disabled={!canNext()} className="btn-primary disabled:opacity-50">
                다음
              </button>
            ) : (
              <button onClick={handleSubmit} disabled={submitting} className="bg-amber-500 text-gov-900 px-8 py-3 rounded-lg font-bold hover:bg-amber-400 disabled:opacity-50">
                {submitting ? '접수 중...' : '민원 접수'}
              </button>
            )}
          </div>
        )}
      </div>
    </div>
  )
}
