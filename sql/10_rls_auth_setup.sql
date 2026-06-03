-- ===== Love 网站 RLS 安全加固 =====
-- 使用方法：在 Supabase SQL Editor 里执行此脚本

-- 1. 开启所有表的 RLS
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE blessing_stats ENABLE ROW LEVEL SECURITY;
ALTER TABLE photos ENABLE ROW LEVEL SECURITY;
ALTER TABLE songs ENABLE ROW LEVEL SECURITY;
ALTER TABLE achievements ENABLE ROW LEVEL SECURITY;
ALTER TABLE settings ENABLE ROW LEVEL SECURITY;

-- 2. messages（碎碎念留言板）：所有人读，登录用户写
CREATE POLICY "messages_select" ON messages FOR SELECT USING (true);
CREATE POLICY "messages_insert" ON messages FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);
CREATE POLICY "messages_delete" ON messages FOR DELETE USING (auth.uid() IS NOT NULL);

-- 3. public_messages（弹幕）：所有人读写（公开功能）
CREATE POLICY "public_messages_select" ON public_messages FOR SELECT USING (true);
CREATE POLICY "public_messages_insert" ON public_messages FOR INSERT WITH CHECK (true);
CREATE POLICY "public_messages_delete" ON public_messages FOR DELETE USING (auth.uid() IS NOT NULL);

-- 4. blessing_stats（99+1 祝福）：所有人读写（公开功能）
CREATE POLICY "blessing_stats_select" ON blessing_stats FOR SELECT USING (true);
CREATE POLICY "blessing_stats_update" ON blessing_stats FOR UPDATE USING (true);

-- 5. photos（照片墙）：所有人读，登录用户写
CREATE POLICY "photos_select" ON photos FOR SELECT USING (true);
CREATE POLICY "photos_insert" ON photos FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);
CREATE POLICY "photos_update" ON photos FOR UPDATE USING (auth.uid() IS NOT NULL);
CREATE POLICY "photos_delete" ON photos FOR DELETE USING (auth.uid() IS NOT NULL);

-- 6. songs（音乐播放器）：所有人读，登录用户写
CREATE POLICY "songs_select" ON songs FOR SELECT USING (true);
CREATE POLICY "songs_insert" ON songs FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);
CREATE POLICY "songs_delete" ON songs FOR DELETE USING (auth.uid() IS NOT NULL);

-- 7. achievements（成就）：所有人读，登录用户写
CREATE POLICY "achievements_select" ON achievements FOR SELECT USING (true);
CREATE POLICY "achievements_insert" ON achievements FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);
CREATE POLICY "achievements_delete" ON achievements FOR DELETE USING (auth.uid() IS NOT NULL);

-- 8. settings（设置）：所有人读，登录用户写
CREATE POLICY "settings_select" ON settings FOR SELECT USING (true);
CREATE POLICY "settings_update" ON settings FOR UPDATE USING (auth.uid() IS NOT NULL);
CREATE POLICY "settings_insert" ON settings FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);
