import express from "express";
const router = express.Router();

// GET all notifications for logged-in user - GET /api/notifications
router.get("/", async (req, res) => {
  try {
    const userId = req.user.id;

    const { data, error } = await req.supabase
      .from("notifications")
      .select("*")
      .eq("user_id", userId)
      .order("created_at", { ascending: false });

    if (error) throw error;

    res.json(data);
  } catch (err) {
    console.error("GET notifications error:", err.message);
    res.status(500).json({ error: "Failed to fetch notifications" });
  }
});

// Mark ONE notification as read - PATCH /api/notifications/read/:id
router.patch("/read/:id", async (req, res) => {
  try {
    const id = req.params.id;
    const userId = req.user.id;

    const { error } = await req.supabase
      .from("notifications")
      .update({ is_read: true })
      .eq("id", id)
      .eq("user_id", userId);

    if (error) throw error;

    res.json({ success: true });
  } catch (err) {
    console.error("PATCH read notification error:", err.message);
    res.status(500).json({ error: "Failed to mark notification as read" });
  }
});

// Mark ALL notifications as read - PATCH /api/notifications/read-all
router.patch("/read-all", async (req, res) => {
  try {
    const userId = req.user.id;

    const { error } = await req.supabase
      .from("notifications")
      .update({ is_read: true })
      .eq("user_id", userId)
      .eq("is_read", false);

    if (error) throw error;

    res.json({ success: true });
  } catch (err) {
    console.error("PATCH read-all error:", err.message);
    res.status(500).json({ error: "Failed to mark all notifications as read" });
  }
});

// DELETE notification by ID - DELETE /api/notifications/:id
router.delete("/:id", async (req, res) => {
  try {
    const id = req.params.id;
    const userId = req.user.id;

    const { error } = await req.supabase
      .from("notifications")
      .delete()
      .eq("id", id)
      .eq("user_id", userId);

    if (error) throw error;

    res.json({ success: true });
  } catch (err) {
    console.error("DELETE notification error:", err.message);
    res.status(500).json({ error: "Failed to delete notification" });
  }
});

// Clear ALL notifications - DELETE /api/notifications
router.delete("/", async (req, res) => {
  try {
    const userId = req.user.id;

    const { error } = await req.supabase
      .from("notifications")
      .delete()
      .eq("user_id", userId);

    if (error) throw error;

    res.json({ success: true });
  } catch (err) {
    console.error("DELETE all notifications error:", err.message);
    res.status(500).json({ error: "Failed to clear notifications" });
  }
});

export default router;
