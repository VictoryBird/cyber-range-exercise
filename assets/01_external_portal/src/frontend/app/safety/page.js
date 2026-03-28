import Link from "next/link";

const EMERGENCY_CONTACTS = [
  { number: "112", label: "Police", desc: "Crime, public order emergencies" },
  { number: "119", label: "Fire / Ambulance", desc: "Fire, medical emergencies" },
  { number: "110", label: "Government Helpline", desc: "Public inquiries, non-emergency" },
  { number: "+42-2-3100-7911", label: "International Emergency", desc: "For callers outside Valdoria" },
];

const SAFETY_GUIDES = [
  {
    title: "Earthquake Preparedness",
    desc: "Drop, Cover, and Hold On when shaking begins. Stay away from windows and exterior walls. After shaking stops, evacuate carefully and check for gas leaks.",
    icon: (
      <path
        strokeLinecap="round"
        strokeLinejoin="round"
        strokeWidth={1.5}
        d="M3.055 11H5a2 2 0 012 2v1a2 2 0 002 2 2 2 0 012 2v2.945M8 3.935V5.5A2.5 2.5 0 0010.5 8h.5a2 2 0 012 2 2 2 0 104 0 2 2 0 012-2h1.064M15 20.488V18a2 2 0 012-2h3.064M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
      />
    ),
  },
  {
    title: "Typhoon & Flood Safety",
    desc: "Monitor official weather advisories. Know your nearest evacuation route and designated shelter. Avoid flooded roads and low-lying coastal areas during advisories.",
    icon: (
      <path
        strokeLinecap="round"
        strokeLinejoin="round"
        strokeWidth={1.5}
        d="M3 15a4 4 0 004 4h9a5 5 0 10-.1-9.999 5.002 5.002 0 10-9.78 2.096A4.001 4.001 0 003 15z"
      />
    ),
  },
  {
    title: "Fire Safety",
    desc: "Install and test smoke detectors regularly. Know two exit routes from every room. Never use elevators during a fire. Close doors to slow smoke spread.",
    icon: (
      <path
        strokeLinecap="round"
        strokeLinejoin="round"
        strokeWidth={1.5}
        d="M17.657 18.657A8 8 0 016.343 7.343S7 9 9 10c0-2 .5-5 2.986-7C14 5 16.09 5.777 17.656 7.343A7.975 7.975 0 0120 13a7.975 7.975 0 01-2.343 5.657z"
      />
    ),
  },
  {
    title: "Cybersecurity for Citizens",
    desc: "Use strong unique passwords and enable two-factor authentication. Verify sender identity before clicking links. Report phishing attempts to cert@valdoria.gov.",
    icon: (
      <path
        strokeLinecap="round"
        strokeLinejoin="round"
        strokeWidth={1.5}
        d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z"
      />
    ),
  },
  {
    title: "Chemical / Industrial Hazards",
    desc: "If a HAZMAT incident is declared, shelter in place with windows sealed or evacuate as directed. Do not approach incident sites. Await official all-clear before returning.",
    icon: (
      <path
        strokeLinecap="round"
        strokeLinejoin="round"
        strokeWidth={1.5}
        d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"
      />
    ),
  },
  {
    title: "First Aid Basics",
    desc: "For cardiac arrest: call 119, begin chest compressions at 100-120 per minute. Control bleeding with firm direct pressure. Keep accident victims still until emergency services arrive.",
    icon: (
      <path
        strokeLinecap="round"
        strokeLinejoin="round"
        strokeWidth={1.5}
        d="M4.318 6.318a4.5 4.5 0 000 6.364L12 20.364l7.682-7.682a4.5 4.5 0 00-6.364-6.364L12 7.636l-1.318-1.318a4.5 4.5 0 00-6.364 0z"
      />
    ),
  },
];

const SHELTERS = [
  {
    name: "Valdoria Central Gymnasium",
    district: "Central District",
    address: "45 Central Park Rd, Valdoria Capital 10001",
    capacity: "3,500",
  },
  {
    name: "Silicon Coast Convention Center",
    district: "Silicon Coast",
    address: "200 Harbor Innovation Blvd, Westport 30100",
    capacity: "8,000",
  },
  {
    name: "Northport Community Hall",
    district: "Northern Region",
    address: "12 Northgate Avenue, Northport 50200",
    capacity: "1,200",
  },
  {
    name: "Capital District Underground Station",
    district: "Central District",
    address: "Republic Metro Line 2, Level B3, Valdoria Capital 10050",
    capacity: "5,000",
  },
  {
    name: "Southern Coast Military Base",
    district: "Southern Coast",
    address: "Coastal Defense Road, Southern Shore District 80010",
    capacity: "2,800",
  },
];

const CHECKLIST = [
  "Sufficient drinking water (at least 3 liters per person per day for 72 hours)",
  "Non-perishable food supply for at least 3 days per household member",
  "First aid kit with basic medications, bandages, and antiseptic",
  "Copies of essential documents (ID, insurance, prescriptions) in a waterproof pouch",
  "Battery-powered or hand-crank radio for emergency broadcasts",
  "Flashlight and extra batteries",
  "Charged portable power bank for mobile devices",
  "Warm clothing, sturdy footwear, and a waterproof jacket",
  "Emergency contact list written on paper (not only stored on phone)",
  "Whistle and signal mirror for rescue signaling",
];

export default function SafetyPage() {
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
        <span className="text-gray-600 font-medium">Safety &amp; Emergency</span>
      </nav>

      <div className="mb-6">
        <h1 className="text-3xl font-bold text-gray-900 mb-2">Safety &amp; Emergency Information</h1>
        <p className="text-gray-500 max-w-2xl">
          Official safety guidance, emergency contacts, and preparedness resources from the Ministry of
          Interior and Safety.
        </p>
      </div>

      {/* Current Alert Banner */}
      <div className="flex items-start gap-3 bg-amber-50 border border-amber-300 rounded-lg p-4 mb-8">
        <div className="flex-shrink-0 mt-0.5">
          <svg className="w-5 h-5 text-amber-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
          </svg>
        </div>
        <div className="flex-1">
          <p className="text-sm font-semibold text-amber-800 mb-0.5">Active Advisory</p>
          <p className="text-sm text-amber-700">
            Typhoon Miran advisory in effect for Southern Coast Region — residents should monitor official
            broadcasts and prepare for possible evacuation.
          </p>
          <p className="text-xs text-amber-600 mt-1">Updated Mar 27, 2026 at 14:00 VCT</p>
        </div>
        <a href="#" className="flex-shrink-0 text-xs font-medium text-amber-800 underline underline-offset-2 hover:text-amber-900">
          Full Advisory
        </a>
      </div>

      {/* Emergency Contacts */}
      <section className="mb-8">
        <h2 className="text-xl font-semibold text-valdoria-navy mb-5">Emergency Contacts</h2>
        <div className="govt-card">
          <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
            {EMERGENCY_CONTACTS.map((contact) => (
              <div key={contact.number} className="text-center p-4 bg-gray-50 rounded-lg">
                <div className="text-3xl font-bold text-valdoria-navy mb-1 tracking-tight">
                  {contact.number}
                </div>
                <p className="text-sm font-semibold text-gray-800 mb-0.5">{contact.label}</p>
                <p className="text-xs text-gray-500">{contact.desc}</p>
              </div>
            ))}
          </div>
          <p className="text-xs text-gray-400 text-center mt-4">
            Emergency lines are available 24 hours a day, 365 days a year.
          </p>
        </div>
      </section>

      {/* Safety Guides */}
      <section className="mb-8">
        <h2 className="text-xl font-semibold text-valdoria-navy mb-5">Safety Guides</h2>
        <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
          {SAFETY_GUIDES.map((guide) => (
            <div key={guide.title} className="govt-card group">
              <div className="w-10 h-10 rounded-lg bg-valdoria-navy/5 flex items-center justify-center text-valdoria-navy group-hover:bg-valdoria-navy group-hover:text-white transition-colors mb-4">
                <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  {guide.icon}
                </svg>
              </div>
              <h3 className="font-semibold text-gray-900 group-hover:text-valdoria-navy transition-colors mb-2">
                {guide.title}
              </h3>
              <p className="text-sm text-gray-500 leading-relaxed">{guide.desc}</p>
              <button className="mt-3 text-xs text-valdoria-navy font-medium flex items-center gap-1 hover:gap-2 transition-all">
                Full guide
                <svg className="w-3 h-3" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5l7 7-7 7" />
                </svg>
              </button>
            </div>
          ))}
        </div>
      </section>

      {/* Evacuation Shelters */}
      <section className="mb-8">
        <h2 className="text-xl font-semibold text-valdoria-navy mb-2">Designated Evacuation Shelters</h2>
        <p className="text-sm text-gray-500 mb-5">
          The following facilities are designated as primary evacuation shelters during declared emergencies.
          Check local authority instructions for shelter activation status.
        </p>
        <div className="overflow-x-auto rounded-lg border border-gray-200">
          <table className="w-full text-sm">
            <thead>
              <tr className="bg-valdoria-navy text-white">
                <th className="text-left px-4 py-3 font-semibold">Facility</th>
                <th className="text-left px-4 py-3 font-semibold hidden sm:table-cell">District</th>
                <th className="text-left px-4 py-3 font-semibold hidden lg:table-cell">Address</th>
                <th className="text-right px-4 py-3 font-semibold">Capacity</th>
              </tr>
            </thead>
            <tbody>
              {SHELTERS.map((shelter, idx) => (
                <tr
                  key={shelter.name}
                  className={idx % 2 === 0 ? "bg-white" : "bg-gray-50"}
                >
                  <td className="px-4 py-3 font-medium text-gray-900">{shelter.name}</td>
                  <td className="px-4 py-3 text-gray-600 hidden sm:table-cell">{shelter.district}</td>
                  <td className="px-4 py-3 text-gray-500 hidden lg:table-cell text-xs">{shelter.address}</td>
                  <td className="px-4 py-3 text-right text-gray-700 font-medium">{shelter.capacity}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
        <p className="text-xs text-gray-400 mt-2">
          Capacity figures indicate maximum persons. Actual operational capacity may vary during multi-hazard events.
        </p>
      </section>

      {/* Emergency Preparedness Checklist */}
      <section>
        <h2 className="text-xl font-semibold text-valdoria-navy mb-2">Emergency Preparedness Checklist</h2>
        <p className="text-sm text-gray-500 mb-5">
          Every household should maintain a preparedness kit capable of sustaining all members for a minimum
          of 72 hours without external assistance. The following items are recommended by the National
          Emergency Management Office.
        </p>
        <div className="bg-valdoria-cream border border-valdoria-gold/30 rounded-lg p-6">
          <ul className="space-y-2.5">
            {CHECKLIST.map((item) => (
              <li key={item} className="flex items-start gap-3">
                <div className="flex-shrink-0 mt-0.5 w-5 h-5 rounded border-2 border-valdoria-navy/30 flex items-center justify-center">
                  <svg className="w-3 h-3 text-valdoria-navy/50" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2.5} d="M5 13l4 4L19 7" />
                  </svg>
                </div>
                <span className="text-sm text-gray-700 leading-relaxed">{item}</span>
              </li>
            ))}
          </ul>
          <div className="mt-5 pt-4 border-t border-valdoria-gold/20">
            <button className="govt-btn-primary inline-flex items-center gap-2 text-sm">
              <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 10v6m0 0l-3-3m3 3l3-3m2 8H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
              </svg>
              Download Printable Checklist (PDF)
            </button>
          </div>
        </div>
      </section>
    </div>
  );
}
