require('dotenv').config()
const express = require('express')
const cors = require('cors')
const cookieParser = require('cookie-parser')
const { createClient } = require('@supabase/supabase-js')

const app = express()
app.use(cors({ origin: ['http://localhost:3000'], credentials: true }))
app.use(express.json())
app.use(cookieParser())

const SUPABASE_URL = process.env.SUPABASE_URL
const SUPABASE_ANON_KEY = process.env.SUPABASE_ANON_KEY

function supabaseForRequest(req) {
  const auth = req.headers.authorization || ''
  const token = auth.startsWith('Bearer ') ? auth.slice(7) : (req.cookies['sb-access-token'] || '')
  return createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
    global: { headers: token ? { Authorization: `Bearer ${token}` } : {} }
  })
}

app.get('/api/health', (_req, res) => res.json({ ok: true }))

app.get('/api/profile', async (req, res) => {
  const supabase = supabaseForRequest(req)
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) return res.status(401).json({ error: 'Unauthorized' })
  const { data, error } = await supabase
    .from('profiles')
    .select('id, full_name, email, avatar_url')
    .eq('id', user.id)
    .single()
  if (error) return res.status(400).json({ error: error.message })
  res.json(data)
})

app.patch('/api/profile', async (req, res) => {
  const supabase = supabaseForRequest(req)
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) return res.status(401).json({ error: 'Unauthorized' })
  const { full_name, avatar_url } = req.body
  const { data, error } = await supabase
    .from('profiles')
    .update({ full_name, avatar_url })
    .eq('id', user.id)
    .select()
    .single()
  if (error) return res.status(400).json({ error: error.message })
  res.json(data)
})

const PORT = process.env.PORT || 4000
app.listen(PORT, () => console.log(`✅ Server running on http://localhost:${PORT}`))
