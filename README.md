# OHS Soccer Hub — Online Edition

A real, database-backed football league management system built for Supabase.

## Included
- Public dashboard
- Teams, players and FPL-style squad view
- Player accounts/authentication
- Secure admin role
- Fixtures and results
- Automatic league table via database view
- Goals and assists
- Player ratings starting at 50
- Transfers and 7-day news
- Ikororo OHS Cup
- ELCIN Community Shield
- Awards and season history
- Admin CRUD for teams, players, matches, news and transfers
- SQL database schema + security policies

## 1. Create the database
Create a Supabase project, then open SQL Editor and run `supabase/schema.sql`.

## 2. Configure the website
Copy `.env.example` to `.env.local` and put in your Supabase project URL and anon/publishable key.

## 3. Run locally
Install Node.js 20+.

    npm install
    npm run dev

Open http://localhost:3000

## 4. Make yourself admin
After creating your account in the app, run this in Supabase SQL Editor, replacing the email:

    update public.profiles set role = 'admin' where email = 'YOUR_EMAIL';

## 5. Deploy
The project is designed for Vercel/Netlify-style deployment. Add the same environment variables in the hosting provider.

IMPORTANT:
- Never put the Supabase service-role key in browser code.
- The included SQL uses Row Level Security.
- Replace sample content with your actual league data.
