import { useState } from 'react'
import { Link } from 'react-router-dom'

const FAQ_ITEMS = [
  {
    q: 'How long does it take to process a complaint?',
    a: 'Standard complaints are processed within 7 business days from the date of submission. Complex cases — those requiring field investigation or inter-department coordination — may take up to 14 business days. You will be notified by email if extended processing time is required.',
  },
  {
    q: 'How will I know when my complaint is resolved?',
    a: 'You will receive an email notification at the address provided during submission when the status of your complaint changes. You can also check the status at any time using the Track Status page with your complaint number.',
  },
  {
    q: 'Can I attach supporting documents or photos?',
    a: 'Yes. Step 3 of the submission process allows you to upload photos, videos, PDF documents, Word documents, Excel spreadsheets, and ZIP archives. Each file must not exceed 50 MB. There is no limit on the number of files, but total upload size should be kept reasonable to avoid submission timeouts.',
  },
  {
    q: 'What is a complaint number and where do I find it?',
    a: 'A complaint number (e.g. COMP-2026-00042) is a unique identifier assigned to your submission upon completion. It is displayed on the confirmation screen immediately after submission and included in the confirmation email sent to your address. Keep this number safe — it is required to track your complaint status.',
  },
  {
    q: 'Can I submit a complaint anonymously?',
    a: 'Currently, this portal requires basic contact information (name, phone, and email) to process complaints. This information is used solely to notify you of updates and to follow up if clarification is needed. Your information is handled in accordance with the Valdoria Personal Information Protection Act and is not shared with third parties without your consent.',
  },
  {
    q: 'What types of complaints can I submit through this portal?',
    a: 'This portal accepts complaints in six categories: Road & Traffic (potholes, signage, traffic lights), Environment (waste, noise, water quality), Public Facility (parks, buildings, utilities), Social Welfare (benefit services, support programs), Technical / IT (government websites, e-services), and Other. For emergency issues such as fire or medical emergencies, please call 119. For criminal matters, call 112.',
  },
  {
    q: 'What happens if my complaint is rejected?',
    a: 'Complaints may be rejected if they fall outside the Ministry\'s jurisdiction, if duplicate submissions are detected, or if insufficient information is provided. In the event of rejection, you will receive an email explaining the reason and, where applicable, information on the appropriate authority or department to contact. You may resubmit with additional information if the reason for rejection can be addressed.',
  },
  {
    q: 'Can I update or withdraw my complaint after submission?',
    a: 'Submitted complaints cannot be edited through the portal. If you need to provide additional information or withdraw your complaint, please contact the call center at 110 with your complaint number ready. Staff will assist you with amendments or withdrawal requests during business hours (Monday–Friday, 09:00–18:00).',
  },
]

function FaqItem({ item, isOpen, onToggle }) {
  return (
    <div className="card overflow-hidden">
      <button
        type="button"
        onClick={onToggle}
        className="w-full flex items-center justify-between px-5 py-4 text-left gap-4 hover:bg-gray-50 transition-colors"
        aria-expanded={isOpen}
      >
        <span className="text-sm font-medium text-gov-navy leading-snug">{item.q}</span>
        <span
          className={`flex-shrink-0 w-6 h-6 rounded-full border-2 border-gov-navy flex items-center justify-center transition-transform ${
            isOpen ? 'bg-gov-navy rotate-180' : 'bg-white'
          }`}
        >
          <svg
            className={`w-3 h-3 transition-colors ${isOpen ? 'text-gov-gold' : 'text-gov-navy'}`}
            fill="none"
            viewBox="0 0 24 24"
            stroke="currentColor"
          >
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={3} d="M19 9l-7 7-7-7" />
          </svg>
        </span>
      </button>

      {isOpen && (
        <div className="px-5 pb-5 border-t border-gray-100">
          <p className="text-sm text-gray-600 leading-relaxed pt-4">{item.a}</p>
        </div>
      )}
    </div>
  )
}

export default function FaqPage() {
  const [openIndex, setOpenIndex] = useState(null)

  const toggle = (idx) => setOpenIndex((prev) => (prev === idx ? null : idx))

  return (
    <div className="max-w-3xl mx-auto px-4 py-10">
      {/* Page header */}
      <div className="text-center mb-8">
        <h1 className="text-2xl font-bold text-gov-navy mb-2">
          Frequently Asked Questions
        </h1>
        <p className="text-sm text-gray-500">
          Answers to common questions about the Valdoria MOIS Electronic Complaint Portal.
        </p>
      </div>

      {/* Accordion */}
      <div className="space-y-2 mb-10">
        {FAQ_ITEMS.map((item, idx) => (
          <FaqItem
            key={idx}
            item={item}
            isOpen={openIndex === idx}
            onToggle={() => toggle(idx)}
          />
        ))}
      </div>

      {/* Contact section */}
      <div className="card p-6 bg-gov-navy text-white text-center">
        <h2 className="text-base font-semibold mb-2">Still have questions?</h2>
        <p className="text-sm text-gray-300 mb-4">
          Our call center is available Monday through Friday, 09:00–18:00 (VDT).
        </p>
        <div className="flex flex-col sm:flex-row gap-3 justify-center items-center">
          <div className="flex items-center gap-2 text-gov-gold font-semibold">
            <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2}
                d="M3 5a2 2 0 012-2h3.28a1 1 0 01.948.684l1.498 4.493a1 1 0 01-.502 1.21l-2.257 1.13a11.042 11.042 0 005.516 5.516l1.13-2.257a1 1 0 011.21-.502l4.493 1.498a1 1 0 01.684.949V19a2 2 0 01-2 2h-1C9.716 21 3 14.284 3 6V5z" />
            </svg>
            110 (domestic)
          </div>
          <span className="text-gray-500 hidden sm:inline">|</span>
          <div className="flex items-center gap-2 text-gov-gold font-semibold">
            <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2}
                d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z" />
            </svg>
            mois@valdoria.gov.vl
          </div>
        </div>
        <div className="mt-4 flex gap-3 justify-center">
          <Link to="/submit" className="btn-gold text-sm px-5 py-2">
            Submit a Complaint
          </Link>
          <Link to="/status" className="btn-secondary text-sm px-5 py-2 border-gov-gold text-gov-gold hover:bg-gov-navy-light">
            Track Status
          </Link>
        </div>
      </div>
    </div>
  )
}
