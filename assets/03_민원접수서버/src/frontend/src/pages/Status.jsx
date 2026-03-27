import { useState } from 'react'
import { useNavigate } from 'react-router-dom'

export default function Status() {
  const [trackingId, setTrackingId] = useState('')
  const navigate = useNavigate()

  const handleSearch = (e) => {
    e.preventDefault()
    if (trackingId.trim()) {
      navigate(`/status/${trackingId.trim()}`)
    }
  }

  return (
    <div className="max-w-2xl mx-auto px-4 py-16">
      <div className="text-center mb-10 animate-fade-up">
        <h1 className="text-2xl font-bold mb-2">민원 처리현황 조회</h1>
        <p className="text-gray-500">접수번호를 입력하여 민원 처리 현황을 확인하세요.</p>
      </div>

      <div className="card animate-scale-in">
        <form onSubmit={handleSearch} className="flex gap-3">
          <input
            value={trackingId}
            onChange={(e) => setTrackingId(e.target.value)}
            placeholder="접수번호 입력 (예: COMP-2026-00001)"
            className="flex-1 border border-gray-300 rounded-lg px-4 py-3 focus:ring-2 focus:ring-gov-500 focus:border-transparent outline-none"
          />
          <button type="submit" className="btn-primary whitespace-nowrap">조회</button>
        </form>

        <div className="mt-6 p-4 bg-gray-50 rounded-lg">
          <h3 className="font-medium text-sm text-gray-700 mb-2">접수번호 안내</h3>
          <ul className="text-sm text-gray-500 space-y-1">
            <li>• 접수번호는 민원 접수 완료 시 발급됩니다.</li>
            <li>• 형식: COMP-2026-XXXXX</li>
            <li>• 접수번호를 분실한 경우 민원담당관실(02-2100-0000)로 문의하세요.</li>
          </ul>
        </div>
      </div>
    </div>
  )
}
