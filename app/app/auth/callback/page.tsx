'use client'

import { useEffect } from 'react'
import { useRouter, useSearchParams } from 'next/navigation'
import { supabase } from '../../../lib/supabase'

export default function AuthCallback() {
  const router = useRouter()
  const searchParams = useSearchParams()

  useEffect(() => {
    async function handleCallback() {
      const code = searchParams.get('code')
      const next = searchParams.get('next') || '/account'

      if (code) {
        const { error } = await supabase.auth.exchangeCodeForSession(code)

        if (error) {
          router.push('/login?error=reset')
          return
        }
      }

      router.push(next)
    }

    handleCallback()
  }, [router, searchParams])

  return (
    <main
      className="main"
      style={{
        margin: '0 auto',
        maxWidth: 520,
      }}
    >
      <div className="panel">
        <h1>Signing you in...</h1>
        <p className="muted">
          Please wait while we securely continue.
        </p>
      </div>
    </main>
  )
}
