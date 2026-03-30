# Domain Setup Guide: pokecardguess.com (IONOS + Railway)

This guide will help you connect your IONOS domain (`pokecardguess.com`) to your Railway project.

## Phase 1: Configure Railway

1.  **Open Railway Dashboard**.
2.  Click on your **Frontend (Client)** service.
3.  Go to **Settings** -> **Networking** -> **Custom Domains**.
4.  Click **+ Custom Domain**.
5.  Enter `pokecardguess.com`.
6.  Railway will display a **DNS Record** that you need to configure. It will look like:
    - **Type**: `CNAME`
    - **Value/Target**: `random-name.up.railway.app` (e.g., `card-guess-client.up.railway.app`).

> **Recommendation**: Also add `www.pokecardguess.com` as a second custom domain in Railway if you want both to work.

## Phase 2: Configure IONOS DNS

1.  Log in to your **IONOS** account.
2.  Go to **Domains & SSL**.
3.  Click on `pokecardguess.com`.
4.  Switch to the **DNS** tab.
5.  **Important**: If there are existing **A** (IPv4) or **AAAA** (IPv6) records pointing to IONOS (checking the "Value" usually shows an IONOS IP), delete them or modify them. You want Railway to handle the traffic.

### Setting up the Records

**Scenario A: Using `www.pokecardguess.com` (Safest)**

1.  Find the record for `www`. Delete it if it exists.
2.  Add a **CNAME** record:
    - **Host Name**: `www`
    - **Points to**: (The generic Railway domain from Phase 1, e.g., `client-production.up.railway.app`)
    - **TTL**: 1 hour (default)

**Scenario B: Using the Root Domain (`pokecardguess.com`)**
_Note: Standard DNS does not strictly allow CNAME records on the root domain (`@`). However, Railway often requires it. Try adding it as a CNAME first._

1.  Add a **CNAME** record:
    - **Host Name**: `@` (or leave empty if IONOS instructions say so)
    - **Points to**: (The generic Railway domain)

_If IONOS errors saying "CNAME on root is not allowed", you might set up a **Redirect** in IONOS from `pokecardguess.com` to `www.pokecardguess.com`, and use Scenario A for the actual connection._

## Phase 3: Update Backend Configuration

Now that your frontend has a new URL, the backend needs to know about it to allow connections (CORS) and handle Login redirects.

1.  **Railway Dashboard** -> **Backend (Server)** Service -> **Settings**.
2.  Update the **Environment Variable**: `CLIENT_URL`.
    - Old Value: `https://client-production.up.railway.app` (example)
    - **New Value**: `https://pokecardguess.com` (or `https://www.pokecardguess.com`, whichever you set up).
3.  **Redeploy the Backend** Service (Automatic if you save variables? If not, click triggers -> redeploy).

## Phase 4: Update OAuth Providers (Google/Facebook)

If you use Google/Facebook Login, their security settings will block the new domain until you whitelist it.

**For Google:**

1.  Go to [Google Cloud Console](https://console.cloud.google.com/).
2.  APIs & Services -> Credentials.
3.  Edit your OAuth 2.0 Client ID.
4.  **Authorized JavaScript origins**: Add `https://pokecardguess.com`.
5.  **Authorized redirect URIs**: Add `https://server-production.up.railway.app/auth/google/callback` (This usually stays the same if your backend URL didn't change).
    - _Wait, check your auth flow_: If your backend redirects _back_ to the frontend after login, ensure that logic uses the new `CLIENT_URL`.

**For Facebook:**

1.  Go to [Meta Developers](https://developers.facebook.com/).
2.  My Apps -> Your App -> Facebook Login -> Settings.
3.  Review **Valid OAuth Redirect URIs**.

## Verification

1.  Wait for DNS propagation (can take minutes to hours).
2.  Visit `https://pokecardguess.com`.
3.  Check if the SSL (Lock icon) appears (Railway handles HTTPS automatically).
4.  Try logging in and playing.
