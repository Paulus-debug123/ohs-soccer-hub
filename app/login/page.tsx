'use client'

import { useState, type FormEvent } from 'react'
import { useRouter } from 'next/navigation'
import { supabase } from '../../lib/supabase'

export default function Login() {
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [name, setName] = useState('')
  const [signup, setSignup] = useState(false)
  const [forgot, setForgot] = useState(false)
  const [message, setMessage] = useState('')
  const [error, setError] = useState('')
  const router = useRouter()

  async function submit(e: FormEvent<HTMLFormElement>) {
    e.preventDefault()
    setError('')
    setMessage('')

    if (forgot) {
      const { error: resetError } =
        await supabase.auth.resetPasswordForEmail(email, {
          redirectTo: `${window.location.origin}/auth/callback?next=/reset-password`,
        })

      if (resetError) {
        setError(resetError.message)
      } else {
        setMessage(
          'Password reset email sent. Check your email and open the link.'
        )
      }

      return
    }

    const result = signup
      ? await supabase.auth.signUp({
          email,
          password,
          options: {
            data: {
              display_name: name,
            },
          },
        })
      : await supabase.auth.signInWithPassword({
          email,
          password,
        })

    if (result.error) {
      setError(result.error.message)
    } else {
      router.push('/account')
    }
  }

  function switchMode() {
    setSignup(!signup)
    setForgot(false)
    setError('')
    setMessage('')
  }

  return (
    <main
      className="main"
      style={{
        margin: '0 auto',
        maxWidth: 520,
      }}
    >
      <div className="panel">
        <h1>
          {forgot
            ? 'Reset your password'
            : signup
              ? 'Create player account'
              : 'Sign in'}
        </h1>

        <form className="form" onSubmit={submit}>
          {signup && !forgot && (
            <input
              placeholder="Name"
              value={name}
              onChange={(e) => setName(e.target.value)}
              required
            />
          )}

          <input
            type="email"
            placeholder="Email"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            required
          />

          {!forgot && (
            <input
              type="password"
              placeholder="Password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              minLength={6}
              required
            />
          )}

          <button className="btn" type="submit">
            {forgot
              ? 'Send reset link'
              : signup
                ? 'Create account'
                : 'Sign in'}
          </button>
        </form>

        {error && (
          <p style={{ color: 'crimson' }}>
            {error}
          </p>
        )}

        {message && (
          <p style={{ color: '#16a34a' }}>
            {message}
          </p>
        )}

        {!signup && !forgot && (
          <p
            className="muted"
            onClick={() => {
              setForgot(true)
              setError('')
              setMessage('')
            }}
            style={{ cursor: 'pointer' }}
          >
            Forgot your password?
          </p>
        )}

        {forgot && (
          <p
            className="muted"
            onClick={switchMode}
            style={{ cursor: 'pointer' }}
          >
            ← Back to sign in
          </p>
        )}

        {!forgot && (
          <p
            className="muted"
            onClick={switchMode}
            style={{ cursor: 'pointer' }}
          >
            {signup
              ? 'Already have an account? Sign in'
              : 'New player? Create an account'}
          </p>
        )}
      </div>
    </main>
  )
}
