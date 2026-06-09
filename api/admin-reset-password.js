// ============================================================================
//  POST /api/admin-reset-password   ·   Vercel serverless function (Node 18+)
//
//  Sets a new password for any player. Used when a friend forgets theirs.
//
//  Security:
//    • Only the admin@themask.local account (is_admin=true in the profiles
//      table) is allowed to call this. We verify the caller's JWT first.
//    • The Supabase SERVICE_ROLE key NEVER reaches the browser — it lives
//      in Vercel env vars and only this function reads it.
//    • If env vars are missing the function refuses to run.
//
//  Required Vercel environment variables (Project → Settings → Env Vars):
//    SUPABASE_URL                 https://<project>.supabase.co
//    SUPABASE_ANON_KEY            eyJ… (the public anon key)
//    SUPABASE_SERVICE_ROLE_KEY    eyJ… (service_role — KEEP PRIVATE)
// ============================================================================

export default async function handler(req, res){
  if(req.method !== 'POST'){
    res.setHeader('Allow', 'POST');
    return res.status(405).json({error:'POST only'});
  }

  const url        = process.env.SUPABASE_URL;
  const anonKey    = process.env.SUPABASE_ANON_KEY;
  const serviceKey = process.env.SUPABASE_SERVICE_ROLE_KEY;
  if(!url || !anonKey || !serviceKey){
    return res.status(500).json({error:'Server misconfigured: missing SUPABASE_URL / SUPABASE_ANON_KEY / SUPABASE_SERVICE_ROLE_KEY in Vercel env vars'});
  }

  // ── 1. Identify the caller via their JWT ─────────────────────────────────
  const authHeader = req.headers.authorization || '';
  const token = authHeader.startsWith('Bearer ') ? authHeader.slice(7) : null;
  if(!token) return res.status(401).json({error:'No auth token — sign in as admin first'});

  let caller;
  try{
    const userRes = await fetch(`${url}/auth/v1/user`, {
      headers: { apikey: anonKey, Authorization: `Bearer ${token}` }
    });
    if(!userRes.ok) return res.status(401).json({error:'Invalid or expired auth token'});
    caller = await userRes.json();
  } catch(e){
    return res.status(500).json({error:'Could not verify caller: ' + e.message});
  }

  // ── 2. Verify the caller has is_admin=true in the profiles table ────────
  try{
    const profRes = await fetch(`${url}/rest/v1/profiles?id=eq.${encodeURIComponent(caller.id)}&select=is_admin`, {
      headers: { apikey: anonKey, Authorization: `Bearer ${token}` }
    });
    if(!profRes.ok) return res.status(500).json({error:'Could not load caller profile'});
    const rows = await profRes.json();
    if(!rows[0] || !rows[0].is_admin){
      return res.status(403).json({error:'Caller is not an admin'});
    }
  } catch(e){
    return res.status(500).json({error:'Profile check failed: ' + e.message});
  }

  // ── 3. Read and validate the payload ─────────────────────────────────────
  let body = req.body;
  if(typeof body === 'string'){ try{ body = JSON.parse(body); } catch(e){ body = {}; } }
  const targetUid   = body && body.targetUid;
  const newPassword = body && body.newPassword;
  if(!targetUid || !newPassword){
    return res.status(400).json({error:'Missing targetUid or newPassword'});
  }
  if(String(newPassword).length < 6){
    return res.status(400).json({error:'Password must be at least 6 characters'});
  }
  if(targetUid === caller.id){
    return res.status(400).json({error:"Don't reset your own admin password from here — use the profile screen"});
  }

  // ── 4. Block resets against the admin account itself ────────────────────
  try{
    const adminCheck = await fetch(`${url}/rest/v1/profiles?id=eq.${encodeURIComponent(targetUid)}&select=is_admin,email`, {
      headers: { apikey: anonKey, Authorization: `Bearer ${token}` }
    });
    if(adminCheck.ok){
      const r = await adminCheck.json();
      if(r[0] && r[0].is_admin){
        return res.status(403).json({error:"Can't reset another admin's password from here"});
      }
    }
  } catch(e){ /* non-fatal */ }

  // ── 5. Perform the privileged password update via the service-role key ──
  try{
    const updRes = await fetch(`${url}/auth/v1/admin/users/${encodeURIComponent(targetUid)}`, {
      method: 'PUT',
      headers: {
        apikey: serviceKey,
        Authorization: `Bearer ${serviceKey}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({ password: String(newPassword) })
    });
    if(!updRes.ok){
      const errText = await updRes.text();
      return res.status(500).json({error:`Supabase admin API: ${errText || updRes.statusText}`});
    }
  } catch(e){
    return res.status(500).json({error:'Update failed: ' + e.message});
  }

  return res.status(200).json({ok:true});
}
