import dotenv from 'dotenv';
dotenv.config();

import express from 'express';
import cors from 'cors';
import cookieParser from 'cookie-parser';
import { createClient } from '@supabase/supabase-js';
import { authenticate } from './middleware/authMiddleware.js';
import tripsRouter from './routes/trips.js';
import inviteRouter from "./routes/invite.js";
import tripMembersRouter from './routes/tripMembers.js';
const app = express()
app.use(cors({ origin: ['http://localhost:3000'], credentials: true }))
app.use(express.json())
app.use(cookieParser())

// --- Supabase setup ---
const SUPABASE_URL = process.env.SUPABASE_URL
const SUPABASE_ANON_KEY = process.env.SUPABASE_ANON_KEY

function supabaseForRequest(req) {
  const auth = req.headers.authorization || ''
  const token = auth.startsWith('Bearer ')
    ? auth.slice(7)
    : (req.cookies['sb-access-token'] || '')
  return createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
    global: { headers: token ? { Authorization: `Bearer ${token}` } : {} },
  })
}

// --- Middleware: attach Supabase + authenticate ---
function attachSupabase(req, _res, next) {
  req.supabase = supabaseForRequest(req)
  next()
}


// Attach Supabase for all routes
app.use(attachSupabase)
app.get('/', (_req, res) => 
  res.send('Trip API running. Try /api/health or /api/trips')
);

// --- Base routes ---
app.get('/api/health', (_req, res) => res.json({ ok: true }))

app.get('/api/profile', async (req, res) => {
  const { data: { user } } = await req.supabase.auth.getUser()
  if (!user) return res.status(401).json({ error: 'Unauthorized' })

  const { data, error } = await req.supabase
    .from('profiles')
    .select('id, full_name, email, avatar_url')
    .eq('id', user.id)
    .single()

  if (error) return res.status(400).json({ error: error.message })
  res.json(data)
})

app.patch('/api/profile', async (req, res) => {
  const { data: { user } } = await req.supabase.auth.getUser()
  if (!user) return res.status(401).json({ error: 'Unauthorized' })

  const { full_name, avatar_url } = req.body
  const { data, error } = await req.supabase
    .from('profiles')
    .update({ full_name, avatar_url })
    .eq('id', user.id)
    .select()
    .single()

  if (error) return res.status(400).json({ error: error.message })
  res.json(data)
})

// --- Mount Trip routes ---
app.use('/api/trips', authenticate, tripsRouter)
app.use("/api/invite", authenticate, inviteRouter);
app.use('/api/trips', authenticate, tripMembersRouter);

// --- Start server ---
const PORT = process.env.PORT || 4000
app.listen(PORT, () =>
  console.log(`✅ Server running on http://localhost:${PORT}`)
)
