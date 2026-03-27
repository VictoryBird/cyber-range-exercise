import { BrowserRouter, Routes, Route } from 'react-router-dom';
import Header from './components/Header';
import Footer from './components/Footer';
import Home from './pages/Home';
import NoticeList from './pages/NoticeList';
import NoticeDetail from './pages/NoticeDetail';
import Search from './pages/Search';
import Inquiry from './pages/Inquiry';
import AdminLogin from './pages/Login';

function App() {
  return (
    <BrowserRouter>
      <div className="min-h-screen flex flex-col">
        <Header />
        <main className="flex-1">
          <Routes>
            <Route path="/" element={<Home />} />
            <Route path="/notices" element={<NoticeList />} />
            <Route path="/notices/:id" element={<NoticeDetail />} />
            <Route path="/search" element={<Search />} />
            <Route path="/inquiry" element={<Inquiry />} />
            {/* 관리자 로그인 - 내비게이션에 링크 없음 (Security through obscurity) */}
            {/* [취약점] 숨겨진 관리자 페이지: URL 직접 입력이나 JS 번들 분석으로 접근 가능 */}
            <Route path="/login" element={<AdminLogin />} />
          </Routes>
        </main>
        <Footer />
      </div>
    </BrowserRouter>
  );
}

export default App;
