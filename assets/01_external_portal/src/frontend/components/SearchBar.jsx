"use client";

import { useState } from "react";

export default function SearchBar({
  onSearch,
  placeholder = "Search...",
  variant = "default",
  initialValue = "",
}) {
  const [query, setQuery] = useState(initialValue);

  const handleSubmit = (e) => {
    e.preventDefault();
    onSearch(query);
  };

  if (variant === "header") {
    return (
      <form onSubmit={handleSubmit} className="relative">
        <input
          type="text"
          value={query}
          onChange={(e) => setQuery(e.target.value)}
          placeholder={placeholder}
          className="w-full pl-4 pr-10 py-2 rounded-md bg-white/10 border border-white/20
                     text-white placeholder:text-white/50 text-sm
                     focus:outline-none focus:bg-white/15 focus:border-valdoria-gold/50
                     transition-colors"
        />
        <button
          type="submit"
          className="absolute right-2 top-1/2 -translate-y-1/2 text-white/60 hover:text-valdoria-gold transition-colors"
          aria-label="Search"
        >
          <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
          </svg>
        </button>
      </form>
    );
  }

  return (
    <form onSubmit={handleSubmit} className="relative">
      <input
        type="text"
        value={query}
        onChange={(e) => setQuery(e.target.value)}
        placeholder={placeholder}
        className="govt-input pr-12"
      />
      <button
        type="submit"
        className="absolute right-1 top-1/2 -translate-y-1/2 p-2 rounded-md
                   text-valdoria-navy hover:bg-valdoria-navy hover:text-white
                   transition-colors duration-150"
        aria-label="Search"
      >
        <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
        </svg>
      </button>
    </form>
  );
}
