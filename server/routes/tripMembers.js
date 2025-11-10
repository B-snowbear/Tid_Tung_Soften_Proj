import express from "express";
const router = express.Router();

router.get("/:id/members", async (req, res) => {
  const tripId = req.params.id;
  const { data: { user }, error: userErr } = await req.supabase.auth.getUser();
  if (userErr || !user) {
    return res.status(401).json({ error: "Unauthorized" });
  }

  // ✅ Return both owner and normal members
  const { data, error } = await req.supabase
    .from("trip_members")
    .select(`
      member_id,
      is_owner,
      profiles ( id, full_name, email, avatar_url )
    `)
    .eq("trip_id", tripId);

  if (error) return res.status(400).json({ error: error.message });
  res.json(data);
});

export default router;
