"use client";

import Link from "next/link";

export default function PrivacyPage() {
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
        <span className="text-gray-600 font-medium">Privacy Policy</span>
      </nav>

      {/* Page header */}
      <div className="mb-8">
        <h1 className="text-3xl font-bold text-gray-900 mb-2">Privacy Policy</h1>
        <p className="text-gray-500">
          Effective date: 1 January 2026 | Last updated: 15 March 2026
        </p>
      </div>

      {/* Content */}
      <div className="govt-card prose prose-gray max-w-none">
        <p className="text-gray-700 leading-relaxed mb-6">
          The Ministry of Interior and Safety of the Republic of Valdoria is
          committed to protecting the privacy and personal data of all users who
          access this portal. This Privacy Policy explains how we collect, use,
          store, and protect your information in accordance with the Valdoria Data
          Protection Act (VDPA) of 2021.
        </p>

        {/* Section 1 */}
        <section className="mb-8">
          <h2 className="text-xl font-semibold text-valdoria-navy mb-3">
            1. Information We Collect
          </h2>
          <p className="text-gray-700 leading-relaxed mb-3">
            We may collect the following categories of information when you use
            this portal:
          </p>
          <ul className="list-disc list-inside text-gray-700 space-y-2 ml-4">
            <li>
              <span className="font-medium">Personal identification information:</span>{" "}
              name, national identification number, email address, and phone
              number, when you submit inquiries or register for services
            </li>
            <li>
              <span className="font-medium">Technical data:</span> IP address,
              browser type and version, operating system, referring URLs, and
              access timestamps collected automatically through server logs
            </li>
            <li>
              <span className="font-medium">Usage data:</span> pages visited,
              search queries, navigation patterns, and time spent on the portal
            </li>
            <li>
              <span className="font-medium">Inquiry data:</span> the content of
              your submitted inquiries, complaints, or feedback, including any
              attachments
            </li>
          </ul>
        </section>

        {/* Section 2 */}
        <section className="mb-8">
          <h2 className="text-xl font-semibold text-valdoria-navy mb-3">
            2. How We Use Information
          </h2>
          <p className="text-gray-700 leading-relaxed mb-3">
            The information we collect is used for the following purposes:
          </p>
          <ul className="list-disc list-inside text-gray-700 space-y-2 ml-4">
            <li>To provide, operate, and maintain the portal and its services</li>
            <li>To process and respond to citizen inquiries and service requests</li>
            <li>To improve the functionality, content, and user experience of the portal</li>
            <li>To compile statistical data and analytics for public administration purposes</li>
            <li>To ensure the security and integrity of the portal and detect unauthorized access</li>
            <li>To comply with legal obligations under the laws of the Republic of Valdoria</li>
          </ul>
        </section>

        {/* Section 3 */}
        <section className="mb-8">
          <h2 className="text-xl font-semibold text-valdoria-navy mb-3">
            3. Data Retention
          </h2>
          <p className="text-gray-700 leading-relaxed mb-3">
            Personal data collected through this portal is retained only for as
            long as necessary to fulfill the purposes for which it was collected,
            unless a longer retention period is required or permitted by law.
          </p>
          <p className="text-gray-700 leading-relaxed">
            Inquiry records are retained for a period of five (5) years from the
            date of resolution, in accordance with the Valdoria Public Records
            Retention Schedule. Server logs and technical data are retained for a
            maximum of twelve (12) months. Upon expiration of the retention period,
            data is securely deleted or anonymized.
          </p>
        </section>

        {/* Section 4 */}
        <section className="mb-8">
          <h2 className="text-xl font-semibold text-valdoria-navy mb-3">
            4. Cookies
          </h2>
          <p className="text-gray-700 leading-relaxed mb-3">
            This portal uses cookies and similar technologies to enhance your
            browsing experience. The types of cookies used include:
          </p>
          <ul className="list-disc list-inside text-gray-700 space-y-2 ml-4">
            <li>
              <span className="font-medium">Essential cookies:</span> required for
              the basic operation of the portal, including session management and
              authentication
            </li>
            <li>
              <span className="font-medium">Analytics cookies:</span> used to
              collect anonymous usage statistics to help improve the portal
            </li>
            <li>
              <span className="font-medium">Preference cookies:</span> used to
              remember your language and display preferences
            </li>
          </ul>
          <p className="text-gray-700 leading-relaxed mt-3">
            You may configure your browser to refuse cookies; however, doing so
            may limit your ability to use certain features of the portal.
          </p>
        </section>

        {/* Section 5 */}
        <section className="mb-8">
          <h2 className="text-xl font-semibold text-valdoria-navy mb-3">
            5. Third-Party Services
          </h2>
          <p className="text-gray-700 leading-relaxed">
            This portal does not sell, trade, or transfer your personal information
            to third parties. We may share data with other government agencies of
            the Republic of Valdoria when necessary for the provision of public
            services or as required by law. Any such sharing is conducted in
            compliance with the Valdoria Data Protection Act and applicable
            inter-agency data sharing agreements.
          </p>
        </section>

        {/* Section 6 */}
        <section className="mb-8">
          <h2 className="text-xl font-semibold text-valdoria-navy mb-3">
            6. Your Rights
          </h2>
          <p className="text-gray-700 leading-relaxed mb-3">
            Under the Valdoria Data Protection Act, you have the following rights
            regarding your personal data:
          </p>
          <ul className="list-disc list-inside text-gray-700 space-y-2 ml-4">
            <li>
              <span className="font-medium">Right of access:</span> you may
              request a copy of the personal data we hold about you
            </li>
            <li>
              <span className="font-medium">Right to rectification:</span> you may
              request correction of inaccurate or incomplete personal data
            </li>
            <li>
              <span className="font-medium">Right to erasure:</span> you may
              request deletion of your personal data, subject to legal retention
              requirements
            </li>
            <li>
              <span className="font-medium">Right to restriction:</span> you may
              request that we limit the processing of your data in certain
              circumstances
            </li>
            <li>
              <span className="font-medium">Right to object:</span> you may
              object to the processing of your personal data for specific purposes
            </li>
          </ul>
          <p className="text-gray-700 leading-relaxed mt-3">
            To exercise any of these rights, please submit a written request to the
            Data Protection Officer at the address provided below.
          </p>
        </section>

        {/* Section 7 */}
        <section className="border-t border-gray-200 pt-6">
          <h2 className="text-xl font-semibold text-valdoria-navy mb-3">
            7. Contact
          </h2>
          <p className="text-gray-700 leading-relaxed mb-3">
            If you have any questions about this Privacy Policy or wish to exercise
            your data protection rights, please contact:
          </p>
          <div className="bg-valdoria-cream rounded-lg p-4 text-sm text-gray-700">
            <p className="font-semibold text-valdoria-navy mb-1">
              Data Protection Officer
            </p>
            <p>Ministry of Interior and Safety</p>
            <p>47 Constitution Avenue, Elaris</p>
            <p>Republic of Valdoria</p>
            <p className="mt-2">
              Email:{" "}
              <span className="font-medium text-valdoria-navy">
                privacy@mois.gov.vd
              </span>
            </p>
            <p>
              Phone:{" "}
              <span className="font-medium text-valdoria-navy">
                +42 (0)2 3100-7050
              </span>
            </p>
          </div>
        </section>
      </div>
    </div>
  );
}
