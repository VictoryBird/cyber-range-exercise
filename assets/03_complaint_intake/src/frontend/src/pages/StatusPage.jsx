import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { toast } from 'react-toastify'
import { getComplaint } from '../lib/api.js'

const COMPLAINT_NUMBER_PATTERN = /^COMP-\d{4}-\d{5}$/

export default function StatusPage() {
  const navigate = useNavigate()
  const [query, setQuery] = useState('')
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')

  const handleSearch = async (e) => {
    e.preventDefault()
    const trimmed = query.trim().toUpperCase()

    if (!trimmed) {
      setError('Please enter a complaint number.')
      return
    }
    if (!COMPLAINT_NUMBER_PATTERN.test(trimmed)) {
      setError('Invalid format. Complaint numbers follow the pattern COMP-YYYY-NNNNN (e.g. COMP-2026-00042).')
      return
    }
    setError('')
    setLoading(true)

    try {
      // Verify the complaint exists before navigating
      await getComplaint(trimmed)
      navigate(`/status/${trimmed}`)
    } catch (err) {
      if (err.response?.status === 404) {
        setError('No complaint found with this number. Please check and try again.')
      } else {
        toast.error(err.userMessage || 'Unable to retrieve complaint. Please try again later.')
      }
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="max-w-2xl mx-auto px-4 py-12">
      {/* Page header */}
      <div className="text-center mb-10">
        <div className="w-14 h-14 bg-gov-navy rounded-full flex items-center justify-center mx-auto mb-4">
          <svg className="w-7 h-7 text-gov-gold" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2}
              d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-6 9l2 2 4-4" />
          </svg>
        </div>
        <h1 className="text-2xl font-bold text-gov-navy mb-2">
          처리현황 조회 — Track Complaint Status
        </h1>
        <p className="text-sm text-gray-500">
          Enter your complaint number to view the current processing status and details.
        </p>
      </div>

      {/* Search card */}
      <div className="card p-8">
        <form onSubmit={handleSearch}>
          <label className="form-label text-base mb-2 block" htmlFor="complaint-number">
            Complaint Number
          </label>
          <p className="text-xs text-gray-400 mb-3">
            Format: <span className="font-mono font-medium">COMP-YYYY-NNNNN</span> — e.g.{' '}
            <span className="font-mono">COMP-2026-00042</span>
          </p>

          <div className="flex gap-2">
            <input
              id="complaint-number"
              type="text"
              className={`form-input flex-1 uppercase tracking-wider font-mono text-base ${
                error ? 'border-red-400 focus:ring-red-400' : ''
              }`}
              placeholder="COMP-2026-00001"
              value={query}
              onChange={(e) => {
                setQuery(e.target.value)
                if (error) setError('')
              }}
              maxLength={15}
              spellCheck={false}
              autoComplete="off"
            />
            <button
              type="submit"
              disabled={loading}
              className="btn-primary px-6 flex-shrink-0"
            >
              {loading ? (
                <svg className="w-5 h-5 animate-spin" viewBox="0 0 24 24" fill="none">
                  <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
                  <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8v8H4z" />
                </svg>
              ) : 'Search'}
            </button>
          </div>

          {error && (
            <p className="text-sm text-red-500 mt-2 flex items-center gap-1">
              <svg className="w-4 h-4 flex-shrink-0" fill="currentColor" viewBox="0 0 20 20">
                <path fillRule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7 4a1 1 0 11-2 0 1 1 0 012 0zm-1-9a1 1 0 00-1 1v4a1 1 0 102 0V6a1 1 0 00-1-1z" clipRule="evenodd" />
              </svg>
              {error}
            </p>
          )}
        </form>
      </div>

      {/* Help section */}
      <div className="mt-6 card p-5 bg-gov-cream border-gov-cream-dark">
        <h3 className="text-sm font-semibold text-gov-navy mb-2">Where is my complaint number?</h3>
        <ul className="text-sm text-gray-600 space-y-1 list-disc list-inside">
          <li>Your complaint number was shown on the confirmation screen after submission.</li>
          <li>A confirmation email with your complaint number was sent to the address you provided.</li>
          <li>Complaint numbers follow the format <span className="font-mono font-medium">COMP-YYYY-NNNNN</span>.</li>
        </ul>
        <p className="text-xs text-gray-400 mt-3">
          If you cannot find your complaint number, please contact the call center at 110.
        </p>
      </div>
    </div>
  )
}
