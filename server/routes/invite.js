import express from "express";
import crypto from "crypto";
const router = express.Router();

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

  await req.supabase.from("trip_invites").update({ status: "accepted" }).eq("id", invite.id);

  res.json({ success: true, trip_id: invite.trip_id });
});

export default router;
