export default function Footer() {
  return (
    <footer className="bg-gov-900 text-gov-200 mt-auto">
      <div className="max-w-6xl mx-auto px-4 py-8">
        <div className="grid md:grid-cols-3 gap-6 text-sm">
          <div>
            <h3 className="text-white font-bold mb-2">발도리아 행정안전부</h3>
            <p>Ministry of the Interior and Safety, Valdoria</p>
            <p className="mt-1">Valdoria City, Central District, Government Complex 3</p>
          </div>
          <div>
            <h3 className="text-white font-bold mb-2">연락처</h3>
            <p>전화: +82-2-2100-0000</p>
            <p>팩스: +82-2-2100-0001</p>
            <p>이메일: minwon@mois.valdoria.gov</p>
          </div>
          <div>
            <h3 className="text-white font-bold mb-2">이용안내</h3>
            <p>운영시간: 평일 09:00 ~ 18:00</p>
            <p>민원 접수는 24시간 가능합니다.</p>
          </div>
        </div>
        <div className="border-t border-gov-700 mt-6 pt-4 text-xs text-gov-400">
          Copyright © Ministry of the Interior and Safety, Valdoria. All rights reserved.
        </div>
      </div>
    </footer>
  )
}
