import './globals.css'
import type { Metadata } from 'next'

export const metadata: Metadata = {
  title: 'OHS Soccer Hub',
  description: 'OHS Soccer Hub official league system'
}

export default function RootLayout({children}:{children:React.ReactNode}) {
  return <html lang="en"><body>{children}</body></html>
}
