import express from 'express';
import crypto from 'crypto';
const router = express.Router();
export default router;

// ------------------------------------------------------------
// GET /api/trips  → list trips that the current user is part of
// ------------------------------------------------------------
router.get('/', async (req, res) => {
  const userId = req.user.id;

  try {
    // 1️⃣ Trips owned by user
    const { data: owned, error: err1 } = await req.supabase
      .from('trips')
      .select('*')
      .eq('user_id', userId);

    if (err1) throw err1;

    // 2️⃣ Trips joined by user
    const { data: memberRows, error: err2 } = await req.supabase
      .from('trip_members')
      .select('trip_id')
      .eq('member_id', userId);

    if (err2) throw err2;

    const memberTripIds = memberRows.map(r => r.trip_id);

    let joined = [];
    if (memberTripIds.length > 0) {
      const { data: joinedTrips, error: err3 } = await req.supabase
        .from('trips')
        .select('*')
        .in('id', memberTripIds);

      if (err3) throw err3;
      joined = joinedTrips;
    }

    // 3️⃣ Merge owned + joined (no duplicates)
    const allTrips = [
      ...owned,
      ...joined.filter(t => !owned.some(o => o.id === t.id))
    ];

    // 4️⃣ Sort newest first
    allTrips.sort((a, b) => new Date(b.created_at) - new Date(a.created_at));

    res.json(allTrips);
  } catch (e) {
    console.error('Error fetching trips:', e);
    res.status(400).json({ error: e.message });
  }
});

// ------------------------------------------------------------
// POST /api/trips  → create a new trip (auto generates join code)
// ------------------------------------------------------------
router.post('/', async (req, res) => {
  const { name, destination, start_date, end_date, description } = req.body;
  const userId = req.user.id;

  if (!name) return res.status(400).json({ error: 'Trip name is required' });

  try {
    const join_code = crypto.randomBytes(3).toString('hex').toUpperCase(); // e.g. A1B2C3

    // Create trip
    const payload = {
      user_id: userId,
      name,
      destination: destination ?? null,
      start_date,
      end_date,
      description: description ?? null,
      join_code,
    };

    const { data: trip, error } = await req.supabase
      .from('trips')
      .insert([payload])
      .select()
      .single();

    if (error) throw error;

    // ✅ Add creator as OWNER in trip_members
    const { error: memberErr } = await req.supabase
      .from('trip_members')
      .insert([{ trip_id: trip.id, member_id: userId, role: 'owner' }]);

    if (memberErr) throw memberErr;

    res.status(201).json(trip);
  } catch (e) {
    console.error('Error creating trip:', e);
    res.status(400).json({ error: e.message });
  }
});

// ------------------------------------------------------------
// POST /api/trips/join  → join an existing trip by code
// ------------------------------------------------------------
router.post('/join', async (req, res) => {
  const { code } = req.body;
  const userId = req.user.id;

  if (!code) return res.status(400).json({ error: 'Missing join code' });

  const { data: trip, error } = await req.supabase
    .from('trips')
    .select('id')
    .eq('join_code', code)
    .single();

  if (error || !trip) return res.status(404).json({ error: 'Invalid code' });

  // Prevent duplicate joins
  const { data: existing } = await req.supabase
    .from('trip_members')
    .select('*')
    .eq('trip_id', trip.id)
    .eq('member_id', userId)
    .maybeSingle();

  if (existing) return res.json({ success: true, message: 'Already a member' });

  // ✅ Fetch profile info
  const { data: profile } = await req.supabase
    .from('profiles')
    .select('full_name, email')
    .eq('id', userId)
    .maybeSingle();

  // ✅ Add as MEMBER
  const { error: joinErr } = await req.supabase
    .from('trip_members')
    .insert({ trip_id: trip.id, member_id: userId, role: 'member' });

  if (joinErr) return res.status(400).json({ error: joinErr.message });

  // ✅ Ensure full_name is saved (if empty)
  if (!profile?.full_name) {
    const { user } = req.user;
    await req.supabase
      .from('profiles')
      .update({ full_name: user?.user_metadata?.full_name ?? 'Unnamed User' })
      .eq('id', userId);
  }

  res.json({ success: true, trip_id: trip.id });
});


// ------------------------------------------------------------
// GET /api/trips/:tripId/members  → show all members of a trip
// ------------------------------------------------------------
// ------------------------------------------------------------
// GET /api/trips/:id/members  → list all members of this trip
// ------------------------------------------------------------
// GET /api/trips/:id/members
router.get('/:id/members', async (req, res) => {
  const { id } = req.params;

  try {
    const { data, error } = await req.supabase
      .from('trip_members')
      .select(`
        role,
        member_id,
        profiles (
          id,
          full_name,
          email,
          avatar_url
        )
      `)
      .eq('trip_id', id);

    if (error) throw error;
    res.json(data);
  } catch (e) {
    console.error('Error fetching members:', e);
    res.status(400).json({ error: e.message });
  }
});




// ------------------------------------------------------------
// PUT /api/trips/:id  → update your own trip
// ------------------------------------------------------------
router.put('/:id', async (req, res) => {
  const { id } = req.params;
  const updates = req.body;

  const { data, error } = await req.supabase
    .from('trips')
    .update(updates)
    .eq('id', id)
    .eq('user_id', req.user.id)
    .select()
    .single();

  if (error) return res.status(400).json({ error: error.message });
  res.json(data);
});

// ------------------------------------------------------------
// DELETE /api/trips/:id  → delete only your own trip
// ------------------------------------------------------------
router.delete('/:id', async (req, res) => {
  const { id } = req.params;

  const { error } = await req.supabase
    .from('trips')
    .delete()
    .eq('id', id)
    .eq('user_id', req.user.id);

  if (error) return res.status(400).json({ error: error.message });
  res.status(204).send();
});
