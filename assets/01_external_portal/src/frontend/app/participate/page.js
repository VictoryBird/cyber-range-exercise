"use client";

import Link from "next/link";
import { useState } from "react";

const RECENT_PROPOSALS = [
  {
    title: "Extended library operating hours",
    submitted: "Feb 28",
    status: "Under Review",
    statusColor: "bg-yellow-100 text-yellow-700",
  },
  {
    title: "Solar panel subsidies for residential buildings",
    submitted: "Feb 15",
    status: "Forwarded to Energy Ministry",
    statusColor: "bg-blue-100 text-blue-700",
  },
  {
    title: "More bike lanes in Capital District",
    submitted: "Feb 10",
    status: "Approved for Study",
    statusColor: "bg-green-100 text-green-700",
  },
  {
    title: "Multilingual support for government websites",
    submitted: "Jan 28",
    status: "Implementation Planned",
    statusColor: "bg-purple-100 text-purple-700",
  },
];

const CATEGORIES = [
  "Public Safety",
  "Digital Services",
  "Administration",
  "Infrastructure",
  "Other",
];

const PARTICIPATION_STATS = [
  { value: "23,456", label: "Proposals submitted in 2025" },
  { value: "67%", label: "Received a formal response" },
  { value: "12", label: "Proposals implemented" },
];

export default function ParticipatePage() {
  const [formData, setFormData] = useState({
    name: "",
    email: "",
    category: "",
    title: "",
    description: "",
  });
  const [submitted, setSubmitted] = useState(false);
  const [errors, setErrors] = useState({});

  function validate() {
    const newErrors = {};
    if (!formData.name.trim()) newErrors.name = "Name is required.";
    if (!formData.email.trim()) newErrors.email = "Email is required.";
    else if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(formData.email))
      newErrors.email = "Enter a valid email address.";
    if (!formData.category) newErrors.category = "Please select a category.";
    if (!formData.title.trim()) newErrors.title = "Proposal title is required.";
    if (!formData.description.trim())
      newErrors.description = "Description is required.";
    return newErrors;
  }

  function handleChange(e) {
    const { name, value } = e.target;
    setFormData((prev) => ({ ...prev, [name]: value }));
    if (errors[name]) {
      setErrors((prev) => ({ ...prev, [name]: undefined }));
    }
  }

  function handleSubmit(e) {
    e.preventDefault();
    const newErrors = validate();
    if (Object.keys(newErrors).length > 0) {
      setErrors(newErrors);
      return;
    }
    setSubmitted(true);
    setFormData({ name: "", email: "", category: "", title: "", description: "" });
  }

  return (
    <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
      {/* Breadcrumb */}
      <nav className="flex items-center gap-2 text-sm mb-6" aria-label="Breadcrumb">
        <Link href="/" className="breadcrumb-link">
          Home
        </Link>
        <svg className="w-3.5 h-3.5 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5l7 7-7 7" />
        </svg>
        <span className="text-gray-600 font-medium">Citizen Participation</span>
      </nav>

      <div className="mb-8">
        <h1 className="text-3xl font-bold text-gray-900 mb-2">Citizen Participation</h1>
        <p className="text-gray-500 max-w-2xl">
          Your voice matters in shaping Valdoria&#39;s future. Take part in surveys, submit policy proposals, and track how your ideas make a difference.
        </p>
      </div>

      {/* Active Survey */}
      <div className="bg-valdoria-navy rounded-xl p-6 mb-8 flex flex-col sm:flex-row items-start sm:items-center gap-6">
        <div className="flex-1">
          <div className="flex items-center gap-2 mb-2">
            <span className="text-xs font-semibold px-2 py-0.5 rounded bg-valdoria-gold text-valdoria-navy uppercase tracking-wide">
              Active Survey
            </span>
            <span className="text-xs text-white/60">Open until April 30, 2026</span>
          </div>
          <h2 className="text-lg font-bold text-white mb-1">
            2026 Public Services Satisfaction Survey
          </h2>
          <p className="text-sm text-white/75 leading-relaxed mb-2">
            Help us improve government services. Share your experience with digital government platforms, safety services, and administrative processes.
          </p>
          <p className="text-xs text-white/50">
            <svg className="w-3.5 h-3.5 inline mr-1 -mt-0.5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0z" />
            </svg>
            12,847 responses so far
          </p>
        </div>
        <a
          href="#"
          className="flex-shrink-0 bg-valdoria-gold text-valdoria-navy font-semibold text-sm px-5 py-2.5 rounded-lg hover:bg-yellow-400 transition-colors"
        >
          Take Survey
        </a>
      </div>

      <div className="lg:grid lg:grid-cols-2 lg:gap-8">
        {/* Policy Proposal Form */}
        <div>
          <h2 className="text-xs font-semibold text-valdoria-navy uppercase tracking-widest mb-4">
            Submit a Policy Proposal
          </h2>

          {submitted ? (
            <div className="bg-green-50 border border-green-200 rounded-lg p-6 flex items-start gap-3">
              <div className="flex-shrink-0 w-8 h-8 rounded-full bg-green-100 flex items-center justify-center text-green-600">
                <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
                </svg>
              </div>
              <div>
                <p className="font-semibold text-green-800 mb-1">Proposal Submitted</p>
                <p className="text-sm text-green-700">
                  Thank you for your proposal. The relevant department will review it within 14 business days and notify you by email.
                </p>
                <button
                  onClick={() => setSubmitted(false)}
                  className="mt-3 text-sm text-green-700 underline hover:text-green-900 transition-colors"
                >
                  Submit another proposal
                </button>
              </div>
            </div>
          ) : (
            <form onSubmit={handleSubmit} noValidate className="govt-card space-y-4">
              {/* Name */}
              <div>
                <label htmlFor="name" className="block text-sm font-medium text-gray-700 mb-1">
                  Name <span className="text-red-500">*</span>
                </label>
                <input
                  id="name"
                  name="name"
                  type="text"
                  value={formData.name}
                  onChange={handleChange}
                  className={`w-full border rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-valdoria-navy/40 ${
                    errors.name ? "border-red-400" : "border-gray-300"
                  }`}
                  placeholder="Full name"
                />
                {errors.name && <p className="text-xs text-red-500 mt-1">{errors.name}</p>}
              </div>

              {/* Email */}
              <div>
                <label htmlFor="email" className="block text-sm font-medium text-gray-700 mb-1">
                  Email <span className="text-red-500">*</span>
                </label>
                <input
                  id="email"
                  name="email"
                  type="email"
                  value={formData.email}
                  onChange={handleChange}
                  className={`w-full border rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-valdoria-navy/40 ${
                    errors.email ? "border-red-400" : "border-gray-300"
                  }`}
                  placeholder="your@email.com"
                />
                {errors.email && <p className="text-xs text-red-500 mt-1">{errors.email}</p>}
              </div>

              {/* Category */}
              <div>
                <label htmlFor="category" className="block text-sm font-medium text-gray-700 mb-1">
                  Category <span className="text-red-500">*</span>
                </label>
                <select
                  id="category"
                  name="category"
                  value={formData.category}
                  onChange={handleChange}
                  className={`w-full border rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-valdoria-navy/40 bg-white ${
                    errors.category ? "border-red-400" : "border-gray-300"
                  }`}
                >
                  <option value="">Select a category</option>
                  {CATEGORIES.map((cat) => (
                    <option key={cat} value={cat}>
                      {cat}
                    </option>
                  ))}
                </select>
                {errors.category && (
                  <p className="text-xs text-red-500 mt-1">{errors.category}</p>
                )}
              </div>

              {/* Title */}
              <div>
                <label htmlFor="title" className="block text-sm font-medium text-gray-700 mb-1">
                  Proposal Title <span className="text-red-500">*</span>
                </label>
                <input
                  id="title"
                  name="title"
                  type="text"
                  value={formData.title}
                  onChange={handleChange}
                  className={`w-full border rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-valdoria-navy/40 ${
                    errors.title ? "border-red-400" : "border-gray-300"
                  }`}
                  placeholder="Brief title for your proposal"
                />
                {errors.title && <p className="text-xs text-red-500 mt-1">{errors.title}</p>}
              </div>

              {/* Description */}
              <div>
                <label htmlFor="description" className="block text-sm font-medium text-gray-700 mb-1">
                  Description <span className="text-red-500">*</span>
                </label>
                <textarea
                  id="description"
                  name="description"
                  rows={4}
                  value={formData.description}
                  onChange={handleChange}
                  className={`w-full border rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-valdoria-navy/40 resize-none ${
                    errors.description ? "border-red-400" : "border-gray-300"
                  }`}
                  placeholder="Describe your proposal in detail..."
                />
                {errors.description && (
                  <p className="text-xs text-red-500 mt-1">{errors.description}</p>
                )}
              </div>

              <div className="pt-1">
                <button type="submit" className="govt-btn-primary w-full justify-center flex">
                  Submit Proposal
                </button>
                <p className="text-xs text-gray-400 mt-2 text-center">
                  Proposals are reviewed by the relevant department within 14 business days.
                </p>
              </div>
            </form>
          )}
        </div>

        {/* Recent Proposals + Stats */}
        <div className="mt-8 lg:mt-0 space-y-6">
          {/* Recent Proposals */}
          <div>
            <h2 className="text-xs font-semibold text-valdoria-navy uppercase tracking-widest mb-4">
              Recent Citizen Proposals
            </h2>
            <div className="bg-white border border-gray-200 rounded-lg divide-y divide-gray-100">
              {RECENT_PROPOSALS.map((proposal) => (
                <div key={proposal.title} className="flex items-start gap-3 px-4 py-3.5">
                  <div className="flex-1 min-w-0">
                    <p className="text-sm font-medium text-gray-900">{proposal.title}</p>
                    <p className="text-xs text-gray-400 mt-0.5">Submitted {proposal.submitted}</p>
                  </div>
                  <span
                    className={`text-xs font-medium px-2 py-0.5 rounded flex-shrink-0 mt-0.5 ${proposal.statusColor}`}
                  >
                    {proposal.status}
                  </span>
                </div>
              ))}
            </div>
          </div>

          {/* Participation Statistics */}
          <div className="bg-valdoria-cream border border-valdoria-gold/30 rounded-lg p-5">
            <h2 className="text-sm font-semibold text-valdoria-navy mb-4 flex items-center gap-2">
              <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  strokeWidth={1.5}
                  d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z"
                />
              </svg>
              Participation Statistics
            </h2>
            <div className="grid grid-cols-3 gap-3 text-center">
              {PARTICIPATION_STATS.map((stat) => (
                <div key={stat.label}>
                  <p className="text-xl font-bold text-valdoria-navy">{stat.value}</p>
                  <p className="text-xs text-gray-500 leading-snug mt-0.5">{stat.label}</p>
                </div>
              ))}
            </div>
          </div>

          {/* How it works */}
          <div className="govt-card">
            <h2 className="text-sm font-semibold text-valdoria-navy mb-3">How It Works</h2>
            <ol className="space-y-3">
              {[
                "Submit your proposal using the form.",
                "The relevant department reviews it within 14 business days.",
                "You receive an official response by email.",
                "Approved proposals are listed in the public register.",
              ].map((step, i) => (
                <li key={step} className="flex items-start gap-3 text-sm text-gray-600">
                  <span className="flex-shrink-0 w-5 h-5 rounded-full bg-valdoria-navy text-white text-xs flex items-center justify-center font-semibold mt-0.5">
                    {i + 1}
                  </span>
                  {step}
                </li>
              ))}
            </ol>
          </div>
        </div>
      </div>
    </div>
  );
}
