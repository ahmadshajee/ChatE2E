"use client";

// ============================================================
//  Auth Form Component
//  Handles both sign-in and sign-up with email/password.
//  Device registration happens automatically after first login.
// ============================================================

import { useState } from "react";
import { createClient } from "@/lib/supabase/client";
import { useRouter } from "next/navigation";

export default function AuthForm() {
  const [isSignUp, setIsSignUp] = useState(false);
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [displayName, setDisplayName] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);
  const [success, setSuccess] = useState<string | null>(null);

  const router = useRouter();
  const supabase = createClient();

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);
    setSuccess(null);
    setLoading(true);

    try {
      if (isSignUp) {
        // ── Sign Up ─────────────────────────────────────────
        const { error: signUpError } = await supabase.auth.signUp({
          email,
          password,
          options: {
            data: {
              name: displayName || "User",
            },
          },
        });

        if (signUpError) {
          setError(signUpError.message);
          return;
        }

        setSuccess(
          "Account created! Check your email for a confirmation link, or sign in if email confirmation is disabled."
        );
      } else {
        // ── Sign In ─────────────────────────────────────────
        const { error: signInError } = await supabase.auth.signInWithPassword({
          email,
          password,
        });

        if (signInError) {
          setError(signInError.message);
          return;
        }

        // Redirect to chat on successful sign-in
        router.push("/chat");
        router.refresh();
      }
    } catch (err) {
      setError(err instanceof Error ? err.message : "An unexpected error occurred");
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="auth-card">
      {/* Header */}
      <div className="auth-header">
        <div className="auth-logo">
          <svg
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            strokeWidth="1.5"
            strokeLinecap="round"
            strokeLinejoin="round"
            className="auth-logo-icon"
          >
            <path d="M12 22c5.523 0 10-4.477 10-10S17.523 2 12 2 2 6.477 2 12c0 1.82.487 3.53 1.338 5L2 22l5-1.338A9.96 9.96 0 0 0 12 22z" />
            <path d="M8 12h.01M12 12h.01M16 12h.01" />
          </svg>
        </div>
        <h1 className="auth-title">Chatizy</h1>
        <p className="auth-subtitle">End-to-End Encrypted Messaging</p>
      </div>

      {/* Form */}
      <form onSubmit={handleSubmit} className="auth-form">
        {isSignUp && (
          <div className="form-group">
            <label htmlFor="displayName" className="form-label">
              Display Name
            </label>
            <input
              id="displayName"
              type="text"
              value={displayName}
              onChange={(e) => setDisplayName(e.target.value)}
              placeholder="Your name"
              className="form-input"
              autoComplete="name"
            />
          </div>
        )}

        <div className="form-group">
          <label htmlFor="email" className="form-label">
            Email
          </label>
          <input
            id="email"
            type="email"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            placeholder="you@example.com"
            className="form-input"
            required
            autoComplete="email"
          />
        </div>

        <div className="form-group">
          <label htmlFor="password" className="form-label">
            Password
          </label>
          <input
            id="password"
            type="password"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            placeholder="••••••••"
            className="form-input"
            required
            minLength={6}
            autoComplete={isSignUp ? "new-password" : "current-password"}
          />
        </div>

        {error && (
          <div className="form-error" role="alert">
            <svg viewBox="0 0 20 20" fill="currentColor" className="form-error-icon">
              <path
                fillRule="evenodd"
                d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7-4a1 1 0 11-2 0 1 1 0 012 0zM9 9a1 1 0 000 2v3a1 1 0 001 1h1a1 1 0 100-2v-3a1 1 0 00-1-1H9z"
                clipRule="evenodd"
              />
            </svg>
            {error}
          </div>
        )}

        {success && (
          <div className="form-success" role="status">
            <svg viewBox="0 0 20 20" fill="currentColor" className="form-success-icon">
              <path
                fillRule="evenodd"
                d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z"
                clipRule="evenodd"
              />
            </svg>
            {success}
          </div>
        )}

        <button
          type="submit"
          disabled={loading}
          className="form-submit"
        >
          {loading ? (
            <span className="form-spinner" />
          ) : isSignUp ? (
            "Create Account"
          ) : (
            "Sign In"
          )}
        </button>
      </form>

      {/* Toggle */}
      <div className="auth-toggle">
        <span className="auth-toggle-text">
          {isSignUp ? "Already have an account?" : "Don't have an account?"}
        </span>
        <button
          type="button"
          onClick={() => {
            setIsSignUp(!isSignUp);
            setError(null);
            setSuccess(null);
          }}
          className="auth-toggle-btn"
        >
          {isSignUp ? "Sign In" : "Create Account"}
        </button>
      </div>

      {/* E2EE badge */}
      <div className="auth-badge">
        <svg viewBox="0 0 20 20" fill="currentColor" className="auth-badge-icon">
          <path
            fillRule="evenodd"
            d="M5 9V7a5 5 0 0110 0v2a2 2 0 012 2v5a2 2 0 01-2 2H5a2 2 0 01-2-2v-5a2 2 0 012-2zm8-2v2H7V7a3 3 0 016 0z"
            clipRule="evenodd"
          />
        </svg>
        <span>End-to-End Encrypted</span>
      </div>
    </div>
  );
}
