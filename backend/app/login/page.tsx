'use client'
import { createSupabaseBrowser } from '@/lib/supabase/client'
export default function LoginPage() {
  const onGoogle = async () => {
    const supabase = createSupabaseBrowser()
    await supabase.auth.signInWithOAuth({
      provider: 'google',
      options: { redirectTo: `${location.origin}/auth/callback` },
    })
  }
  return (
    <main className="p-6 max-w-sm mx-auto space-y-4">
      <h1 className="text-2xl font-semibold">Sign in</h1>
      <button onClick={onGoogle} className="w-full rounded-xl border px-4 py-2">Continue with Google</button>
    </main>
  )
}
