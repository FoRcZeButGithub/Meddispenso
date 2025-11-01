import { createClient } from "https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2/+esm";
import { renderAuthForm } from './auth.js';
import { renderHomePage } from './home.js';

const supabaseUrl = 'https://gzdxnkejgebiwraxoakl.supabase.co';
const supabaseAnon = 'eyJhbGciOiJIestimatorsI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imd6ZHhua2VqZ2ViaXdyYXhvYWtsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTY3ODUxMjAsImV4cCI6MjA3MjM2MTEyMH0.cuoZf12ACP6MDAWEpl8eC6PvHmPG5vbn8abZGX7iavQ';
export const sb = createClient(supabaseUrl, supabaseAnon);

const appContainer = document.getElementById('app');

// --- AUTH LOGIC ---
sb.auth.onAuthStateChange((event, session) => {
    if (session) {
        renderHomePage(appContainer, sb);
    } else {
        renderAuthForm(appContainer, sb);
    }
});