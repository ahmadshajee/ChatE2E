// ============================================================
//  Auth Page
// ============================================================

import AuthForm from "@/components/auth/auth-form";

export const metadata = {
  title: "Sign In — Chatizy",
  description: "Sign in or create an account to start chatting securely.",
};

export default function AuthPage() {
  return (
    <main className="auth-page">
      <AuthForm />
    </main>
  );
}
