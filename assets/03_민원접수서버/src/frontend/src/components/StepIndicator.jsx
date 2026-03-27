const STEPS = ['분류 선택', '내용 작성', '신청인 정보', '파일 첨부', '확인 및 제출']

export default function StepIndicator({ current }) {
  return (
    <div className="flex items-center justify-center gap-1 mb-8">
      {STEPS.map((label, i) => {
        const step = i + 1
        const done = step < current
        const active = step === current
        return (
          <div key={step} className="flex items-center">
            <div className="flex flex-col items-center">
              <div className={`w-8 h-8 rounded-full flex items-center justify-center text-sm font-bold transition-all duration-300 ${
                done ? 'bg-gov-700 text-white' :
                active ? 'bg-amber-500 text-gov-900 ring-4 ring-amber-200' :
                'bg-gray-200 text-gray-500'
              }`}>
                {done ? '✓' : step}
              </div>
              <span className={`text-xs mt-1 whitespace-nowrap ${active ? 'text-gov-700 font-semibold' : 'text-gray-400'}`}>
                {label}
              </span>
            </div>
            {i < STEPS.length - 1 && (
              <div className={`w-12 h-0.5 mx-1 mt-[-14px] transition-colors duration-300 ${
                done ? 'bg-gov-700' : 'bg-gray-200'
              }`} />
            )}
          </div>
        )
      })}
    </div>
  )
}
