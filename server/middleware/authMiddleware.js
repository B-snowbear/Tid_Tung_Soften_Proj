// server/middleware/authMiddleware.js
import { createClient } from '@supabase/supabase-js';
import dotenv from 'dotenv';
dotenv.config();

const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_ANON_KEY
);

export const authenticate = async (req, res, next) => {
  try {
    const auth = req.headers.authorization || '';
    const token = auth.startsWith('Bearer ') ? auth.slice(7) : null;

    if (!token) {
      return res.status(401).json({ error: 'Missing Bearer token' });
    }

    // 👇 Pass token explicitly
    const { data, error } = await supabase.auth.getUser(token);

    if (error || !data?.user) {
      console.error('Invalid token:', error?.message);
      return res.status(401).json({ error: 'Invalid or expired token' });
    }

    req.user = data.user;
    next();
  } catch (e) {
    console.error('Auth error:', e);
    res.status(500).json({ error: 'Auth middleware error' });
  }
};
