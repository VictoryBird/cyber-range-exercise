import { useState, useEffect } from 'react'
import { useParams, Link } from 'react-router-dom'
import { getComplaint, getDownloadUrl } from '../lib/api.js'

const CATEGORY_LABELS = {
  road: 'Road & Traffic',
  environment: 'Environment',
  facility: 'Public Facility',
  welfare: 'Social Welfare',
  technical: 'Technical / IT',
  other: 'Other',
}

const STATUS_STEPS = [
  { key: 'received', label: 'Received', desc: 'Complaint received by the system.' },
  { key: 'processing', label: 'Under Review', desc: 'Being reviewed by a case officer.' },
  { key: 'completed', label: 'Resolved', desc: 'Complaint has been processed and closed.' },
]

function getStatusIndex(status) {
  if (!status) return 0
  const s = status.toLowerCase()
  if (s === 'completed' || s === 'resolved') return 2
  if (s === 'processing' || s === 'in_progress' || s === 'under_review') return 1
  return 0
}

function StatusBadge({ status }) {
  const s = (status || '').toLowerCase()
  if (s === 'completed' || s === 'resolved') return <span className="badge-completed">{status}</span>
  if (s === 'processing' || s === 'in_progress') return <span className="badge-processing">{status}</span>
  if (s === 'rejected') return <span className="badge-rejected">{status}</span>
  return <span className="badge-received">{status || 'Received'}</span>
}

function Timeline({ status }) {
  const current = getStatusIndex(status)
  return (
    <div className="flex items-start gap-0 mt-2">
      {STATUS_STEPS.map((step, idx) => {
        const done = idx <= current
        const active = idx === current
        return (
          <div key={step.key} className="flex items-start flex-1">
            <div className="flex flex-col items-center flex-shrink-0">
              <div className={`w-8 h-8 rounded-full flex items-center justify-center border-2 ${
                done
                  ? 'bg-gov-navy border-gov-navy text-white'
                  : 'bg-white border-gray-200 text-gray-300'
              }`}>
                {done && idx < current ? (
                  <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={3} d="M5 13l4 4L19 7" />
                  </svg>
                ) : (
                  <span className={`text-xs font-bold ${done ? 'text-gov-gold' : ''}`}>{idx + 1}</span>
                )}
              </div>
              <p className={`text-xs font-medium mt-1 text-center max-w-16 leading-tight ${
                active ? 'text-gov-navy' : done ? 'text-gray-600' : 'text-gray-300'
              }`}>
                {step.label}
              </p>
            </div>
            {idx < STATUS_STEPS.length - 1 && (
              <div className={`flex-1 h-0.5 mt-4 mx-1 ${done && idx < current ? 'bg-gov-navy' : 'bg-gray-200'}`} />
            )}
          </div>
        )
      })}
    </div>
  )
}

export default function StatusDetailPage() {
  const { id } = useParams()
  const [complaint, setComplaint] = useState(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(null)

  useEffect(() => {
    if (!id) return
    setLoading(true)
    setError(null)
    getComplaint(id)
      .then((res) => setComplaint(res.data))
      .catch((err) => {
        if (err.response?.status === 404) {
          setError('Complaint not found. Please check your complaint number.')
        } else {
          setError(err.userMessage || 'Failed to load complaint details. Please try again.')
        }
      })
      .finally(() => setLoading(false))
  }, [id])

  if (loading) {
    return (
      <div className="max-w-3xl mx-auto px-4 py-20 text-center">
        <svg className="w-10 h-10 text-gov-navy animate-spin mx-auto mb-4" viewBox="0 0 24 24" fill="none">
          <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
          <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8v8H4z" />
        </svg>
        <p className="text-gray-500 text-sm">Loading complaint details...</p>
      </div>
    )
  }

  if (error) {
    return (
      <div className="max-w-3xl mx-auto px-4 py-16 text-center">
        <div className="card p-10">
          <svg className="w-12 h-12 text-red-400 mx-auto mb-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2}
              d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
          </svg>
          <h2 className="text-lg font-semibold text-gray-800 mb-2">Unable to Load Complaint</h2>
          <p className="text-sm text-gray-500 mb-6">{error}</p>
          <Link to="/status" className="btn-primary">
            Search Again
          </Link>
        </div>
      </div>
    )
  }

  if (!complaint) return null

  const attachments = complaint.attachments || []

  return (
    <div className="max-w-3xl mx-auto px-4 py-10">
      {/* Breadcrumb */}
      <nav className="text-sm text-gray-400 mb-4 flex items-center gap-1">
        <Link to="/" className="hover:text-gov-navy">Home</Link>
        <span>/</span>
        <Link to="/status" className="hover:text-gov-navy">Track Status</Link>
        <span>/</span>
        <span className="text-gray-600 font-mono">{id}</span>
      </nav>

      {/* Status header card */}
      <div className="card p-6 mb-5 border-l-4 border-gov-navy">
        <div className="flex flex-col md:flex-row md:items-start md:justify-between gap-3 mb-5">
          <div>
            <p className="text-xs text-gray-400 font-mono mb-0.5">{complaint.complaint_number || id}</p>
            <h1 className="text-xl font-bold text-gov-navy leading-snug">{complaint.title}</h1>
          </div>
          <div className="flex-shrink-0">
            <StatusBadge status={complaint.status} />
          </div>
        </div>

        {/* Timeline */}
        <Timeline status={complaint.status} />

        {complaint.status_message && (
          <div className="mt-4 p-3 bg-blue-50 border border-blue-100 rounded text-sm text-blue-800">
            <strong>Status note:</strong> {complaint.status_message}
          </div>
        )}
      </div>

      {/* Complaint detail card */}
      <div className="card p-6 mb-5">
        <h2 className="text-sm font-semibold text-gov-navy uppercase tracking-wide mb-4">Complaint Information</h2>
        <div className="divide-y divide-gray-100">
          <div className="py-3 grid grid-cols-3 gap-4">
            <span className="text-xs font-medium text-gray-500">Category</span>
            <span className="col-span-2 text-sm text-gray-800">
              {CATEGORY_LABELS[complaint.category] || complaint.category}
            </span>
          </div>
          <div className="py-3 grid grid-cols-3 gap-4">
            <span className="text-xs font-medium text-gray-500">Submitted</span>
            <span className="col-span-2 text-sm text-gray-800">
              {complaint.created_at
                ? new Date(complaint.created_at).toLocaleString('en-GB', {
                    year: 'numeric', month: 'long', day: 'numeric',
                    hour: '2-digit', minute: '2-digit',
                  })
                : '—'}
            </span>
          </div>
          {complaint.updated_at && (
            <div className="py-3 grid grid-cols-3 gap-4">
              <span className="text-xs font-medium text-gray-500">Last Updated</span>
              <span className="col-span-2 text-sm text-gray-800">
                {new Date(complaint.updated_at).toLocaleString('en-GB', {
                  year: 'numeric', month: 'long', day: 'numeric',
                  hour: '2-digit', minute: '2-digit',
                })}
              </span>
            </div>
          )}
          <div className="py-3 grid grid-cols-3 gap-4">
            <span className="text-xs font-medium text-gray-500">Description</span>
            <span className="col-span-2 text-sm text-gray-600 leading-relaxed whitespace-pre-wrap">
              {complaint.content}
            </span>
          </div>
        </div>
      </div>

      {/* Attachments */}
      {attachments.length > 0 && (
        <div className="card p-6 mb-5">
          <h2 className="text-sm font-semibold text-gov-navy uppercase tracking-wide mb-4">
            Attachments ({attachments.length})
          </h2>
          <div className="space-y-2">
            {attachments.map((att) => (
              <div key={att.file_id || att.id} className="flex items-center gap-3 p-3 bg-gray-50 rounded border border-gray-200">
                <svg className="w-5 h-5 text-gov-navy flex-shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2}
                    d="M15.172 7l-6.586 6.586a2 2 0 102.828 2.828l6.414-6.586a4 4 0 00-5.656-5.656l-6.415 6.585a6 6 0 108.486 8.486L20.5 13" />
                </svg>
                <div className="flex-1 min-w-0">
                  <p className="text-sm font-medium text-gray-700 truncate">{att.filename || att.name}</p>
                  {att.file_size && (
                    <p className="text-xs text-gray-400">{(att.file_size / 1024 / 1024).toFixed(2)} MB</p>
                  )}
                </div>
                <a
                  href={getDownloadUrl(complaint.complaint_number || id, att.file_id || att.id)}
                  className="text-gov-navy hover:text-gov-gold transition-colors flex-shrink-0"
                  title="Download file"
                  download
                >
                  <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2}
                      d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-4l-4 4m0 0l-4-4m4 4V4" />
                  </svg>
                </a>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* Submitter info */}
      <div className="card p-6 mb-8">
        <h2 className="text-sm font-semibold text-gov-navy uppercase tracking-wide mb-4">Submitter Information</h2>
        <div className="divide-y divide-gray-100">
          <div className="py-3 grid grid-cols-3 gap-4">
            <span className="text-xs font-medium text-gray-500">Name</span>
            <span className="col-span-2 text-sm text-gray-800">{complaint.submitter_name}</span>
          </div>
          <div className="py-3 grid grid-cols-3 gap-4">
            <span className="text-xs font-medium text-gray-500">Phone</span>
            <span className="col-span-2 text-sm text-gray-800">{complaint.submitter_phone}</span>
          </div>
          <div className="py-3 grid grid-cols-3 gap-4">
            <span className="text-xs font-medium text-gray-500">Email</span>
            <span className="col-span-2 text-sm text-gray-800">{complaint.submitter_email}</span>
          </div>
        </div>
      </div>

      <div className="flex gap-3">
        <Link to="/status" className="btn-secondary">
          Search Another
        </Link>
        <Link to="/submit" className="btn-primary">
          Submit New Complaint
        </Link>
      </div>
    </div>
  )
}
