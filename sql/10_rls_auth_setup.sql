-- ===== Love 网站 RLS 安全加固 =====
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

-- ========================================
-- 第二步：创建新的安全策略
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

-- 7. settings（设置）：所有人读（公开字段），登录用户写
CREATE POLICY "settings_select" ON settings FOR SELECT USING (true);
CREATE POLICY "settings_update" ON settings FOR UPDATE USING (auth.uid() IS NOT NULL);
CREATE POLICY "settings_insert" ON settings FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

-- 8. visited_places（足迹地图）：所有人读，登录用户写
CREATE POLICY "visited_places_select" ON visited_places FOR SELECT USING (true);
CREATE POLICY "visited_places_insert" ON visited_places FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);
CREATE POLICY "visited_places_delete" ON visited_places FOR DELETE USING (auth.uid() IS NOT NULL);
