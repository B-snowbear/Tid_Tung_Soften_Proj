import express from 'express';
import { createClient } from '@supabase/supabase-js';
import { randomInt, randomUUID } from 'crypto';
import dotenv from 'dotenv';
import { sendOtpMail } from '../utils/mailer.js';


dotenv.config();


dotenv.config(); // 👈 load .env in this file


const router = express.Router();

const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_ANON_KEY
);

// Helper: generate 6-digit OTP
function genOtp() {
  return String(randomInt(100000, 999999));
}

// ------------------------------
// POST /api/auth/login
// 1) Check email + password
// 2) Create OTP row in login_otps
// 3) Return tempToken
// ------------------------------
router.post('/login', async (req, res) => {
  const { email, password } = req.body;

  if (!email || !password) {
    return res.status(400).json({ message: 'Email and password are required' });
  }

  try {
    // 1) Verify credentials via Supabase
    const { data, error } = await supabase.auth.signInWithPassword({
      email,
      password,
    });

    if (error || !data?.user) {
      console.error('Supabase signIn error:', error?.message);
      return res.status(400).json({ message: 'Invalid email or password' });
    }

    const userId = data.user.id;

    // 2) Generate OTP + expiry + temp token
    const otp = genOtp();
    const expiresAt = new Date(Date.now() + 5 * 60 * 1000).toISOString(); // 5 minutes
    const tempToken = randomUUID();

    // Optional: clear previous unused OTPs for this user
    await supabase
      .from('login_otps')
      .delete()
      .eq('user_id', userId)
      .eq('used', false);

    const { error: insertError } = await supabase
      .from('login_otps')
      .insert({
        user_id: userId,
        otp_code: otp,
        expires_at: expiresAt,
        resend_count: 0,
        failed_attempts: 0,
        temp_token: tempToken,
        used: false,
      });

    if (insertError) {
      console.error('Error inserting OTP row:', insertError);
      return res.status(500).json({ message: 'Failed to create OTP' });
    }

    // 3) TODO: send OTP via email
    try {
      await sendOtpMail(email, otp);
      console.log(`📧 OTP sent to ${email}`);
    } catch (mailError) {
      console.error('❌ Failed to send OTP:', mailError);
      return res.status(500).json({ message: 'Failed to send OTP email' });
    }


    res.json({ tempToken });


    res.json({ tempToken });
  } catch (e) {
    console.error('Login OTP error:', e);
    res.status(500).json({ message: 'Server error' });
  }
});

// ------------------------------
// POST /api/auth/verify-otp
// Body: { tempToken, otp }
// ------------------------------
router.post('/verify-otp', async (req, res) => {
  const { tempToken, otp } = req.body;

  if (!tempToken || !otp) {
    return res.status(400).json({ message: 'tempToken and otp are required' });
  }

  try {
    // 1) Look up OTP row
    const { data: row, error } = await supabase
      .from('login_otps')
      .select('*')
      .eq('temp_token', tempToken)
      .maybeSingle();

    if (error) {
      console.error('Error fetching OTP row:', error);
      return res.status(500).json({ message: 'DB error' });
    }

    if (!row) {
      return res.status(400).json({ message: 'Invalid temp token' });
    }

    // Already used
    if (row.used) {
      return res.status(400).json({ message: 'OTP already used. Please log in again.' });
    }

    // Too many failed attempts
    if (row.failed_attempts >= 5) {
      return res
        .status(423)
        .json({ message: 'Account locked due to too many invalid OTP attempts.' });
    }

    // Expired
    const now = new Date();
    const expiry = new Date(row.expires_at);
    if (expiry < now) {
      return res.status(400).json({ message: 'OTP expired. Please log in again.' });
    }

    // 2) Compare OTP
    if (row.otp_code !== otp) {
      const newAttempts = row.failed_attempts + 1;

      const { error: updateError } = await supabase
        .from('login_otps')
        .update({ failed_attempts: newAttempts })
        .eq('id', row.id);

      if (updateError) {
        console.error('Failed to update failed_attempts:', updateError);
      }

      if (newAttempts >= 5) {
        return res
          .status(423)
          .json({ message: 'Account locked after 5 invalid OTP attempts.' });
      }

      return res
        .status(400)
        .json({ message: `Incorrect OTP. Attempts: ${newAttempts}/5` });
    }

    // 3) Mark OTP as used
    const { error: usedError } = await supabase
      .from('login_otps')
      .update({ used: true })
      .eq('id', row.id);

    if (usedError) {
      console.error('Failed to mark OTP used:', usedError);
      // We still consider it verified but warn in logs
    }

    // ✅ At this point, OTP is correct.
    // For now we just respond success. Supabase session is still the same
    // session that was created in /login, but the client (Flutter) does not
    // have that token. If you want, you can later change the flow so that
    // Flutter also signs in to Supabase after OTP.
    res.json({ success: true, user_id: row.user_id });
  } catch (e) {
    console.error('Verify OTP error:', e);
    res.status(500).json({ message: 'Server error' });
  }
});

// ------------------------------
// POST /api/auth/resend-otp
// Body: { tempToken }
// Max 3 resends
// ------------------------------
router.post('/resend-otp', async (req, res) => {
  const { tempToken } = req.body;

  if (!tempToken) {
    return res.status(400).json({ message: 'tempToken is required' });
  }

  try {
    const { data: row, error } = await supabase
      .from('login_otps')
      .select('*')
      .eq('temp_token', tempToken)
      .maybeSingle();

    if (error) {
      console.error('Error fetching OTP row for resend:', error);
      return res.status(500).json({ message: 'DB error' });
    }

    if (!row) {
      return res.status(400).json({ message: 'Invalid temp token' });
    }

    if (row.used) {
      return res.status(400).json({ message: 'OTP already used. Please log in again.' });
    }

    if (row.resend_count >= 3) {
      return res.status(429).json({ message: 'Max resend attempts reached.' });
    }

    // Generate a new OTP or reuse the same one. Here we generate a new one.
    const newOtp = genOtp();
    const newExpiry = new Date(Date.now() + 5 * 60 * 1000).toISOString();

    const { error: updateError } = await supabase
      .from('login_otps')
      .update({
        otp_code: newOtp,
        expires_at: newExpiry,
        resend_count: row.resend_count + 1,
      })
      .eq('id', row.id);

    if (updateError) {
      console.error('Failed to update OTP for resend:', updateError);
      return res.status(500).json({ message: 'Could not resend OTP' });
    }

    // TODO: send OTP via email
    console.log(`DEBUG RESEND OTP: tempToken=${tempToken}, otp=${newOtp}`);

    res.json({ success: true });
  } catch (e) {
    console.error('Resend OTP error:', e);
    res.status(500).json({ message: 'Server error' });
  }
});

export default router;
