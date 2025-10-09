'use client'

import Link from 'next/link'

export default function HomePage() {
  return (
    <main className="min-h-screen flex flex-col justify-center items-center bg-gradient-to-b from-amber-50 to-yellow-100 text-gray-800 p-6">
      {/* Header */}
      <header className="w-full max-w-3xl flex justify-between items-center mb-16">
        <h1 className="text-3xl font-bold text-amber-700">💰 TidTung</h1>
        <Link
          href="/login"
          className="rounded-xl bg-amber-600 text-white px-4 py-2 font-medium hover:bg-amber-700 transition"
        >
          Sign In
        </Link>
      </header>

      {/* Main content */}
      <section className="max-w-2xl text-center space-y-6">
        <h2 className="text-4xl md:text-5xl font-bold">
          Simplify Shared Expenses with <span className="text-amber-700">TidTung</span>
        </h2>

        <p className="text-lg md:text-xl text-gray-600">
          TidTung helps friends, families, and coworkers track expenses, balances, and
          settlements easily — reducing confusion and stress.
        </p>

        <div className="flex justify-center gap-4 mt-8">
          <Link
            href="/login"
            className="bg-amber-600 text-white px-6 py-3 rounded-xl font-medium shadow hover:bg-amber-700 transition"
          >
            Get Started
          </Link>
          <a
            href="#features"
            className="border border-amber-600 text-amber-700 px-6 py-3 rounded-xl font-medium hover:bg-amber-100 transition"
          >
            Learn More
          </a>
        </div>
      </section>

      {/* Features Section */}
      <section id="features" className="max-w-4xl mt-24 space-y-12">
        <h3 className="text-3xl font-semibold text-center text-amber-700">
          💡 Key Features
        </h3>

        <div className="grid md:grid-cols-3 gap-8 text-center">
          <div className="p-6 rounded-2xl bg-white shadow-md hover:shadow-lg transition">
            <h4 className="font-semibold text-xl mb-2">Expense Tracking</h4>
            <p className="text-gray-600 text-sm">
              Log shared expenses quickly and view total balances for each group.
            </p>
          </div>
          <div className="p-6 rounded-2xl bg-white shadow-md hover:shadow-lg transition">
            <h4 className="font-semibold text-xl mb-2">Automatic Settlement</h4>
            <p className="text-gray-600 text-sm">
              Automatically calculate who owes whom and how much — no more math!
            </p>
          </div>
          <div className="p-6 rounded-2xl bg-white shadow-md hover:shadow-lg transition">
            <h4 className="font-semibold text-xl mb-2">Group Collaboration</h4>
            <p className="text-gray-600 text-sm">
              Create shared groups for trips, roommates, or events to manage spending together.
            </p>
          </div>
        </div>
      </section>

      {/* Footer */}
      <footer className="mt-24 text-center text-sm text-gray-500">
        <p>© 2025 TidTung Team — Built with ❤️ using Next.js, Supabase, and Flutter.</p>
      </footer>
    </main>
  )
}
