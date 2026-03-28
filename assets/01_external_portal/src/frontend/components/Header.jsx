"use client";

import { useState } from "react";
import Link from "next/link";
import { useRouter, usePathname } from "next/navigation";
import SearchBar from "./SearchBar";

const TRANSLATIONS = {
  en: {
    banner: "An official website of the Republic of Valdoria",
    republic: "Republic of Valdoria",
    ministry: "Ministry of Interior and Safety",
    searchPlaceholder: "Search portal...",
    nav: [
      { href: "/", label: "Home" },
      { href: "/notices", label: "Notices" },
      { href: "/inquiry", label: "Inquiry Status" },
      { href: "/search", label: "Search" },
    ],
  },
  ko: {
    banner: "발도리아 공화국 공식 웹사이트",
    republic: "발도리아 공화국",
    ministry: "행정안전부",
    searchPlaceholder: "포털 검색...",
    nav: [
      { href: "/", label: "홈" },
      { href: "/notices", label: "공지사항" },
      { href: "/inquiry", label: "민원조회" },
      { href: "/search", label: "검색" },
    ],
  },
};

export default function Header() {
  const router = useRouter();
  const pathname = usePathname();
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);
  const [lang, setLang] = useState("en");

  const t = TRANSLATIONS[lang];

  const handleSearch = (query) => {
    if (query.trim()) {
      router.push(`/search?q=${encodeURIComponent(query.trim())}`);
    }
  };

  return (
    <header className="w-full">
      {/* Top banner */}
      <div className="bg-valdoria-navy-dark text-white">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex items-center justify-between h-8 text-xs tracking-wide">
            <span className="opacity-80">
              {t.banner}
            </span>
            <div className="hidden sm:flex items-center gap-4 opacity-80">
              <button
                onClick={() => setLang(lang === "en" ? "ko" : "en")}
                className="hover:text-valdoria-gold transition-colors cursor-pointer"
              >
                {lang === "en" ? "한국어" : "English"}
              </button>
              <span className="text-valdoria-gold/60">|</span>
              <Link href="/accessibility" className="hover:text-valdoria-gold transition-colors">
                Accessibility
              </Link>
            </div>
          </div>
        </div>
      </div>

      {/* Main header */}
      <div className="bg-valdoria-navy">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex items-center justify-between h-20">
            {/* Government emblem and title */}
            <Link href="/" className="flex items-center gap-4 group">
              {/* Text-based government seal */}
              <div className="govt-seal flex-shrink-0 w-12 h-12 rounded-full border-2 border-valdoria-gold flex items-center justify-center bg-valdoria-navy-dark">
                <div className="text-center leading-none">
                  <div className="text-valdoria-gold text-lg font-bold">V</div>
                </div>
              </div>
              <div className="text-white">
                <div className="text-sm font-medium tracking-widest uppercase text-valdoria-gold-light opacity-90">
                  {t.republic}
                </div>
                <div className="text-lg font-semibold tracking-wide group-hover:text-valdoria-gold-light transition-colors">
                  {t.ministry}
                </div>
              </div>
            </Link>

            {/* Desktop search */}
            <div className="hidden lg:block w-72">
              <SearchBar
                onSearch={handleSearch}
                placeholder={t.searchPlaceholder}
                variant="header"
              />
            </div>

            {/* Mobile menu toggle */}
            <button
              onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
              className="lg:hidden text-white p-2 rounded-md hover:bg-valdoria-navy-light transition-colors"
              aria-label="Toggle menu"
            >
              <svg className="w-6 h-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                {mobileMenuOpen ? (
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                ) : (
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 6h16M4 12h16M4 18h16" />
                )}
              </svg>
            </button>
          </div>
        </div>
      </div>

      {/* Navigation bar */}
      <nav className="bg-valdoria-navy-light border-b-2 border-valdoria-gold/40">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="hidden lg:flex items-center h-11 gap-1">
            {t.nav.map((item) => {
              const isActive =
                item.href === "/"
                  ? pathname === "/"
                  : pathname.startsWith(item.href);
              return (
                <Link
                  key={item.href}
                  href={item.href}
                  className={`px-4 py-2 text-sm font-medium rounded-t-md transition-colors duration-150 ${
                    isActive
                      ? "bg-white text-valdoria-navy"
                      : "text-white/90 hover:bg-white/10 hover:text-white"
                  }`}
                >
                  {item.label}
                </Link>
              );
            })}
          </div>
        </div>
      </nav>

      {/* Mobile menu */}
      {mobileMenuOpen && (
        <div className="lg:hidden bg-valdoria-navy border-t border-valdoria-navy-light">
          <div className="px-4 py-3 space-y-1">
            {t.nav.map((item) => {
              const isActive =
                item.href === "/"
                  ? pathname === "/"
                  : pathname.startsWith(item.href);
              return (
                <Link
                  key={item.href}
                  href={item.href}
                  onClick={() => setMobileMenuOpen(false)}
                  className={`block px-3 py-2 rounded-md text-sm font-medium transition-colors ${
                    isActive
                      ? "bg-valdoria-navy-light text-valdoria-gold"
                      : "text-white/80 hover:bg-valdoria-navy-light hover:text-white"
                  }`}
                >
                  {item.label}
                </Link>
              );
            })}
            <div className="pt-2">
              <SearchBar
                onSearch={(q) => {
                  handleSearch(q);
                  setMobileMenuOpen(false);
                }}
                placeholder={t.searchPlaceholder}
                variant="header"
              />
            </div>
          </div>
        </div>
      )}
    </header>
  );
}
