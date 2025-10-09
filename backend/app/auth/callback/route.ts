import { NextResponse } from 'next/server'
import { createSupabaseServer } from '@/lib/supabase/server'
export async function GET(req: Request) {
  const url = new URL(req.url)
  const code = url.searchParams.get('code')
  const next = url.searchParams.get('next') ?? '/profile'
  if (!code) return NextResponse.redirect(new URL('/login?error=missing_code', req.url))
  const supabase = createSupabaseServer()
  const { error } = await supabase.auth.exchangeCodeForSession(code)
  if (error) return NextResponse.redirect(new URL(`/login?error=${encodeURIComponent(error.message)}`, req.url))
  return NextResponse.redirect(new URL(next, req.url))
}
