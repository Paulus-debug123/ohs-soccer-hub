'use client'
import {useState} from 'react'
import {useRouter} from 'next/navigation'
import {supabase} from '../../lib/supabase'
export default function Login(){
 const [email,setEmail]=useState(''),[password,setPassword]=useState(''),[name,setName]=useState(''),[signup,setSignup]=useState(false),[error,setError]=useState('');const router=useRouter()
 async function submit(e:any){e.preventDefault();setError('');const r=signup?await supabase.auth.signUp({email,password,options:{data:{display_name:name}}}):await supabase.auth.signInWithPassword({email,password});if(r.error)setError(r.error.message);else router.push('/account')}
 return <main className="main" style={{margin:'0 auto',maxWidth:520}}><div className="panel"><h1>{signup?'Create player account':'Sign in'}</h1><form className="form" onSubmit={submit}>{signup&&<input placeholder="Name" value={name} onChange={e=>setName(e.target.value)} required/>}<input type="email" placeholder="Email" value={email} onChange={e=>setEmail(e.target.value)} required/><input type="password" placeholder="Password" value={password} onChange={e=>setPassword(e.target.value)} minLength={6} required/><button className="btn">{signup?'Create account':'Sign in'}</button></form>{error&&<p style={{color:'crimson'}}>{error}</p>}<p className="muted" onClick={()=>setSignup(!signup)} style={{cursor:'pointer'}}>{signup?'Already have an account? Sign in':'New player? Create an account'}</p></div></main>
}
