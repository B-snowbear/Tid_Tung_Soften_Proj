// server/controllers/tripController.js
import { supabase } from '../services/supabaseClient.js';

export const getTrips = async (req, res) => {
  try {
    const token = req.headers.authorization?.replace('Bearer ', '')

    // Verify Supabase auth token
    const { data: { user }, error } = await supabase.auth.getUser(token)

    if (error || !user) {
      return res.status(401).json({ error: 'Unauthorized' })
    }

    // ✅ If authorized, fetch trips for that user
    const { data: trips, error: tripsError } = await supabase
      .from('trips')
      .select('*')
      .eq('user_id', user.id)

    if (tripsError) {
      return res.status(400).json({ error: tripsError.message })
    }

    res.json(trips)
  } catch (err) {
    res.status(500).json({ error: err.message })
  }
}


export const createTrip = async (req, res) => {
  const { name, destination, start_date, end_date, description } = req.body
  const { data, error } = await supabase
    .from('trips')
    .insert([{ user_id: req.user.id, name, destination, start_date, end_date, description }])
    .select()
  if (error) return res.status(400).json({ error: error.message })
  res.status(201).json(data[0])
}

export const updateTrip = async (req, res) => {
  const { id } = req.params
  const { data, error } = await supabase
    .from('trips')
    .update(req.body)
    .eq('id', id)
    .eq('user_id', req.user.id)
    .select()
  if (error) return res.status(400).json({ error: error.message })
  res.json(data[0])
}

export const deleteTrip = async (req, res) => {
  const { id } = req.params
  const { error } = await supabase
    .from('trips')
    .delete()
    .eq('id', id)
    .eq('user_id', req.user.id)
  if (error) return res.status(400).json({ error: error.message })
  res.status(204).send()
}
