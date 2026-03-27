import { Link } from 'react-router-dom';

export default function Footer() {
  return (
    <footer>
      {/* 기관 정보 영역 */}
      <div className="bg-[#2c3e50] text-gray-300">
        <div className="max-w-6xl mx-auto px-4 py-8">
          <h3 className="text-white font-bold text-lg mb-3">발도리아 행정안전부</h3>
          <div className="text-sm space-y-1">
            <p>주소: Valdoria City, Central District, Government Complex 3</p>
            <p>전화: +82-2-2100-0000 &nbsp;|&nbsp; 팩스: +82-2-2100-0001</p>
            <p>이메일: webmaster@mois.valdoria.gov</p>
          </div>
        </div>
      </div>

      {/* 하단 링크 영역 */}
      <div className="bg-[#1a252f] text-gray-400">
        <div className="max-w-6xl mx-auto px-4 py-4 text-xs">
          <div className="flex flex-wrap gap-4 mb-2">
            <Link to="#" className="hover:text-white">이용약관</Link>
            <Link to="#" className="hover:text-white font-bold">개인정보처리방침</Link>
            <Link to="#" className="hover:text-white">저작권정책</Link>
            <Link to="#" className="hover:text-white">사이트맵</Link>
          </div>
          <p>Copyright &copy; Ministry of the Interior and Safety, Valdoria. All rights reserved.</p>
        </div>
      </div>
    </footer>
  );
}
