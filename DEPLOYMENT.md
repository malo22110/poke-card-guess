# Deployment Guide

## 1. Backend (NestJS)

### Database Configuration (Important!)

By default, the backend uses SQLite. For a production deployment (Render, Railway, Heroku, etc.), you strongly should switch to PostgreSQL.

1.  **Get a Postgres Database**: Create one on Render, Railway, Neon, or Supabase.
2.  **Update Config**:
    - Set `DATABASE_URL` environment variable to your Postgres connection string (e.g., `postgresql://user:pass@host:5432/db`).
    - **Migration**: You might need to adjust `prisma/schema.prisma`. Change `provider = "sqlite"` to `provider = "postgresql"` if you are ready to switch.

### Deploying with Docker (Recommended)

We have added a `Dockerfile` to `apps/server`. You can deploy this to any container platform (Railway, Render, Fly.io).

**Render Example:**

1.  Connect your GitHub repo.
2.  Create a "Web Service".
3.  Root Directory: `apps/server`
4.  Runtime: Docker
5.  Environment Variables:
    - `DATABASE_URL`: Your production DB URL.
    - `JWT_SECRET`: A secure random string.
    - `GOOGLE_CLIENT_ID` / `GOOGLE_CLIENT_SECRET`: For auth (if used).
    - `FACEBOOK_APP_ID` / `FACEBOOK_APP_SECRET`: For auth (if used).

## 2. Frontend (Flutter Web)

### Deploying to Vercel (Easiest)

1.  Install Vercel CLI or go to vercel.com.
2.  Import the repository.
3.  **Build Settings**:
    - Framework: Other
    - Build Command: `flutter build web --release`
    - Output Directory: `build/web`
    - Root Directory: `apps/client`
4.  **Environment Variables**:
    - You might need to set the backend URL in your Flutter app configuration (e.g., `API_URL`).

### Deploying with Docker

We have added a `Dockerfile` to `apps/client`.

1.  This builds the Flutter app and serves it with Nginx.
2.  Deploy to Railway/Render as a Docker service.
    - Root Directory: `apps/client`
    - Port: 80
    - **Build Arguments** (Set these during deployment configuration):
      - `API_URL`: URL of your deployed backend (e.g., `https://my-api.onrender.com`).
      - `SOCKET_URL`: URL of your socket server (usually same as API).
      - `PAYPAL_CLIENT_ID`: Your PayPal Client ID (prod or sandbox).
      - `PAYPAL_CURRENCY`: Currency code (default USD).

## 3. Connecting them

- Ensure your Client knows the Server's URL. You may need to update `apps/client/lib/services/game_service.ts` (or equivalent Dart file) to point to your Production Backend URL instead of `localhost:3000`.

---

# 🚀 Deployment Walkthrough (Recommended: Railway)

We recommend **Railway** for this project because it handles Docker containers and PostgreSQL seamlessly in a single project view.

### Prerequisites

- A GitHub account.
- The project pushed to GitHub.

### Step-by-Step Guide

1.  **Sign Up & Create Project**
    - Go to [railway.app](https://railway.app/) and sign in with GitHub.
    - Click **"New Project"** -> **"Deploy from GitHub repo"**.
    - Select your `PokeCardGuess` repository.

2.  **Add Database (PostgreSQL)**
    - In your Railway project canvas, right-click (or click "New") -> **Database** -> **Add PostgreSQL**.
    - This will spin up a tracked Postgres instance.

3.  **Configure Backend (NestJS)**
    - Click your repo card in the canvas.
    - Go to **Settings** -> **General** -> **Root Directory**: Set to `/apps/server`.
    - Go to **Variables**:
      - `DATABASE_URL`: Click "Reference Variable" -> Select `Postgres` -> `DATABASE_URL`.
      - `JWT_SECRET`: Generate a random string.
      - `PORT`: Set to `3000`.
      - `GOOGLE_...` / `FACEBOOK_...`: Add your OAuth credentials if you have them.
    - **Networking**: Generate a Domain (e.g., `server-production.up.railway.app`).

4.  **Configure Frontend (Flutter)**
    - Add a **second service** from the same GitHub repo (Click "New" -> GitHub Repo -> Select `PokeCardGuess` again).
    - Go to **Settings** -> **General** -> **Root Directory**: Set to `/apps/client`.
    - **Networking**: Generate a Domain (e.g., `client-production.up.railway.app`).
    - **Settings** -> **Build**:
      - Dockerfile Path: `Dockerfile`
      - **Build Arguments** (Click "New ARG"):
        - `API_URL`: `https://<YOUR-BACKEND-DOMAIN>` (e.g., `https://server-production.up.railway.app`)
        - `SOCKET_URL`: `https://<YOUR-BACKEND-DOMAIN>`
        - `PAYPAL_CLIENT_ID`: Your PayPal Client ID.
        - `PAYPAL_CURRENCY`: `USD` (or your pref).

5.  **Verify**
    - Wait for both to deploy (Green checkmarks).
    - Open your Client Domain.
    - Try to log in (Ensure your Google Cloud console allows the new Railway Domain as a redirect URI!).
