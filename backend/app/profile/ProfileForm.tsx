'use client'

import { useState } from 'react'

export default function ProfileForm({ initial }: { initial: any }) {
  const [fullName, setFullName] = useState(initial?.full_name ?? '')
  const [avatarUrl, setAvatarUrl] = useState(initial?.avatar_url ?? '')
  const [saving, setSaving] = useState(false)
  const [msg, setMsg] = useState<string | null>(null)

  const onSave = async () => {
    setSaving(true)
    setMsg(null)

    const res = await fetch('/api/profile', {
      method: 'PATCH',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ full_name: fullName, avatar_url: avatarUrl }),
    })

    const json = await res.json()
    setSaving(false)
    setMsg(res.ok ? '✅ Saved!' : `❌ ${json.error ?? 'Failed'}`)
  }

  return (
    <div className="space-y-3">
      <div>
        <label className="block text-sm font-medium text-gray-700">
          Full name
        </label>
        <input
          className="w-full rounded-xl border px-3 py-2 mt-1"
          value={fullName}
          onChange={(e) => setFullName(e.target.value)}
        />
      </div>

      <div>
        <label className="block text-sm font-medium text-gray-700">
          Avatar URL
        </label>
        <input
          className="w-full rounded-xl border px-3 py-2 mt-1"
          value={avatarUrl}
          onChange={(e) => setAvatarUrl(e.target.value)}
        />
      </div>

      <button
        onClick={onSave}
        disabled={saving}
        className="rounded-xl border px-4 py-2 bg-amber-600 text-white hover:bg-amber-700 transition"
      >
        {saving ? 'Saving…' : 'Save'}
      </button>

      {msg && <p className="text-sm mt-2 text-gray-600">{msg}</p>}
    </div>
  )
}
