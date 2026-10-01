// common.js - shared helpers used by every page.
// It connects to our database (Supabase) and shows friendly messages.

// Fixed choices used on all pages
const LOCATIONS = [
  "Pit A - North Bench",
  "Pit B - Haul Road",
  "Coal Handling Plant",
  "Workshop",
  "Weighbridge",
  "Colony / Township",
  "Office Area",
  "Other"
];
const CATEGORIES = ["Safety", "Equipment", "Electrical", "Environment", "Road / Haulage", "Water / Housing", "Other"];
const URGENCIES = ["Low", "Medium", "High"];
const STATUSES = ["Open", "In progress", "Resolved"];
const TABLE = "issues";

// Show a message box. type = "ok", "err" or "info". detail = actual error text.
function showMsg(boxId, type, text, detail) {
  const box = document.getElementById(boxId);
  if (!box) return;
  box.className = "msg show " + type;
  box.textContent = text;
  if (detail) {
    const code = document.createElement("code");
    code.textContent = "Error details: " + detail;
    box.appendChild(code);
  }
}
function hideMsg(boxId) {
  const box = document.getElementById(boxId);
  if (box) box.className = "msg";
}

// Turn any error into readable text
function errText(e) {
  if (!e) return "Unknown error";
  if (typeof e === "string") return e;
  return [e.message, e.details, e.hint, e.code].filter(Boolean).join(" | ") || String(e);
}

// Connect to the database. If something is missing, db stays null
// and dbProblem explains why.
let db = null;
let dbProblem = "";
try {
  if (!window.supabase) {
    dbProblem = "The Supabase library did not load. Check the internet connection.";
  } else if (typeof window.SUPABASE_URL === "undefined" && typeof window.SUPABASE_PUBLISHABLE_KEY === "undefined") {
    dbProblem = "config.js did not load or has a typing mistake (for example missing quote marks). " +
                "Open config.js and check both lines look like: window.SUPABASE_URL = \"https://....supabase.co\";";
  } else if (!window.SUPABASE_URL || String(window.SUPABASE_URL).indexOf("PASTE_") === 0 ||
             !window.SUPABASE_PUBLISHABLE_KEY || String(window.SUPABASE_PUBLISHABLE_KEY).indexOf("PASTE_") === 0) {
    dbProblem = "The database settings are not filled in yet. Put the Project URL and publishable key in config.js. " +
                "(The website is reading: URL = " + window.SUPABASE_URL + ")";
  } else {
    db = window.supabase.createClient(window.SUPABASE_URL,
                                      window.SUPABASE_PUBLISHABLE_KEY);
  }
} catch (e) {
  dbProblem = "Could not connect to the database. " + errText(e);
}

// Make text safe to put inside the page
function esc(s) {
  return String(s == null ? "" : s)
    .replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;").replace(/'/g, "&#39;");
}

// Show a date like "3 Oct 2026, 2:15 pm"
function niceDate(iso) {
  if (!iso) return "";
  const d = new Date(iso);
  return d.toLocaleString("en-IN", { day: "numeric", month: "short", year: "numeric", hour: "numeric", minute: "2-digit" });
}

// Fill a <select> with options
function fillSelect(id, items, firstLabel) {
  const sel = document.getElementById(id);
  if (!sel) return;
  let html = firstLabel ? '<option value="">' + esc(firstLabel) + "</option>" : "";
  items.forEach(function (v) { html += '<option value="' + esc(v) + '">' + esc(v) + "</option>"; });
  sel.innerHTML = html;
}

// Load all records, newest first
async function loadIssues() {
  if (!db) throw new Error(dbProblem);
  const { data, error } = await db.from(TABLE).select("*").order("created_at", { ascending: false });
  if (error) throw error;
  return data || [];
}

// CSS class for a status badge ("In progress" -> "In-progress")
function cls(s) { return String(s || "").replace(/\s+/g, "-"); }
