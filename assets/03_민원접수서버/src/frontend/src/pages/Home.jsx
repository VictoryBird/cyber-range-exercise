import { Link } from 'react-router-dom'

export default function Home() {
  return (
    <div>
      {/* 히어로 */}
      <section className="bg-gov-700 text-white py-16 bg-gov-pattern">
        <div className="max-w-6xl mx-auto px-4 text-center animate-fade-up">
          <h1 className="text-4xl font-bold mb-4">국민 민원 서비스</h1>
          <p className="text-gov-200 text-lg mb-8 max-w-2xl mx-auto">
            발도리아 행정안전부 민원포털에 오신 것을 환영합니다.<br />
            시민 여러분의 소중한 의견을 접수하고 신속하게 처리합니다.
          </p>
          <div className="flex gap-4 justify-center">
            <Link to="/submit" className="bg-amber-500 text-gov-900 px-8 py-3 rounded-lg font-bold hover:bg-amber-400 transition-colors">
              민원 접수하기
            </Link>
            <Link to="/status" className="border-2 border-white text-white px-8 py-3 rounded-lg font-semibold hover:bg-white/10 transition-colors">
              처리현황 조회
            </Link>
          </div>
        </div>
      </section>

      {/* 통계 */}
      <section className="max-w-6xl mx-auto px-4 -mt-8">
        <div className="grid md:grid-cols-3 gap-4">
          {[
            { label: '금일 접수', value: '24건', color: 'text-gov-700' },
            { label: '처리 중', value: '87건', color: 'text-amber-600' },
            { label: '이번 달 처리 완료', value: '312건', color: 'text-green-600' },
          ].map(({ label, value, color }) => (
            <div key={label} className="card text-center animate-fade-up">
              <p className={`text-3xl font-bold ${color}`}>{value}</p>
              <p className="text-gray-500 text-sm mt-1">{label}</p>
            </div>
          ))}
        </div>
      </section>

      {/* 서비스 안내 */}
      <section className="max-w-6xl mx-auto px-4 py-16">
        <h2 className="text-2xl font-bold text-center mb-8">민원 서비스 안내</h2>
        <div className="grid md:grid-cols-3 gap-6">
          {[
            { icon: '📝', title: '간편한 접수', desc: '온라인으로 24시간 민원을 접수할 수 있습니다. 첨부파일도 간편하게 업로드하세요.' },
            { icon: '🔍', title: '실시간 조회', desc: '접수번호로 민원 처리 현황을 실시간으로 확인할 수 있습니다.' },
            { icon: '📋', title: '신속한 처리', desc: '접수된 민원은 담당 부서에 자동 배정되어 신속하게 처리됩니다.' },
          ].map(({ icon, title, desc }) => (
            <div key={title} className="card hover:shadow-md transition-shadow">
              <div className="text-3xl mb-3">{icon}</div>
              <h3 className="font-bold text-lg mb-2">{title}</h3>
              <p className="text-gray-500 text-sm">{desc}</p>
            </div>
          ))}
        </div>
      </section>
    </div>
  )
}
