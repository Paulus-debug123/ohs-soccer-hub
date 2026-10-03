'use client'

import { useState, type FormEvent } from 'react'
import { useRouter } from 'next/navigation'
import { supabase } from '../../lib/supabase'

export default function ResetPassword() {
  const [password, setPassword] = useState('')
  const [confirm, setConfirm] = useState('')
  const [message, setMessage] = useState('')
  const [error, setError] = useState('')
  const router = useRouter()

  async function updatePassword(e: FormEvent<HTMLFormElement>) {
    e.preventDefault()
    setError('')
    setMessage('')

    if (password.length < 6) {
      setError('Password must be at least 6 characters.')
      return
    }

    if (password !== confirm) {
      setError('Passwords do not match.')
      return
    }

    const { error } = await supabase.auth.updateUser({
      password,
    })

    if (error) {
      setError(error.message)
      return
    }

    setMessage('Password updated successfully. Redirecting to login...')

    setTimeout(() => {
      router.push('/login')
    }, 1500)
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
        <h1>Create a new password</h1>

        <form className="form" onSubmit={updatePassword}>
          <input
            type="password"
            placeholder="New password"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            minLength={6}
            required
          />

          <input
            type="password"
            placeholder="Confirm new password"
            value={confirm}
            onChange={(e) => setConfirm(e.target.value)}
            minLength={6}
            required
          />

          <button className="btn" type="submit">
            Update password
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
      </div>
    </main>
  )
}
