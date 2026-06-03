[README.md](https://github.com/user-attachments/files/28573502/README.md)
# FieldSales NZ — Setup & Deployment Guide

A mobile-first sales call management app for field reps.  
Built with vanilla HTML/JS + Supabase (database + file storage).

---

## 1 — Create a Supabase Project

1. Go to **https://supabase.com** → Sign in / create a free account  
2. Click **"New project"**  
   - Organisation: your org (or create one)  
   - Name: `fieldsales-nz`  
   - Database Password: generate a strong one and save it  
   - Region: **Southeast Asia (Singapore)** — closest to NZ  
3. Wait ~2 minutes for the project to provision  

---

## 2 — Run the Database Schema

1. In your Supabase project, click **SQL Editor** (left sidebar)  
2. Click **"New query"**  
3. Open the file `supabase-schema.sql` from this repo  
4. Paste the entire contents into the editor  
5. Click **"Run"** — you should see "Success. No rows returned"  

This creates all tables, RLS policies, and the storage bucket automatically.

---

## 3 — Get Your API Keys

1. In Supabase, go to **Settings → API** (gear icon, bottom left)  
2. Copy these two values:
   - **Project URL** — looks like `https://xxxxxxxxxxxx.supabase.co`
   - **anon public key** — the long JWT starting with `eyJ...`  

---

## 4 — Configure the App

Open `index.html` and find these two lines near the top of the `<script>` section:

```js
const SUPABASE_URL = 'YOUR_SUPABASE_URL';
const SUPABASE_ANON_KEY = 'YOUR_SUPABASE_ANON_KEY';
```

Replace with your actual values:

```js
const SUPABASE_URL = 'https://xxxxxxxxxxxx.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...';
```

Save the file.

---

## 5 — Deploy to GitHub Pages (free hosting)

### First time setup

```bash
# 1. Create a new repo on github.com (name it e.g. "fieldsales-nz")
#    Make it PUBLIC for free GitHub Pages

# 2. Clone it locally
git clone https://github.com/YOUR_USERNAME/fieldsales-nz.git
cd fieldsales-nz

# 3. Copy app files into the repo
cp /path/to/index.html .
cp /path/to/supabase-schema.sql .
cp /path/to/README.md .

# 4. Push to GitHub
git add .
git commit -m "Initial deploy"
git push origin main
```

### Enable GitHub Pages

1. Go to your repo on GitHub  
2. **Settings → Pages** (left sidebar)  
3. Source: **Deploy from a branch**  
4. Branch: `main` / `/ (root)` → Save  
5. Wait ~1 minute → your app is live at:  
   `https://YOUR_USERNAME.github.io/fieldsales-nz/`

### Updating the app

```bash
# Make changes to index.html, then:
git add .
git commit -m "Update: describe what changed"
git push origin main
# GitHub Pages rebuilds automatically in ~30 seconds
```

---

## 6 — Add to Home Screen (iOS / Android)

For the best mobile experience, add the app to your phone's home screen:

**iPhone/iPad (Safari):**  
Share button → "Add to Home Screen" → Add  

**Android (Chrome):**  
Menu (⋮) → "Add to Home screen" → Add  

This makes it feel like a native app with no browser chrome.

---

## File Structure

```
fieldsales-nz/
├── index.html          ← The entire app (single file)
├── supabase-schema.sql ← Run once in Supabase SQL Editor
└── README.md           ← This file
```

---

## Storage Layout (Supabase Storage)

Files are stored in the `fieldsales-media` bucket with this path structure:

```
fieldsales-media/
├── customers/
│   └── {customer_id}/
│       ├── planogram/
│       ├── price-list/
│       ├── contract/
│       ├── photo/
│       └── other/
└── calls/
    └── {call_id}/
        └── {filename}
```

---

## Adding Authentication Later

When you're ready to add login (so reps only see their own data):

1. Enable **Supabase Auth** → Email provider  
2. Add an `owner_id uuid references auth.users` column to each table  
3. Update RLS policies to `using (auth.uid() = owner_id)`  
4. Add a login screen to `index.html`  

---

## Troubleshooting

| Problem | Fix |
|---|---|
| "Failed to fetch" errors | Check SUPABASE_URL and ANON_KEY are set correctly |
| Photos not uploading | Confirm the `fieldsales-media` bucket exists and is public |
| Data not saving | Open browser DevTools → Console for error details |
| App looks broken | Hard refresh: Ctrl+Shift+R (Windows) / Cmd+Shift+R (Mac) |
