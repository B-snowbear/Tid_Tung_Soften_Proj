import express from "express";
import crypto from "crypto";
const router = express.Router();
import { pushNotification } from "../func/notify";

// POST /api/invite/create   { trip_id }
router.post("/create", async (req, res) => {
  const { trip_id } = req.body;
  const { data: { user } } = await req.supabase.auth.getUser();
  if (!user) return res.status(401).json({ error: "Unauthorized" });

  const code = crypto.randomBytes(3).toString("hex").toUpperCase(); // e.g. "A1B2C3"

  const { error } = await req.supabase.from("trip_invites").insert({
    trip_id,
    code,
    created_by: user.id,
  });

  if (error) return res.status(400).json({ error: error.message });
  res.json({ code });
});

// POST /api/invite/join   { code }
router.post("/join", async (req, res) => {
  const { code } = req.body;
  const { data: { user } } = await req.supabase.auth.getUser();
  if (!user) return res.status(401).json({ error: "Unauthorized" });

  const { data: invite, error } = await req.supabase
    .from("trip_invites")
    .select("*")
    .eq("code", code)
    .single();

  if (error || !invite) return res.status(404).json({ error: "Invalid code" });

  await req.supabase.from("trip_members").insert({
    trip_id: invite.trip_id,
    user_id: user.id,
  });

  // notify the trip members
  const { data: tripData, error: tripError } = await req.supabase
    .from("trips")
    .select(`
    id,
    name,
    trip_members:user_id (
      user_id,
      member_id:id
    )
    `).eq("id", invite.trip_id)
    .single(); 

  if (tripError) {
    console.error("Error fetching trip members for notification:", membersError.message);
    return res.status(500).json({ error: "Failed to notify trip members" });
  }

  for (const member of tripData.trip_members) {
    if (member.user_id === user.id) continue; // don't notify the joiner

    await req.supabase.from("notifications").insert({
      user_id: member.user_id,
      message: `${user.email} joined ${tripData.name}`,
      type: "trip_join",
      trip_id: tripData.id,
      member_id: member.member_id,
      created_at: new Date()
    });
  }

  await req.supabase.from("trip_invites").update({ status: "accepted" }).eq("id", invite.id);

  res.json({ success: true, trip_id: invite.trip_id });
});

export default router;
