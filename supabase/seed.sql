-- Optional starter data after schema.sql
insert into public.teams(name,short_name,primary_color,season_id)
select v.name,v.short_name,v.color,s.id
from (values
('OHS Lions','LIO','#16a765'),('Ikororo FC','IKO','#e34b4b'),
('Young Stars','YST','#3b72c4'),('United Academy','UAC','#e59b22'),
('ELCIN XI','ELC','#8d56c9'),('OHS Eagles','EAG','#16a0aa'),
('City Boys','CTB','#5d6870'),('OHS Warriors','WAR','#c94387')
) v(name,short_name,color), public.seasons s where s.name='2026/27'
and not exists(select 1 from public.teams t where t.name=v.name);
