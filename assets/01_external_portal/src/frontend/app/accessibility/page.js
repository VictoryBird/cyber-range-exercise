"use client";

import Link from "next/link";

export default function AccessibilityPage() {
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
        <span className="text-gray-600 font-medium">Accessibility</span>
      </nav>

      {/* Page header */}
      <div className="mb-8">
        <h1 className="text-3xl font-bold text-gray-900 mb-2">
          Accessibility Statement
        </h1>
        <p className="text-gray-500">
          Our commitment to making government services accessible to everyone.
        </p>
      </div>

      {/* Content */}
      <div className="govt-card prose prose-gray max-w-none">
        {/* Commitment */}
        <section className="mb-8">
          <h2 className="text-xl font-semibold text-valdoria-navy mb-3">
            Our Commitment
          </h2>
          <p className="text-gray-700 leading-relaxed mb-3">
            The Ministry of Interior and Safety of the Republic of Valdoria is
            committed to ensuring that this portal is accessible to all citizens,
            including persons with disabilities. We believe that every individual
            has the right to access government information and services, regardless
            of their abilities or the assistive technologies they use.
          </p>
          <p className="text-gray-700 leading-relaxed">
            We continuously work to improve the accessibility and usability of this
            portal, and we welcome feedback from our users to help us achieve this
            goal.
          </p>
        </section>

        {/* Standards */}
        <section className="mb-8">
          <h2 className="text-xl font-semibold text-valdoria-navy mb-3">
            Accessibility Standards
          </h2>
          <p className="text-gray-700 leading-relaxed mb-3">
            This portal strives to conform to the{" "}
            <span className="font-medium">
              Web Content Accessibility Guidelines (WCAG) 2.1, Level AA
            </span>
            , as published by the World Wide Web Consortium (W3C). These guidelines
            provide a framework for making web content more accessible to people
            with a wide range of disabilities, including visual, auditory,
            physical, speech, cognitive, language, learning, and neurological
            disabilities.
          </p>
          <p className="text-gray-700 leading-relaxed">
            Our compliance efforts are guided by the Valdoria Digital Accessibility
            Act of 2023, which mandates that all government digital services meet
            or exceed WCAG 2.1 Level AA standards.
          </p>
        </section>

        {/* Features */}
        <section className="mb-8">
          <h2 className="text-xl font-semibold text-valdoria-navy mb-3">
            Accessibility Features
          </h2>
          <p className="text-gray-700 leading-relaxed mb-3">
            The following features have been implemented to support accessibility:
          </p>
          <div className="grid gap-4 sm:grid-cols-2 mt-4">
            {[
              {
                title: "Keyboard Navigation",
                desc: "All interactive elements are accessible via keyboard. Tab order follows a logical reading sequence.",
              },
              {
                title: "Screen Reader Support",
                desc: "Semantic HTML, ARIA labels, and descriptive alt text are used throughout the portal.",
              },
              {
                title: "Text Resizing",
                desc: "Content can be resized up to 200% without loss of functionality or information.",
              },
              {
                title: "Color Contrast",
                desc: "Text and interactive elements meet WCAG 2.1 Level AA minimum contrast ratios.",
              },
              {
                title: "Focus Indicators",
                desc: "Visible focus indicators are provided for all interactive elements during keyboard navigation.",
              },
              {
                title: "Descriptive Links",
                desc: "Link text clearly describes the destination or purpose of each link.",
              },
            ].map((feature) => (
              <div
                key={feature.title}
                className="bg-valdoria-cream rounded-lg p-4"
              >
                <h3 className="text-sm font-semibold text-valdoria-navy mb-1">
                  {feature.title}
                </h3>
                <p className="text-sm text-gray-600">{feature.desc}</p>
              </div>
            ))}
          </div>
        </section>

        {/* Known limitations */}
        <section className="mb-8">
          <h2 className="text-xl font-semibold text-valdoria-navy mb-3">
            Known Limitations
          </h2>
          <p className="text-gray-700 leading-relaxed mb-3">
            While we strive for full compliance, some areas of the portal may have
            accessibility limitations:
          </p>
          <ul className="list-disc list-inside text-gray-700 space-y-2 ml-4">
            <li>
              Some older PDF documents may not be fully accessible. We are working
              to remediate these documents on an ongoing basis.
            </li>
            <li>
              Third-party content embedded on the portal may not meet all
              accessibility standards.
            </li>
          </ul>
        </section>

        {/* Feedback and contact */}
        <section className="border-t border-gray-200 pt-6">
          <h2 className="text-xl font-semibold text-valdoria-navy mb-3">
            Accessibility Feedback
          </h2>
          <p className="text-gray-700 leading-relaxed mb-4">
            We welcome your feedback on the accessibility of this portal. If you
            encounter any barriers or have suggestions for improvement, please
            contact us:
          </p>
          <div className="bg-valdoria-cream rounded-lg p-4 text-sm text-gray-700">
            <p className="font-semibold text-valdoria-navy mb-1">
              Digital Accessibility Team
            </p>
            <p>Ministry of Interior and Safety</p>
            <p>47 Constitution Avenue, Elaris</p>
            <p>Republic of Valdoria</p>
            <p className="mt-2">
              Email:{" "}
              <span className="font-medium text-valdoria-navy">
                accessibility@mois.gov.vd
              </span>
            </p>
            <p>
              Phone:{" "}
              <span className="font-medium text-valdoria-navy">
                +42 (0)2 3100-7060
              </span>
            </p>
          </div>
          <p className="text-gray-700 leading-relaxed mt-4">
            We aim to respond to all accessibility feedback within five (5)
            business days. If you are unable to access any content or service on
            this portal, we will provide the information to you in an alternative
            format upon request.
          </p>
        </section>
      </div>
    </div>
  );
}
