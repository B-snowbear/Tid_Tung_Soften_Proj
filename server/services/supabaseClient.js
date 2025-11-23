// server/services/supabaseClient.js
import { createClient } from '@supabase/supabase-js';
import dotenv from 'dotenv';
dotenv.config();

export const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_ANON_KEY
);

export const supabaseAdmin = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY, 
  {
    auth: {
      autoRefreshToken: false, // Admin client doesn't need to refresh tokens
      persistSession: false    // Admin client doesn't need to save session to storage
    }
  }
);


