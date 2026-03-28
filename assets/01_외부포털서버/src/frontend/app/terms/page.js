"use client";

import Link from "next/link";

export default function TermsPage() {
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
        <span className="text-gray-600 font-medium">Terms of Use</span>
      </nav>

      {/* Page header */}
      <div className="mb-8">
        <h1 className="text-3xl font-bold text-gray-900 mb-2">Terms of Use</h1>
        <p className="text-gray-500">
          Effective date: 1 January 2026 | Last updated: 15 March 2026
        </p>
      </div>

      {/* Content */}
      <div className="govt-card prose prose-gray max-w-none">
        <p className="text-gray-700 leading-relaxed mb-6">
          Welcome to the official web portal of the Ministry of Interior and Safety
          of the Republic of Valdoria. By accessing or using this website, you agree
          to comply with and be bound by the following terms and conditions. Please
          read them carefully before using any services provided through this portal.
        </p>

        {/* Section 1 */}
        <section className="mb-8">
          <h2 className="text-xl font-semibold text-valdoria-navy mb-3">
            1. Acceptance of Terms
          </h2>
          <p className="text-gray-700 leading-relaxed mb-3">
            By accessing this portal, you acknowledge that you have read, understood,
            and agree to be bound by these Terms of Use and all applicable laws and
            regulations of the Republic of Valdoria. If you do not agree with any
            part of these terms, you must discontinue use of this website immediately.
          </p>
          <p className="text-gray-700 leading-relaxed">
            The Ministry reserves the right to modify these terms at any time without
            prior notice. Your continued use of the portal following any changes
            constitutes acceptance of the revised terms. It is your responsibility to
            review these terms periodically for updates.
          </p>
        </section>

        {/* Section 2 */}
        <section className="mb-8">
          <h2 className="text-xl font-semibold text-valdoria-navy mb-3">
            2. User Conduct
          </h2>
          <p className="text-gray-700 leading-relaxed mb-3">
            Users of this portal agree to use the website only for lawful purposes
            and in a manner consistent with all applicable national and local laws of
            the Republic of Valdoria. You shall not:
          </p>
          <ul className="list-disc list-inside text-gray-700 space-y-2 ml-4">
            <li>
              Attempt to gain unauthorized access to any portion of the portal, its
              servers, or any connected systems or networks
            </li>
            <li>
              Transmit any material that is unlawful, threatening, abusive,
              defamatory, or otherwise objectionable
            </li>
            <li>
              Use the portal to impersonate any person or entity, or falsely state
              or otherwise misrepresent your affiliation with a person or entity
            </li>
            <li>
              Interfere with or disrupt the operation of the portal or servers or
              networks connected to the portal
            </li>
            <li>
              Collect or store personal data about other users without their
              explicit consent
            </li>
          </ul>
        </section>

        {/* Section 3 */}
        <section className="mb-8">
          <h2 className="text-xl font-semibold text-valdoria-navy mb-3">
            3. Intellectual Property
          </h2>
          <p className="text-gray-700 leading-relaxed mb-3">
            All content published on this portal, including but not limited to text,
            graphics, logos, images, data compilations, and software, is the property
            of the Ministry of Interior and Safety of the Republic of Valdoria or its
            content suppliers and is protected by Valdorian and international
            intellectual property laws.
          </p>
          <p className="text-gray-700 leading-relaxed">
            Users may download or print individual pages for personal,
            non-commercial use, provided that copyright and other proprietary notices
            are retained. Reproduction, distribution, or transmission of any content
            from this portal for commercial purposes without prior written permission
            from the Ministry is strictly prohibited.
          </p>
        </section>

        {/* Section 4 */}
        <section className="mb-8">
          <h2 className="text-xl font-semibold text-valdoria-navy mb-3">
            4. Limitation of Liability
          </h2>
          <p className="text-gray-700 leading-relaxed mb-3">
            The Ministry of Interior and Safety makes every effort to ensure that
            the information provided on this portal is accurate, complete, and
            up-to-date. However, the Ministry does not warrant or guarantee the
            accuracy, reliability, or completeness of any information on this
            website.
          </p>
          <p className="text-gray-700 leading-relaxed">
            To the fullest extent permitted by law, the Ministry shall not be liable
            for any direct, indirect, incidental, special, consequential, or punitive
            damages arising out of your access to, use of, or inability to use this
            portal, or any errors or omissions in its content. This limitation
            applies regardless of whether the damages are based on warranty,
            contract, tort, negligence, strict liability, or any other legal theory.
          </p>
        </section>

        {/* Section 5 */}
        <section className="mb-8">
          <h2 className="text-xl font-semibold text-valdoria-navy mb-3">
            5. Governing Law
          </h2>
          <p className="text-gray-700 leading-relaxed">
            These Terms of Use shall be governed by and construed in accordance with
            the laws of the Republic of Valdoria, without regard to its conflict of
            law provisions. Any disputes arising from or relating to the use of this
            portal shall be subject to the exclusive jurisdiction of the courts of
            the Republic of Valdoria, located in the capital city of Elaris.
          </p>
        </section>

        {/* Section 6 */}
        <section className="mb-8">
          <h2 className="text-xl font-semibold text-valdoria-navy mb-3">
            6. Modifications
          </h2>
          <p className="text-gray-700 leading-relaxed mb-3">
            The Ministry of Interior and Safety reserves the right to revise,
            amend, or update these Terms of Use at any time and for any reason.
            Changes will become effective immediately upon posting to this portal.
            The &ldquo;Last updated&rdquo; date at the top of this page will be
            revised to reflect the date of the most recent changes.
          </p>
          <p className="text-gray-700 leading-relaxed">
            We encourage users to periodically review this page for the latest
            information on our terms and conditions. Continued use of the portal
            after modifications have been posted constitutes your acceptance of the
            modified terms.
          </p>
        </section>

        {/* Contact */}
        <section className="border-t border-gray-200 pt-6">
          <h2 className="text-xl font-semibold text-valdoria-navy mb-3">
            Contact Information
          </h2>
          <p className="text-gray-700 leading-relaxed">
            If you have any questions regarding these Terms of Use, please contact
            the Ministry of Interior and Safety at{" "}
            <span className="font-medium text-valdoria-navy">contact@mois.gov.vd</span>{" "}
            or by mail at 47 Constitution Avenue, Elaris, Republic of Valdoria.
          </p>
        </section>
      </div>
    </div>
  );
}
