import { BrowserRouter, Routes, Route } from 'react-router-dom'
import { ToastContainer } from 'react-toastify'
import Layout from './components/Layout.jsx'
import HomePage from './pages/HomePage.jsx'
import SubmitPage from './pages/SubmitPage.jsx'
import StatusPage from './pages/StatusPage.jsx'
import StatusDetailPage from './pages/StatusDetailPage.jsx'
import FaqPage from './pages/FaqPage.jsx'

export default function App() {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/" element={<Layout />}>
          <Route index element={<HomePage />} />
          <Route path="submit" element={<SubmitPage />} />
          <Route path="status" element={<StatusPage />} />
          <Route path="status/:id" element={<StatusDetailPage />} />
          <Route path="faq" element={<FaqPage />} />
        </Route>
      </Routes>
      <ToastContainer
        position="top-right"
        autoClose={4000}
        hideProgressBar={false}
        newestOnTop
        closeOnClick
        pauseOnFocusLoss
        draggable
        pauseOnHover
        theme="light"
      />
    </BrowserRouter>
  )
}
