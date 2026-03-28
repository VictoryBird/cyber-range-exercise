import { useState, useCallback } from 'react'
import { useDropzone } from 'react-dropzone'
import { toast } from 'react-toastify'
import { submitComplaint, uploadFile } from '../lib/api.js'

// ---- Category definitions ----
const CATEGORIES = [
  {
    id: 'road',
    label: 'Road & Traffic',
    korean: '도로/교통',
    icon: (
      <svg className="w-6 h-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5}
          d="M9 20l-5.447-2.724A1 1 0 013 16.382V5.618a1 1 0 011.447-.894L9 7m0 13l6-3m-6 3V7m6 10l4.553 2.276A1 1 0 0021 18.382V7.618a1 1 0 00-.553-.894L15 4m0 13V4m0 0L9 7" />
      </svg>
    ),
  },
  {
    id: 'environment',
    label: 'Environment',
    korean: '환경/위생',
    icon: (
      <svg className="w-6 h-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5}
          d="M3.055 11H5a2 2 0 012 2v1a2 2 0 002 2 2 2 0 012 2v2.945M8 3.935V5.5A2.5 2.5 0 0010.5 8h.5a2 2 0 012 2 2 2 0 104 0 2 2 0 012-2h1.064M15 20.488V18a2 2 0 012-2h3.064" />
      </svg>
    ),
  },
  {
    id: 'facility',
    label: 'Public Facility',
    korean: '공공시설',
    icon: (
      <svg className="w-6 h-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5}
          d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4" />
      </svg>
    ),
  },
  {
    id: 'welfare',
    label: 'Social Welfare',
    korean: '사회/복지',
    icon: (
      <svg className="w-6 h-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5}
          d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0z" />
      </svg>
    ),
  },
  {
    id: 'technical',
    label: 'Technical / IT',
    korean: '기술/정보화',
    icon: (
      <svg className="w-6 h-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5}
          d="M9.75 17L9 20l-1 1h8l-1-1-.75-3M3 13h18M5 17h14a2 2 0 002-2V5a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z" />
      </svg>
    ),
  },
  {
    id: 'other',
    label: 'Other',
    korean: '기타',
    icon: (
      <svg className="w-6 h-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5}
          d="M8.228 9c.549-1.165 2.03-2 3.772-2 2.21 0 4 1.343 4 3 0 1.4-1.278 2.575-3.006 2.907-.542.104-.994.54-.994 1.093m0 3h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
      </svg>
    ),
  },
]

const STEPS = ['Category', 'Details', 'Attachments', 'Review']

// ---- Step indicator ----
function StepIndicator({ current }) {
  return (
    <div className="flex items-center justify-center mb-8">
      {STEPS.map((label, idx) => {
        const step = idx + 1
        const done = step < current
        const active = step === current
        return (
          <div key={label} className="flex items-center">
            <div className="flex flex-col items-center">
              <div className={`w-9 h-9 rounded-full flex items-center justify-center text-sm font-semibold border-2 transition-colors ${
                done
                  ? 'bg-gov-navy border-gov-navy text-white'
                  : active
                  ? 'bg-gov-gold border-gov-gold text-gov-navy'
                  : 'bg-white border-gray-300 text-gray-400'
              }`}>
                {done ? (
                  <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={3} d="M5 13l4 4L19 7" />
                  </svg>
                ) : step}
              </div>
              <span className={`text-xs mt-1 font-medium ${active ? 'text-gov-navy' : 'text-gray-400'}`}>
                {label}
              </span>
            </div>
            {idx < STEPS.length - 1 && (
              <div className={`h-0.5 w-12 md:w-20 mx-1 mb-5 transition-colors ${done ? 'bg-gov-navy' : 'bg-gray-200'}`} />
            )}
          </div>
        )
      })}
    </div>
  )
}

// ---- File upload state for a single file ----
function FileItem({ file, progress, error, onRemove }) {
  const sizeMb = (file.size / 1024 / 1024).toFixed(2)
  return (
    <div className="flex items-center gap-3 p-3 bg-gray-50 rounded border border-gray-200">
      <svg className="w-5 h-5 text-gov-navy flex-shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor">
        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2}
          d="M15.172 7l-6.586 6.586a2 2 0 102.828 2.828l6.414-6.586a4 4 0 00-5.656-5.656l-6.415 6.585a6 6 0 108.486 8.486L20.5 13" />
      </svg>
      <div className="flex-1 min-w-0">
        <p className="text-sm font-medium text-gray-700 truncate">{file.name}</p>
        <p className="text-xs text-gray-400">{sizeMb} MB</p>
        {progress !== null && progress < 100 && !error && (
          <div className="mt-1 h-1.5 bg-gray-200 rounded-full overflow-hidden">
            <div
              className="h-full bg-gov-navy transition-all duration-200"
              style={{ width: `${progress}%` }}
            />
          </div>
        )}
        {error && <p className="text-xs text-red-500 mt-0.5">{error}</p>}
        {progress === 100 && !error && (
          <p className="text-xs text-green-600 mt-0.5">Uploaded successfully</p>
        )}
      </div>
      <button
        type="button"
        onClick={onRemove}
        className="text-gray-400 hover:text-red-500 transition-colors flex-shrink-0"
        aria-label="Remove file"
      >
        <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
        </svg>
      </button>
    </div>
  )
}

// ---- Success modal ----
function SuccessModal({ complaintNumber, onClose }) {
  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
      <div className="bg-white rounded-lg shadow-xl max-w-md w-full p-8 text-center">
        <div className="w-16 h-16 bg-green-100 rounded-full flex items-center justify-center mx-auto mb-4">
          <svg className="w-8 h-8 text-green-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
          </svg>
        </div>
        <h2 className="text-xl font-bold text-gov-navy mb-2">Complaint Submitted</h2>
        <p className="text-gray-500 text-sm mb-4">
          Your complaint has been received. Please save your complaint number for future reference.
        </p>
        <div className="bg-gov-cream border border-gov-gold rounded-lg p-4 mb-6">
          <p className="text-xs text-gray-500 mb-1">Complaint Number</p>
          <p className="text-2xl font-bold text-gov-navy tracking-wider">{complaintNumber}</p>
        </div>
        <p className="text-xs text-gray-400 mb-6">
          You will receive a confirmation via email. Processing typically takes 4–7 business days.
        </p>
        <div className="flex gap-3">
          <button
            onClick={onClose}
            className="flex-1 btn-secondary"
          >
            Submit Another
          </button>
          <a
            href={`/status/${complaintNumber}`}
            className="flex-1 btn-primary text-center"
          >
            Track Status
          </a>
        </div>
      </div>
    </div>
  )
}

// ---- Main component ----
export default function SubmitPage() {
  const [step, setStep] = useState(1)
  const [category, setCategory] = useState('')
  const [form, setForm] = useState({
    title: '',
    content: '',
    submitter_name: '',
    submitter_phone: '',
    submitter_email: '',
  })
  const [files, setFiles] = useState([])       // { file, progress, error }
  const [privacyConsent, setPrivacyConsent] = useState(false)
  const [submitting, setSubmitting] = useState(false)
  const [complaintNumber, setComplaintNumber] = useState(null)
  const [errors, setErrors] = useState({})

  // ---- Dropzone ----
  const onDrop = useCallback((accepted, rejected) => {
    if (rejected.length > 0) {
      toast.error('Some files were rejected. Max 50 MB per file.')
    }
    const newFiles = accepted.map((f) => ({ file: f, progress: null, error: null }))
    setFiles((prev) => [...prev, ...newFiles])
  }, [])

  const { getRootProps, getInputProps, isDragActive } = useDropzone({
    onDrop,
    maxSize: 50 * 1024 * 1024,
    multiple: true,
    accept: {
      'image/*': [],
      'video/*': [],
      'application/pdf': [],
      'application/msword': [],
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document': [],
      'application/vnd.ms-excel': [],
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet': [],
      'text/plain': [],
      'application/zip': [],
    },
  })

  const removeFile = (idx) => {
    setFiles((prev) => prev.filter((_, i) => i !== idx))
  }

  // ---- Validation ----
  const validateStep2 = () => {
    const errs = {}
    if (!form.title.trim()) errs.title = 'Title is required.'
    if (form.title.trim().length < 5) errs.title = 'Title must be at least 5 characters.'
    if (!form.content.trim()) errs.content = 'Please describe your complaint.'
    if (form.content.trim().length < 20) errs.content = 'Description must be at least 20 characters.'
    if (!form.submitter_name.trim()) errs.submitter_name = 'Your name is required.'
    if (!form.submitter_phone.trim()) errs.submitter_phone = 'Phone number is required.'
    if (!form.submitter_email.trim()) errs.submitter_email = 'Email address is required.'
    else if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(form.submitter_email)) {
      errs.submitter_email = 'Please enter a valid email address.'
    }
    return errs
  }

  const handleNext = () => {
    if (step === 1 && !category) {
      toast.warning('Please select a category before continuing.')
      return
    }
    if (step === 2) {
      const errs = validateStep2()
      if (Object.keys(errs).length > 0) {
        setErrors(errs)
        return
      }
      setErrors({})
    }
    setStep((s) => s + 1)
  }

  const handleBack = () => setStep((s) => s - 1)

  // ---- Submit ----
  const handleSubmit = async () => {
    if (!privacyConsent) {
      toast.warning('Please agree to the privacy policy before submitting.')
      return
    }
    setSubmitting(true)
    try {
      // Step 1: Submit complaint metadata
      const payload = {
        category,
        title: form.title,
        content: form.content,
        submitter_name: form.submitter_name,
        submitter_phone: form.submitter_phone,
        submitter_email: form.submitter_email,
      }
      const res = await submitComplaint(payload)
      const { complaint_id, complaint_number } = res.data

      // Step 2: Upload each file sequentially
      for (let i = 0; i < files.length; i++) {
        const entry = files[i]
        try {
          await uploadFile(complaint_id, entry.file, (pct) => {
            setFiles((prev) =>
              prev.map((f, idx) => (idx === i ? { ...f, progress: pct } : f))
            )
          })
          setFiles((prev) =>
            prev.map((f, idx) => (idx === i ? { ...f, progress: 100 } : f))
          )
        } catch (err) {
          const msg = err.userMessage || 'Upload failed.'
          setFiles((prev) =>
            prev.map((f, idx) => (idx === i ? { ...f, error: msg } : f))
          )
          toast.error(`File upload failed: ${entry.file.name}`)
        }
      }

      setComplaintNumber(complaint_number)
    } catch (err) {
      toast.error(err.userMessage || 'Submission failed. Please try again.')
    } finally {
      setSubmitting(false)
    }
  }

  const handleCloseSuccess = () => {
    setComplaintNumber(null)
    setStep(1)
    setCategory('')
    setForm({ title: '', content: '', submitter_name: '', submitter_phone: '', submitter_email: '' })
    setFiles([])
    setPrivacyConsent(false)
  }

  // ---- Render steps ----
  const renderStep1 = () => (
    <div>
      <h2 className="text-lg font-semibold text-gov-navy mb-1">Select Complaint Category</h2>
      <p className="text-sm text-gray-500 mb-5">
        Choose the category that best describes the issue you want to report.
      </p>
      <div className="grid grid-cols-2 md:grid-cols-3 gap-3">
        {CATEGORIES.map((cat) => (
          <button
            key={cat.id}
            type="button"
            onClick={() => setCategory(cat.id)}
            className={`flex flex-col items-center gap-2 p-5 rounded border-2 transition-all text-center ${
              category === cat.id
                ? 'border-gov-navy bg-gov-navy text-white shadow-md'
                : 'border-gray-200 bg-white text-gray-600 hover:border-gov-navy hover:shadow-sm'
            }`}
          >
            <span className={category === cat.id ? 'text-gov-gold' : 'text-gov-navy'}>
              {cat.icon}
            </span>
            <span className="font-medium text-sm leading-tight">{cat.label}</span>
            <span className={`text-xs ${category === cat.id ? 'text-gray-300' : 'text-gray-400'}`}>
              {cat.korean}
            </span>
          </button>
        ))}
      </div>
    </div>
  )

  const renderStep2 = () => (
    <div>
      <h2 className="text-lg font-semibold text-gov-navy mb-1">Complaint Details</h2>
      <p className="text-sm text-gray-500 mb-5">
        Please provide as much detail as possible to help us process your complaint efficiently.
      </p>
      <div className="space-y-4">
        <div>
          <label className="form-label" htmlFor="title">
            Complaint Title <span className="text-red-500">*</span>
          </label>
          <input
            id="title"
            type="text"
            className={`form-input ${errors.title ? 'border-red-400 focus:ring-red-400' : ''}`}
            placeholder="Brief summary of the issue (e.g. Pothole on Main Street near intersection)"
            value={form.title}
            onChange={(e) => setForm({ ...form, title: e.target.value })}
            maxLength={200}
          />
          {errors.title && <p className="text-xs text-red-500 mt-1">{errors.title}</p>}
        </div>

        <div>
          <label className="form-label" htmlFor="content">
            Description <span className="text-red-500">*</span>
          </label>
          <textarea
            id="content"
            className={`form-textarea min-h-32 ${errors.content ? 'border-red-400 focus:ring-red-400' : ''}`}
            placeholder="Describe the issue in detail. Include location, time of occurrence, and any relevant circumstances."
            value={form.content}
            onChange={(e) => setForm({ ...form, content: e.target.value })}
            rows={5}
          />
          <p className="text-xs text-gray-400 mt-1 text-right">{form.content.length} characters</p>
          {errors.content && <p className="text-xs text-red-500 mt-1">{errors.content}</p>}
        </div>

        <div className="border-t border-gray-200 pt-4">
          <p className="text-sm font-medium text-gray-700 mb-3">Submitter Information</p>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label className="form-label" htmlFor="submitter_name">
                Full Name <span className="text-red-500">*</span>
              </label>
              <input
                id="submitter_name"
                type="text"
                className={`form-input ${errors.submitter_name ? 'border-red-400' : ''}`}
                placeholder="Your full name"
                value={form.submitter_name}
                onChange={(e) => setForm({ ...form, submitter_name: e.target.value })}
              />
              {errors.submitter_name && <p className="text-xs text-red-500 mt-1">{errors.submitter_name}</p>}
            </div>
            <div>
              <label className="form-label" htmlFor="submitter_phone">
                Phone Number <span className="text-red-500">*</span>
              </label>
              <input
                id="submitter_phone"
                type="tel"
                className={`form-input ${errors.submitter_phone ? 'border-red-400' : ''}`}
                placeholder="+1-555-000-0000"
                value={form.submitter_phone}
                onChange={(e) => setForm({ ...form, submitter_phone: e.target.value })}
              />
              {errors.submitter_phone && <p className="text-xs text-red-500 mt-1">{errors.submitter_phone}</p>}
            </div>
            <div className="md:col-span-2">
              <label className="form-label" htmlFor="submitter_email">
                Email Address <span className="text-red-500">*</span>
              </label>
              <input
                id="submitter_email"
                type="email"
                className={`form-input ${errors.submitter_email ? 'border-red-400' : ''}`}
                placeholder="you@example.com"
                value={form.submitter_email}
                onChange={(e) => setForm({ ...form, submitter_email: e.target.value })}
              />
              {errors.submitter_email && <p className="text-xs text-red-500 mt-1">{errors.submitter_email}</p>}
            </div>
          </div>
        </div>
      </div>
    </div>
  )

  const renderStep3 = () => (
    <div>
      <h2 className="text-lg font-semibold text-gov-navy mb-1">Attach Supporting Files</h2>
      <p className="text-sm text-gray-500 mb-5">
        Upload photos, videos, or documents that support your complaint. This step is optional.
        Maximum 50 MB per file. Accepted formats: images, video, PDF, Word, Excel, ZIP.
      </p>

      {/* Dropzone */}
      <div
        {...getRootProps()}
        className={`border-2 border-dashed rounded-lg p-8 text-center cursor-pointer transition-colors mb-4 ${
          isDragActive
            ? 'border-gov-navy bg-blue-50'
            : 'border-gray-300 bg-gray-50 hover:border-gov-navy hover:bg-gov-cream'
        }`}
      >
        <input {...getInputProps()} />
        <svg className="w-10 h-10 text-gray-400 mx-auto mb-3" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5}
            d="M7 16a4 4 0 01-.88-7.903A5 5 0 1115.9 6L16 6a5 5 0 011 9.9M15 13l-3-3m0 0l-3 3m3-3v12" />
        </svg>
        {isDragActive ? (
          <p className="text-gov-navy font-medium">Drop files here...</p>
        ) : (
          <>
            <p className="text-gray-600 font-medium mb-1">Drag and drop files here</p>
            <p className="text-xs text-gray-400">or click to browse your computer</p>
          </>
        )}
      </div>

      {/* File list */}
      {files.length > 0 && (
        <div className="space-y-2">
          <p className="text-sm font-medium text-gray-700">{files.length} file(s) selected:</p>
          {files.map((entry, idx) => (
            <FileItem
              key={idx}
              file={entry.file}
              progress={entry.progress}
              error={entry.error}
              onRemove={() => removeFile(idx)}
            />
          ))}
        </div>
      )}

      {files.length === 0 && (
        <p className="text-sm text-gray-400 italic">
          No files attached. You may skip this step.
        </p>
      )}
    </div>
  )

  const selectedCategory = CATEGORIES.find((c) => c.id === category)

  const renderStep4 = () => (
    <div>
      <h2 className="text-lg font-semibold text-gov-navy mb-1">Review &amp; Confirm</h2>
      <p className="text-sm text-gray-500 mb-5">
        Please review your complaint information before submitting.
      </p>

      <div className="space-y-4">
        {/* Summary card */}
        <div className="card divide-y divide-gray-100">
          <div className="p-4 flex items-center gap-2">
            <span className="text-xs font-medium text-gray-500 w-28 flex-shrink-0">Category</span>
            <span className="text-sm text-gray-800 font-medium">
              {selectedCategory?.label} ({selectedCategory?.korean})
            </span>
          </div>
          <div className="p-4 flex items-start gap-2">
            <span className="text-xs font-medium text-gray-500 w-28 flex-shrink-0 pt-0.5">Title</span>
            <span className="text-sm text-gray-800">{form.title}</span>
          </div>
          <div className="p-4 flex items-start gap-2">
            <span className="text-xs font-medium text-gray-500 w-28 flex-shrink-0 pt-0.5">Description</span>
            <span className="text-sm text-gray-600 whitespace-pre-wrap leading-relaxed">{form.content}</span>
          </div>
          <div className="p-4 flex items-center gap-2">
            <span className="text-xs font-medium text-gray-500 w-28 flex-shrink-0">Name</span>
            <span className="text-sm text-gray-800">{form.submitter_name}</span>
          </div>
          <div className="p-4 flex items-center gap-2">
            <span className="text-xs font-medium text-gray-500 w-28 flex-shrink-0">Phone</span>
            <span className="text-sm text-gray-800">{form.submitter_phone}</span>
          </div>
          <div className="p-4 flex items-center gap-2">
            <span className="text-xs font-medium text-gray-500 w-28 flex-shrink-0">Email</span>
            <span className="text-sm text-gray-800">{form.submitter_email}</span>
          </div>
          <div className="p-4 flex items-center gap-2">
            <span className="text-xs font-medium text-gray-500 w-28 flex-shrink-0">Attachments</span>
            <span className="text-sm text-gray-800">
              {files.length > 0
                ? files.map((e) => e.file.name).join(', ')
                : 'None'}
            </span>
          </div>
        </div>

        {/* Privacy consent */}
        <div className="card p-4 bg-blue-50 border-blue-100">
          <label className="flex items-start gap-3 cursor-pointer">
            <input
              type="checkbox"
              checked={privacyConsent}
              onChange={(e) => setPrivacyConsent(e.target.checked)}
              className="mt-0.5 w-4 h-4 accent-gov-navy flex-shrink-0"
            />
            <span className="text-sm text-gray-700 leading-relaxed">
              I agree to the{' '}
              <a href="#" className="text-gov-navy underline hover:text-gov-navy-light">
                Privacy Policy
              </a>{' '}
              and consent to the Ministry of the Interior and Safety collecting and processing my
              personal information for the purpose of handling this complaint. I understand that
              my information will be retained for 3 years in accordance with applicable law.
            </span>
          </label>
        </div>

        <p className="text-xs text-gray-400">
          By submitting this form, you confirm that the information provided is accurate and complete.
          Providing false information is a violation of the Civil Petitions Act (Article 17).
        </p>
      </div>
    </div>
  )

  return (
    <div className="max-w-3xl mx-auto px-4 py-10">
      {/* Page header */}
      <div className="mb-6">
        <h1 className="text-2xl font-bold text-gov-navy">민원 접수하기 — Submit a Complaint</h1>
        <p className="text-sm text-gray-500 mt-1">
          Complete all steps to submit your complaint to the Valdoria Ministry of the Interior and Safety.
        </p>
      </div>

      <div className="card p-6 md:p-8">
        <StepIndicator current={step} />

        <div className="min-h-64">
          {step === 1 && renderStep1()}
          {step === 2 && renderStep2()}
          {step === 3 && renderStep3()}
          {step === 4 && renderStep4()}
        </div>

        {/* Navigation buttons */}
        <div className="flex justify-between mt-8 pt-5 border-t border-gray-200">
          {step > 1 ? (
            <button type="button" onClick={handleBack} className="btn-secondary" disabled={submitting}>
              Back
            </button>
          ) : (
            <div />
          )}

          {step < 4 ? (
            <button type="button" onClick={handleNext} className="btn-primary">
              Continue
            </button>
          ) : (
            <button
              type="button"
              onClick={handleSubmit}
              disabled={submitting || !privacyConsent}
              className="btn-primary min-w-32"
            >
              {submitting ? (
                <span className="flex items-center gap-2">
                  <svg className="w-4 h-4 animate-spin" viewBox="0 0 24 24" fill="none">
                    <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
                    <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8v8H4z" />
                  </svg>
                  Submitting...
                </span>
              ) : 'Submit Complaint'}
            </button>
          )}
        </div>
      </div>

      {complaintNumber && (
        <SuccessModal complaintNumber={complaintNumber} onClose={handleCloseSuccess} />
      )}
    </div>
  )
}
