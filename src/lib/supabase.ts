import { createClient } from '@supabase/supabase-js';

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL!;
const supabaseKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!;

export const supabase = createClient(supabaseUrl, supabaseKey);

// Derive a deterministic email from password
// This way the user only needs to enter their password,
// and we can always derive the same Supabase Auth email from it.
const deriveEmail = async (password: string): Promise<string> => {
    const encoder = new TextEncoder();
    const data = encoder.encode(password + '-love-awacat-salt');
    const hashBuffer = await crypto.subtle.digest('SHA-256', data);
    const hashArray = Array.from(new Uint8Array(hashBuffer));
    const hashHex = hashArray.map(b => b.toString(16).padStart(2, '0')).join('');
    return `${hashHex.slice(0, 16)}@love.awacat.cc`;
};

export const signIn = async (password: string) => {
    const email = await deriveEmail(password);
    const { data, error } = await supabase.auth.signInWithPassword({
        email,
        password,
    });
    return { data, error };
};

export const signOut = async () => {
    const { error } = await supabase.auth.signOut();
    return { error };
};

export const getSession = async () => {
    const { data: { session } } = await supabase.auth.getSession();
    return session;
};

// Helper to create Auth users (run once during setup)
// Call this from browser console to create the two users
export const createAuthUser = async (password: string, name: string) => {
    const email = await deriveEmail(password);
    console.log(`Creating user for ${name}: email=${email}, password=${password}`);
    // This needs to be done from Supabase Dashboard or with service_role key
    return { email, password };
};
