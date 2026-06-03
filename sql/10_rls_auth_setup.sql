-- ===== Love 网站 RLS 安全加固 v3 =====
-- 重要：必须先 DROP 旧的开放策略，否则 permissive policies 会 OR 合并，新策略不生效

-- ========================================
-- 第一步：删除所有旧的开放策略
-- ========================================

-- 00_schema_setup.sql 里的旧策略
DROP POLICY IF EXISTS "Public songs access" ON public.songs;
DROP POLICY IF EXISTS "Public photos access" ON public.photos;
DROP POLICY IF EXISTS "Public messages access" ON public.messages;
DROP POLICY IF EXISTS "Public blessings access" ON public.blessings;
DROP POLICY IF EXISTS "Public settings access" ON public.settings;

-- 03_visited_places_setup.sql 里的旧策略
DROP POLICY IF EXISTS "Public read access" ON public.visited_places;
DROP POLICY IF EXISTS "Public insert access" ON public.visited_places;
DROP POLICY IF EXISTS "Public delete access" ON public.visited_places;

-- 05_public_messages.sql 里的旧策略
DROP POLICY IF EXISTS "Allow public read access" ON public_messages;
DROP POLICY IF EXISTS "Allow public insert access" ON public_messages;
DROP POLICY IF EXISTS "Allow public delete access" ON public_messages;

-- 02_fix_songs_table.sql 可能有的旧策略
DROP POLICY IF EXISTS "songs_select" ON public.songs;
DROP POLICY IF EXISTS "songs_insert" ON public.songs;
DROP POLICY IF EXISTS "songs_delete" ON public.songs;

-- 之前版本创建的策略（如果已执行过）
DROP POLICY IF EXISTS "messages_select" ON messages;
DROP POLICY IF EXISTS "messages_insert" ON messages;
DROP POLICY IF EXISTS "messages_delete" ON messages;
DROP POLICY IF EXISTS "public_messages_select" ON public_messages;
DROP POLICY IF EXISTS "public_messages_insert" ON public_messages;
DROP POLICY IF EXISTS "public_messages_delete" ON public_messages;
DROP POLICY IF EXISTS "blessing_stats_select" ON blessing_stats;
DROP POLICY IF EXISTS "blessing_stats_update" ON blessing_stats;
DROP POLICY IF EXISTS "photos_select" ON photos;
DROP POLICY IF EXISTS "photos_insert" ON photos;
DROP POLICY IF EXISTS "photos_update" ON photos;
DROP POLICY IF EXISTS "photos_delete" ON photos;
DROP POLICY IF EXISTS "songs_select" ON songs;
DROP POLICY IF EXISTS "songs_insert" ON songs;
DROP POLICY IF EXISTS "songs_delete" ON songs;
DROP POLICY IF EXISTS "achievements_select" ON achievements;
DROP POLICY IF EXISTS "achievements_insert" ON achievements;
DROP POLICY IF EXISTS "achievements_delete" ON achievements;
DROP POLICY IF EXISTS "settings_select" ON settings;
DROP POLICY IF EXISTS "settings_update" ON settings;
DROP POLICY IF EXISTS "settings_insert" ON settings;
DROP POLICY IF EXISTS "visited_places_select" ON visited_places;
DROP POLICY IF EXISTS "visited_places_insert" ON visited_places;
DROP POLICY IF EXISTS "visited_places_delete" ON visited_places;
DROP POLICY IF EXISTS "admin_secrets_select" ON admin_secrets;
DROP POLICY IF EXISTS "admin_secrets_update" ON admin_secrets;
DROP POLICY IF EXISTS "admin_secrets_insert" ON admin_secrets;

-- ========================================
-- 第二步：创建敏感字段分离表 + 删除 settings 敏感列
-- ========================================

-- 把密码 hash 和 admin_password 移到单独的表
CREATE TABLE IF NOT EXISTS admin_secrets (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    settings_id uuid REFERENCES settings(id),
    password1_hash text DEFAULT '',
    password2_hash text DEFAULT '',
    admin_password text DEFAULT ''
);

-- 从现有 settings 表迁移数据（如果有的话）
INSERT INTO admin_secrets (settings_id, password1_hash, password2_hash, admin_password)
SELECT id, password1_hash, password2_hash, admin_password
FROM settings
WHERE NOT EXISTS (SELECT 1 FROM admin_secrets WHERE admin_secrets.settings_id = settings.id);

-- 从 settings 表删除敏感列
ALTER TABLE settings DROP COLUMN IF EXISTS password1_hash;
ALTER TABLE settings DROP COLUMN IF EXISTS password2_hash;
ALTER TABLE settings DROP COLUMN IF EXISTS admin_password;

-- ========================================
-- 第三步：创建 public_settings View（只暴露公开字段）
-- ========================================

-- View 会自动跟随 settings 表的列变化
-- 即使将来 settings 表加了新列，View 也不会暴露它们（除非手动添加）
CREATE OR REPLACE VIEW public_settings AS
SELECT id, name1, avatar1, name2, avatar2, start_date,
       show_countdown, show_blessing, show_message_board,
       show_photo_wall, show_music_player, show_map, show_milestones
FROM settings;

-- 授予所有人读取权限
GRANT SELECT ON public_settings TO anon, authenticated;

-- ========================================
-- 第四步：创建新的安全策略
-- ========================================

-- 1. messages（碎碎念留言板）：所有人读，登录用户写
CREATE POLICY "messages_select" ON messages FOR SELECT USING (true);
CREATE POLICY "messages_insert" ON messages FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);
CREATE POLICY "messages_delete" ON messages FOR DELETE USING (auth.uid() IS NOT NULL);

-- 2. public_messages（弹幕）：所有人读写（公开功能），删除需登录
CREATE POLICY "public_messages_select" ON public_messages FOR SELECT USING (true);
CREATE POLICY "public_messages_insert" ON public_messages FOR INSERT WITH CHECK (true);
CREATE POLICY "public_messages_delete" ON public_messages FOR DELETE USING (auth.uid() IS NOT NULL);

-- 3. blessing_stats（99+1 祝福）：所有人读写（公开功能）
CREATE POLICY "blessing_stats_select" ON blessing_stats FOR SELECT USING (true);
CREATE POLICY "blessing_stats_update" ON blessing_stats FOR UPDATE USING (true);

-- 4. photos（照片墙）：所有人读，登录用户写
CREATE POLICY "photos_select" ON photos FOR SELECT USING (true);
CREATE POLICY "photos_insert" ON photos FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);
CREATE POLICY "photos_update" ON photos FOR UPDATE USING (auth.uid() IS NOT NULL);
CREATE POLICY "photos_delete" ON photos FOR DELETE USING (auth.uid() IS NOT NULL);

-- 5. songs（音乐播放器）：所有人读，登录用户写
CREATE POLICY "songs_select" ON songs FOR SELECT USING (true);
CREATE POLICY "songs_insert" ON songs FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);
CREATE POLICY "songs_delete" ON songs FOR DELETE USING (auth.uid() IS NOT NULL);

-- 6. achievements（成就）：所有人读，登录用户写
CREATE POLICY "achievements_select" ON achievements FOR SELECT USING (true);
CREATE POLICY "achievements_insert" ON achievements FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);
CREATE POLICY "achievements_delete" ON achievements FOR DELETE USING (auth.uid() IS NOT NULL);

-- 7. settings（设置）：只有登录用户能读写（通过 public_settings View 对外暴露公开字段）
CREATE POLICY "settings_select" ON settings FOR SELECT USING (auth.uid() IS NOT NULL);
CREATE POLICY "settings_update" ON settings FOR UPDATE USING (auth.uid() IS NOT NULL);
CREATE POLICY "settings_insert" ON settings FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

-- 8. visited_places（足迹地图）：所有人读，登录用户写
CREATE POLICY "visited_places_select" ON visited_places FOR SELECT USING (true);
CREATE POLICY "visited_places_insert" ON visited_places FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);
CREATE POLICY "visited_places_delete" ON visited_places FOR DELETE USING (auth.uid() IS NOT NULL);

-- 9. admin_secrets（敏感字段）：只有登录用户能读写
CREATE POLICY "admin_secrets_select" ON admin_secrets FOR SELECT USING (auth.uid() IS NOT NULL);
CREATE POLICY "admin_secrets_update" ON admin_secrets FOR UPDATE USING (auth.uid() IS NOT NULL);
CREATE POLICY "admin_secrets_insert" ON admin_secrets FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

-- ========================================
-- 第五步：禁用 Supabase Auth 自助注册
-- ========================================
-- ⚠️ 这一步需要在 Supabase Dashboard 手动操作：
-- Authentication → Providers → Email → 关闭 "Allow new users to sign up"
-- 这样只有通过 setup-auth-users.mjs 创建的用户才能登录

-- ========================================
-- 第六步：创建 Auth 用户
-- ========================================
-- 运行：node scripts/setup-auth-users.mjs
-- 需要环境变量：SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, PASSWORD1, PASSWORD2
