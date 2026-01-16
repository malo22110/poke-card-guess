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

## 3. Connecting them

- Ensure your Client knows the Server's URL. You may need to update `apps/client/lib/services/game_service.ts` (or equivalent Dart file) to point to your Production Backend URL instead of `localhost:3000`.
