# Chatizy E2EE — Full Implementation Roadmap

> This document is the master reference for all remaining work. 
> **Part 1 is COMPLETE.** Parts 2–5 are defined below.

---

## Status Overview

| Part | Title | Status |
|------|-------|--------|
| 1 | Foundation, Repo Setup, Auth, Device Registry & Schema | ✅ **COMPLETE** |
| 2 | Local Storage, Crypto Interfaces, Direct Messaging & Chat UI | ✅ **COMPLETE** |
| 3 | QR Linking, Multi-Device Sync, Receipts & Recovery | ⏳ Pending |
| 4 | Encrypted Media (R2), Attachments & Push Notifications | ⏳ Pending |
| 5 | Group Chat, Typing/Presence, Cleanup & Production Hardening | ⏳ Pending |

---

## Global Architecture Rules (Apply to ALL parts)

- **WhatsApp-like E2EE architecture.**
- **Readable/plaintext chat history lives only on client devices.**
- **Server-side storage is only for:** encrypted envelopes, routing metadata, sync metadata, receipts, device registry, and encrypted media metadata.
- **Do not** redesign into a normal server-stored plaintext chat.
- **Do not** invent env values, project IDs, secrets, bucket URLs, or deployment-specific settings.

---

## Part 1 — COMPLETED ✅

Foundation, repo setup, auth, device registry, server metadata schema.

**What was built:**
- Monorepo: Next.js web + Flutter mobile + shared-types + Supabase migrations
- 10 database tables (users, devices, one_time_prekeys, conversations, conversation_members, device_envelopes, media_objects, device_sync_cursors, linked_device_sessions, delivery_events)
- RLS policies for all tables
- Supabase Realtime publication config
- Edge Function stubs (register-device, rotate-prekeys)
- Auth (email/password) on both web and mobile
- Device registration scaffolding with placeholder prekeys
- Architecture documentation
- Debug APK built and tested with real Supabase credentials

**Supabase project:** `https://nzddduhyvgmzynligmup.supabase.co`  
**Schema applied:** All 10 tables verified and active.

---

## Part 2 — Local Storage, Crypto, Direct Messaging & Chat UI

### Goal
Implement the first end-to-end messaging path for **direct 1-to-1 chats** with local-only readable storage.

### Build in this part

**Web local data layer (IndexedDB):**
- conversations
- messages
- contacts
- device state
- sync cursor

**Flutter local data layer (Drift/SQLite):**
- chats
- messages
- attachments metadata
- outbound queue
- sessions metadata
- device state

**Crypto interfaces/services:**
- per-device identity keys (X25519)
- signed prekeys / one-time prekeys
- session bootstrap (simplified X3DH)
- encrypting a message on sender device (AES-256-GCM)
- decrypting a message on recipient device

**Direct conversation creation path**

**Envelope send path:**
- generate `client_message_id`
- create local pending message
- create encrypted envelopes per target device
- send via backend

**Envelope receive path:**
- fetch device queue
- decrypt locally
- write plaintext to local DB only

**Edge Functions:**
- `send-envelopes-batch`
- `fetch-device-queue`
- `ack-envelope`
- `submit-receipt`

**Basic chat list/chat room UI** that reads from local decrypted storage only

### Do NOT build
- QR linking flow
- Cloudflare R2 media upload/download
- Group chat
- Push notifications
- Typing/presence

### Done when
- A direct message can be created locally, encrypted, sent as per-device envelopes, fetched, decrypted, and stored locally
- Server stores ciphertext only

---

## Part 3 — QR Linking, Multi-Device Sync, Receipts & Recovery

### Goal
Implement **WhatsApp-like linked web sessions** and reliable recovery across devices.

### Build in this part
- Web QR linking page/UI
- Link-session creation flow
- Flutter QR scan and approval flow
- Edge Functions:
  - `create-link-session`
  - `approve-link-session`
- Register approved web session as a device
- Sync cursor logic using `device_sync_cursors`
- Idempotent queue processing
- Delivery/read receipt propagation across linked devices
- Basic device revocation flow
- Initial encrypted bootstrap design for linked web device

### Do NOT build
- Encrypted media flow
- Group chat
- Typing/presence
- Advanced search

### Done when
- A web device can be linked through QR approval
- It becomes a registered device
- It can receive encrypted envelopes as its own target device
- Recovery works using sync cursors

---

## Part 4 — Encrypted Media (R2), Attachments & Push Notifications

### Goal
Implement encrypted media handling and notification-driven sync for richer messaging.

### Build in this part
- Media encryption before upload on client
- Cloudflare R2 integration using placeholders for bucket details and credentials
- Edge Functions:
  - `create-upload-ticket`
  - `register-media-object`
  - `create-download-ticket` (if needed)
- Attachment manifest inside encrypted message payload
- Local attachment metadata and cache handling
- Attachment send/receive flow
- Mobile push notification registration scaffolding
- Push wake-up → fetch queue → decrypt flow
- Basic rich-message UI for image/file/audio/video metadata and previews

### Do NOT build
- Group key rotation
- Typing/presence
- Disappearing messages
- Production observability stack

### Done when
- Ciphertext media can be uploaded/downloaded
- Media metadata is server-side, decrypted usability is client-side
- Mobile can be woken to sync encrypted envelopes

---

## Part 5 — Group Chat, Typing/Presence, Cleanup & Production Hardening

### Goal
Finish the system with group messaging and operational pieces for a production-minded MVP.

### Build in this part
- Group conversation creation and membership management
- Group message fanout using encrypted per-device envelopes first
- Group admin/member roles
- Membership change handling
- Design hooks for future group key rotation
- Typing indicators as transient metadata only
- Presence / last-seen metadata with privacy controls
- Cleanup jobs:
  - expired envelopes
  - expired link sessions
  - stale or consumed prekeys
- Threat-model notes
- Test plan
- Production-hardening checklist

### Do NOT build
- Custom scaling infra beyond placeholders
- Extra features outside agreed scope

### Done when
- Group chat works with encrypted per-device fanout
- Typing/presence remain metadata-only
- Cleanup and hardening guidance exists

---

## Final Manual Steps (After All 5 Parts)

After all 5 parts are implemented and reviewed, do the following manually:

1. Provide the real **Supabase env files**
2. Provide the real **Cloudflare R2 env/config values**
3. Put the generated **SQL schema/migrations into the Supabase SQL editor**
4. Configure Auth providers / phone auth / OTP as needed
5. Configure bucket/access policies for R2
6. Wire real push credentials for FCM/APNs
7. Run end-to-end testing across:
   - mobile → mobile
   - mobile → web linked device
   - media send/receive
   - offline recovery
