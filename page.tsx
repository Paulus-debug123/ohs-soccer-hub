'use client'
import {useEffect,useState} from 'react'
import Link from 'next/link'
import {supabase} from '../lib/supabase'

export default function Home(){
 const [teams,setTeams]=useState<any[]>([]),[table,setTable]=useState<any[]>([]),[news,setNews]=useState<any[]>([]),[loading,setLoading]=useState(true)
 useEffect(()=>{(async()=>{const [a,b,c]=await Promise.all([
  supabase.from('teams').select('*').limit(8),
  supabase.from('league_table').select('*').order('points',{ascending:false}).order('goal_difference',{ascending:false}),
  supabase.from('news').select('*').order('published_at',{ascending:false}).limit(4)
 ]);setTeams(a.data||[]);setTable(b.data||[]);setNews(c.data||[]);setLoading(false)})()},[])
 return <><header className="top"><div className="brand">⚽ OHS SOCCER HUB<small>OFFICIAL LEAGUE CENTRE</small></div><Link href="/login"><button className="btn">Admin / Player Login</button></Link></header>
 <div className="layout"><aside>{['Home','Teams','Fixtures','Results','Table','Ikororo OHS Cup','Community Shield','News','Awards','History'].map(x=><div className="nav" key={x}>{x}</div>)}</aside>
 <main className="main"><section className="hero"><div className="eyebrow">2026/27 SEASON</div><h1>OHS Soccer Hub</h1><p>Live league centre for fixtures, results, players, transfers and trophies.</p></section>
 <div className="cards"><div className="card"><span className="muted">Teams</span><strong>{teams.length}</strong></div><div className="card"><span className="muted">Players</span><strong>—</strong></div><div className="card"><span className="muted">Live news</span><strong>{news.length}</strong></div><div className="card"><span className="muted">Status</span><strong>ONLINE</strong></div></div>
 <div className="grid"><div className="panel"><h2>League Table</h2>{loading?<p>Loading...</p>:<table className="table"><thead><tr><th>#</th><th>TEAM</th><th>P</th><th>GD</th><th>PTS</th></tr></thead><tbody>{table.map((t,i)=><tr key={t.team_id}><td>{i+1}</td><td><b>{t.name}</b></td><td>{t.played}</td><td>{t.goal_difference}</td><td><b>{t.points}</b></td></tr>)}</tbody></table>}</div>
 <div className="panel"><h2>Latest News</h2>{news.map(n=><div className="match" key={n.id}><div><b>{n.title}</b><div className="muted">{n.category}</div></div></div>)}</div></div>
 <h2>Teams</h2><div className="teams">{teams.map(t=><div className="card team" style={{borderTopColor:t.primary_color}} key={t.id}><h3>{t.name}</h3><p className="muted">{t.short_name||'Club'} · Squad centre</p></div>)}</div>
 </main></div></>
}
