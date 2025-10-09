import { createSupabaseServer } from '@/lib/supabase/server'
import ProfileForm from './ProfileForm'

// ---------- Server component ----------
async function getProfile() {
  const supabase = createSupabaseServer()
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) return { authed: false, profile: null }

  const { data } = await supabase
    .from('profiles')
    .select('full_name, email, avatar_url')
    .eq('id', user.id)
    .single()

  return { authed: true, profile: data }
}

export default async function ProfilePage() {
  const { authed, profile } = await getProfile()

  if (!authed)
    return (
      <main className="p-6 text-center">
        <a href="/login" className="text-amber-700 underline">
          Please sign in
        </a>
      </main>
    )

  return (
    <main className="p-6 max-w-lg mx-auto space-y-4">
      <h1 className="text-2xl font-semibold text-amber-700">Your Profile</h1>
      <ProfileForm initial={profile} />
    </main>
  )
}
