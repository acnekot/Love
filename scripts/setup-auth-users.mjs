/**
 * setup-auth-users.mjs
 * 
 * 运行方式：node setup-auth-users.mjs
 * 
 * 需要环境变量：
 * - SUPABASE_URL: 你的 Supabase 项目 URL
 * - SUPABASE_SERVICE_ROLE_KEY: Supabase service_role key（在 Dashboard → Settings → API）
 * - PASSWORD1: 第一个用户的密码（草莓）
 * - PASSWORD2: 第二个用户的密码（小眠）
 * 
 * ⚠️ 重要：deriveEmail 函数必须和 src/lib/supabase.ts 里的完全一致！
 * 如果修改了 salt 或 hash 算法，两边都要改。
 * 
 * 这个脚本会：
 * 1. 从密码推导出邮箱
 * 2. 创建两个 Supabase Auth 用户
 * 3. 在 user_metadata 里存 role（name1 / name2）
 */

const SUPABASE_URL = process.env.SUPABASE_URL;
const SERVICE_ROLE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY;
const PASSWORD1 = process.env.PASSWORD1;
const PASSWORD2 = process.env.PASSWORD2;

if (!SUPABASE_URL || !SERVICE_ROLE_KEY || !PASSWORD1 || !PASSWORD2) {
    console.error('Missing required environment variables:');
    console.error('  SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, PASSWORD1, PASSWORD2');
    process.exit(1);
}

async function deriveEmail(password) {
    const encoder = new TextEncoder();
    const data = encoder.encode(password + '-love-awacat-salt');
    const hashBuffer = await crypto.subtle.digest('SHA-256', data);
    const hashArray = Array.from(new Uint8Array(hashBuffer));
    const hashHex = hashArray.map(b => b.toString(16).padStart(2, '0')).join('');
    return `${hashHex.slice(0, 16)}@love.awacat.cc`;
}

async function createUser(email, password, role) {
    const response = await fetch(`${SUPABASE_URL}/auth/v1/admin/users`, {
        method: 'POST',
        headers: {
            'Authorization': `Bearer ${SERVICE_ROLE_KEY}`,
            'Content-Type': 'application/json',
            'apikey': SERVICE_ROLE_KEY,
        },
        body: JSON.stringify({
            email,
            password,
            user_metadata: { role },
            email_confirm: true, // Skip email verification
        }),
    });

    const data = await response.json();
    
    if (!response.ok) {
        if (data.msg?.includes('already been registered')) {
            console.log(`✓ User ${role} (${email}) already exists`);
            return null;
        }
        throw new Error(`Failed to create ${role}: ${JSON.stringify(data)}`);
    }

    console.log(`✓ Created user ${role}: ${email} (id: ${data.id})`);
    return data;
}

async function main() {
    console.log('Setting up Supabase Auth users...\n');

    const email1 = await deriveEmail(PASSWORD1);
    const email2 = await deriveEmail(PASSWORD2);

    console.log(`User 1 (name1/草莓):`);
    console.log(`  Email: ${email1}`);
    console.log(`  Password: ${'*'.repeat(PASSWORD1.length)}\n`);

    console.log(`User 2 (name2/小眠):`);
    console.log(`  Email: ${email2}`);
    console.log(`  Password: ${'*'.repeat(PASSWORD2.length)}\n`);

    try {
        await createUser(email1, PASSWORD1, 'name1');
        await createUser(email2, PASSWORD2, 'name2');
        console.log('\n✅ Setup complete!');
        console.log('\nUsers can now log in with their passwords on the website.');
    } catch (error) {
        console.error('\n❌ Error:', error.message);
        process.exit(1);
    }
}

main();
