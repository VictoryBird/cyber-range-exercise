import { Link } from 'react-router-dom'

const ANNOUNCEMENTS = [
  {
    id: 1,
    date: '2026-03-25',
    tag: 'Notice',
    title: 'System maintenance scheduled: April 5, 02:00–04:00 (VDT)',
    content: 'The complaint portal will be temporarily unavailable during scheduled maintenance.',
  },
  {
    id: 2,
    date: '2026-03-20',
    tag: 'Update',
    title: 'Average processing time improved to 4.2 business days in Q1 2026',
    content: 'We continue to reduce turnaround time through process automation improvements.',
  },
  {
    id: 3,
    date: '2026-03-10',
    tag: 'Policy',
    title: 'New complaint categories added: Urban Noise and Public Lighting',
    content: 'Two new complaint categories are now available to better address citizen concerns.',
  },
]

const FAQ_PREVIEW = [
  {
    q: 'How long does it take to process a complaint?',
    a: 'Standard complaints are processed within 7 business days. Complex cases may take up to 14 business days.',
  },
  {
    q: 'Can I attach supporting documents to my complaint?',
    a: 'Yes. You may attach photos, videos, or documents up to 50 MB each during Step 3 of the submission process.',
  },
  {
    q: 'How do I check my complaint status?',
    a: 'Use the "Track Status" page and enter your complaint number (COMP-YYYY-NNNNN) to view real-time status.',
  },
]

const STATS = [
  { label: 'Complaints Resolved (2026)', value: '12,847' },
  { label: 'Average Processing Days', value: '4.2' },
  { label: 'Satisfaction Rate', value: '91%' },
  { label: 'Categories Available', value: '8' },
]

export default function HomePage() {
  return (
    <div>
      {/* Hero Banner */}
      <section className="bg-gov-navy text-white">
        <div className="max-w-6xl mx-auto px-4 py-16 md:py-20 text-center">
          <p className="text-gov-gold text-sm font-medium tracking-widest uppercase mb-3">
            발도리아 행정안전부 전자민원 포털
          </p>
          <h1 className="text-3xl md:text-4xl font-bold leading-tight mb-4">
            Valdoria Electronic Complaint Portal
          </h1>
          <p className="text-gray-300 text-base max-w-2xl mx-auto mb-8 leading-relaxed">
            Submit complaints, inquiries, and suggestions to the Ministry of the Interior
            and Safety. Track your submission in real time and receive official responses
            within the statutory timeframe.
          </p>
          <div className="flex flex-col sm:flex-row gap-3 justify-center">
            <Link to="/submit" className="btn-gold text-base px-8 py-3">
              Submit a Complaint
            </Link>
            <Link to="/status" className="btn-secondary text-base px-8 py-3">
              Track Status
            </Link>
          </div>
        </div>
      </section>

      {/* Stats bar */}
      <section className="bg-gov-cream-dark border-b border-gray-200">
        <div className="max-w-6xl mx-auto px-4 py-4 grid grid-cols-2 md:grid-cols-4 gap-4">
          {STATS.map((s) => (
            <div key={s.label} className="text-center">
              <div className="text-2xl font-bold text-gov-navy">{s.value}</div>
              <div className="text-xs text-gray-500 mt-0.5">{s.label}</div>
            </div>
          ))}
        </div>
      </section>

      <div className="max-w-6xl mx-auto px-4 py-10">
        {/* Quick link cards */}
        <div className="grid grid-cols-1 md:grid-cols-2 gap-5 mb-10">
          <Link
            to="/submit"
            className="card p-6 hover:shadow-md transition-shadow group border-l-4 border-gov-navy"
          >
            <div className="flex items-start gap-4">
              <div className="w-12 h-12 bg-gov-navy rounded flex items-center justify-center flex-shrink-0">
                <svg className="w-6 h-6 text-gov-gold" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2}
                    d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z" />
                </svg>
              </div>
              <div>
                <h2 className="text-lg font-semibold text-gov-navy group-hover:text-gov-navy-light transition-colors mb-1">
                  민원 접수하기 — Submit a Complaint
                </h2>
                <p className="text-sm text-gray-500 leading-relaxed">
                  File a new complaint with our 4-step guided wizard. Attach supporting
                  documents and receive a complaint number instantly upon submission.
                </p>
                <span className="inline-block mt-3 text-sm font-medium text-gov-navy group-hover:underline">
                  Start here &rarr;
                </span>
              </div>
            </div>
          </Link>

          <Link
            to="/status"
            className="card p-6 hover:shadow-md transition-shadow group border-l-4 border-gov-gold"
          >
            <div className="flex items-start gap-4">
              <div className="w-12 h-12 bg-gov-gold rounded flex items-center justify-center flex-shrink-0">
                <svg className="w-6 h-6 text-gov-navy" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2}
                    d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-6 9l2 2 4-4" />
                </svg>
              </div>
              <div>
                <h2 className="text-lg font-semibold text-gov-navy group-hover:text-gov-navy-light transition-colors mb-1">
                  처리현황 조회 — Track Status
                </h2>
                <p className="text-sm text-gray-500 leading-relaxed">
                  Check the current processing status of your complaint using your complaint
                  number (format: COMP-YYYY-NNNNN).
                </p>
                <span className="inline-block mt-3 text-sm font-medium text-gov-navy group-hover:underline">
                  Check status &rarr;
                </span>
              </div>
            </div>
          </Link>
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
          {/* Announcements */}
          <div className="lg:col-span-2">
            <h2 className="section-title">Announcements</h2>
            <div className="space-y-3">
              {ANNOUNCEMENTS.map((item) => (
                <div key={item.id} className="card p-4 hover:shadow transition-shadow">
                  <div className="flex items-start gap-3">
                    <span className="badge bg-gov-navy text-gov-gold text-xs flex-shrink-0 mt-0.5">
                      {item.tag}
                    </span>
                    <div className="flex-1 min-w-0">
                      <h3 className="text-sm font-medium text-gray-800 leading-snug mb-1">
                        {item.title}
                      </h3>
                      <p className="text-xs text-gray-500">{item.content}</p>
                    </div>
                    <span className="text-xs text-gray-400 flex-shrink-0">{item.date}</span>
                  </div>
                </div>
              ))}
            </div>
          </div>

          {/* FAQ Preview */}
          <div>
            <h2 className="section-title">Frequently Asked</h2>
            <div className="space-y-3">
              {FAQ_PREVIEW.map((item, idx) => (
                <div key={idx} className="card p-4">
                  <p className="text-sm font-medium text-gov-navy mb-1">{item.q}</p>
                  <p className="text-xs text-gray-500 leading-relaxed">{item.a}</p>
                </div>
              ))}
            </div>
            <Link
              to="/faq"
              className="inline-block mt-4 text-sm text-gov-navy font-medium hover:underline"
            >
              View all FAQs &rarr;
            </Link>
          </div>
        </div>

        {/* How it works */}
        <div className="mt-10">
          <h2 className="section-title">How It Works</h2>
          <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
            {[
              { step: 1, title: 'Select Category', desc: 'Choose the complaint type that best describes your issue.' },
              { step: 2, title: 'Provide Details', desc: 'Enter your contact information and describe the problem clearly.' },
              { step: 3, title: 'Attach Files', desc: 'Upload supporting documents, photos, or videos (optional).' },
              { step: 4, title: 'Receive Confirmation', desc: 'Get a unique complaint number and track progress online.' },
            ].map(({ step, title, desc }) => (
              <div key={step} className="card p-4 text-center">
                <div className="w-10 h-10 rounded-full bg-gov-navy text-white text-lg font-bold flex items-center justify-center mx-auto mb-3">
                  {step}
                </div>
                <h3 className="text-sm font-semibold text-gov-navy mb-1">{title}</h3>
                <p className="text-xs text-gray-500 leading-relaxed">{desc}</p>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  )
}
