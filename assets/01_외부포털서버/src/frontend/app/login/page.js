"use client";

/**
 * [취약점] VULN-01-04: Hidden admin login page
 * This page is NOT linked from the navigation or any public page.
 * It exists as a security-through-obscurity measure that attackers
 * can discover via source code analysis or directory brute-forcing.
 *
 * 올바른 구현:
 * - Admin panel should be on a separate internal domain
 * - Protected by VPN/IP allowlist
 * - Not accessible from the public internet
 */

import { useState } from "react";
import Link from "next/link";

export default function LoginPage() {
  const [username, setUsername] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState(null);
  const [loading, setLoading] = useState(false);

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);
    setError(null);

    // Simulated login — nonfunctional for the exercise
    setTimeout(() => {
      setError("Authentication service is currently unavailable.");
      setLoading(false);
    }, 1500);
  };

  return (
    <div className="min-h-[70vh] flex items-center justify-center px-4 py-12">
      <div className="w-full max-w-sm">
        {/* Header */}
        <div className="text-center mb-8">
          <div className="w-14 h-14 rounded-full border-2 border-valdoria-gold/50 flex items-center justify-center bg-valdoria-navy mx-auto mb-4">
            <span className="text-valdoria-gold text-xl font-bold">V</span>
          </div>
          <h1 className="text-xl font-bold text-gray-900">
            Portal Administration
          </h1>
          <p className="text-sm text-gray-500 mt-1">
            Authorized personnel only
          </p>
        </div>

        {/* Login form */}
        <div className="bg-white border border-gray-200 rounded-lg shadow-sm p-6">
          <form onSubmit={handleSubmit} className="space-y-4">
            <div>
              <label
                htmlFor="username"
                className="block text-sm font-medium text-gray-700 mb-1"
              >
                Username
              </label>
              <input
                id="username"
                type="text"
                value={username}
                onChange={(e) => setUsername(e.target.value)}
                className="govt-input"
                placeholder="Enter your username"
                autoComplete="username"
                required
              />
            </div>
            <div>
              <label
                htmlFor="password"
                className="block text-sm font-medium text-gray-700 mb-1"
              >
                Password
              </label>
              <input
                id="password"
                type="password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                className="govt-input"
                placeholder="Enter your password"
                autoComplete="current-password"
                required
              />
            </div>

            {error && (
              <div className="rounded-md bg-red-50 border border-red-200 p-3 text-sm text-red-700">
                {error}
              </div>
            )}

            <button
              type="submit"
              disabled={loading}
              className="govt-btn-primary w-full disabled:opacity-50"
            >
              {loading ? (
                <svg className="w-5 h-5 animate-spin" fill="none" viewBox="0 0 24 24">
                  <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
                  <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z" />
                </svg>
              ) : (
                "Sign In"
              )}
            </button>
          </form>
        </div>

        {/* Back link */}
        <div className="text-center mt-4">
          <Link
            href="/"
            className="text-sm text-gray-500 hover:text-valdoria-navy transition-colors"
          >
            Return to Portal
          </Link>
        </div>
      </div>
    </div>
  );
}
