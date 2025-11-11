import express from 'express';
const router = express.Router();
export default router;

// ------------------------------------------------------------
// GET /api/trips → list trips that the current user is part of
// ------------------------------------------------------------
router.get('/', async (req, res) => {
  const userId = req.user.id;

  try {
    // 1️⃣ Trips owned by the user
    const { data: owned, error: err1 } = await req.supabase
      .from('trips')
      .select('*')
      .eq('user_id', userId);

    if (err1) throw err1;

    // 2️⃣ Trips joined by the user
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

    // 3️⃣ Merge owned + joined (remove duplicates)
    const allTrips = [
      ...owned,
      ...joined.filter(t => !owned.some(o => o.id === t.id)),
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
// POST /api/trips → create a new trip
// ------------------------------------------------------------
router.post('/', async (req, res) => {
  const { name, destination, start_date, end_date, description } = req.body;
  const userId = req.user.id;

  if (!name) return res.status(400).json({ error: 'Trip name is required' });

  try {
    // ✅ Create trip (no join_code)
    const payload = {
      user_id: userId,
      name,
      destination: destination ?? null,
      start_date,
      end_date,
      description: description ?? null,
    };

    const { data: trip, error } = await req.supabase
      .from('trips')
      .insert([payload])
      .select()
      .single();

    if (error) throw error;

    // ✅ Add creator as owner in trip_members
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
// POST /api/trips/join → join an existing trip by Trip ID
// ------------------------------------------------------------
router.post('/join', async (req, res) => {
  const { trip_id } = req.body;
  const userId = req.user.id;

  if (!trip_id) return res.status(400).json({ error: 'Missing trip ID' });

  try {
    // 1️⃣ Check if the trip exists
    const { data: trip, error: tripErr } = await req.supabase
      .from('trips')
      .select('id, name')
      .eq('id', trip_id)
      .single();

    if (tripErr || !trip) return res.status(404).json({ error: 'Trip not found' });

    // 2️⃣ Prevent duplicate joins
    const { data: existing } = await req.supabase
      .from('trip_members')
      .select('*')
      .eq('trip_id', trip_id)
      .eq('member_id', userId)
      .maybeSingle();

    if (existing)
      return res.json({ success: true, message: 'Already a member' });

    // 3️⃣ Add as MEMBER
    const { error: joinErr } = await req.supabase
      .from('trip_members')
      .insert([{ trip_id, member_id: userId, role: 'member' }]);

    if (joinErr) throw joinErr;

    res.json({
      success: true,
      message: `Joined trip ${trip.name}`,
      trip_id,
    });
  } catch (e) {
    console.error('Error joining trip:', e);
    res.status(400).json({ error: e.message });
  }
});

// ------------------------------------------------------------
// GET /api/trips/:id/members → list all members of this trip
// ------------------------------------------------------------
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
// PUT /api/trips/:id → update your own trip
// ------------------------------------------------------------
router.put('/:id', async (req, res) => {
  const { id } = req.params;
  const updates = req.body;

  try {
    const { data, error } = await req.supabase
      .from('trips')
      .update(updates)
      .eq('id', id)
      .eq('user_id', req.user.id)
      .select()
      .single();

    if (error) throw error;

    res.json(data);
  } catch (e) {
    console.error('Error updating trip:', e);
    res.status(400).json({ error: e.message });
  }
});

// ------------------------------------------------------------
// DELETE /api/trips/:id → delete only your own trip
// ------------------------------------------------------------
router.delete('/:id', async (req, res) => {
  const { id } = req.params;

  try {
    const { error } = await req.supabase
      .from('trips')
      .delete()
      .eq('id', id)
      .eq('user_id', req.user.id);

    if (error) throw error;

    res.status(204).send();
  } catch (e) {
    console.error('Error deleting trip:', e);
    res.status(400).json({ error: e.message });
  }
});
