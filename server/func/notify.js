export async function pushNotification(supabase, userId, title, message) {
  return supabase
    .from("notifications")
    .insert({
      user_id: userId,
      title,
      message
    });
}   
