# Chatizy E2EE — Architecture Overview

## System Design

Chatizy is a WhatsApp-like end-to-end encrypted (E2EE) messaging application.
**Readable/plaintext chat history lives ONLY on client devices.**

## Data Flow Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                     CLIENT DEVICES                          │
│  ┌─────────────┐           ┌─────────────┐                │
│  │  Mobile App  │           │   Web App    │                │
│  │  (Flutter)   │           │  (Next.js)   │                │
│  │             │           │             │                │
│  │ ┌─────────┐ │           │ ┌─────────┐ │                │
│  │ │ SQLite  │ │           │ │IndexedDB│ │                │
│  │ │Plaintext│ │           │ │Plaintext│ │                │
│  │ │Messages │ │           │ │Messages │ │                │
│  │ └─────────┘ │           │ └─────────┘ │                │
│  │ ┌─────────┐ │           │ ┌─────────┐ │                │
│  │ │ Crypto  │ │           │ │WebCrypto│ │                │
│  │ │ Engine  │ │           │ │ Engine  │ │                │
│  │ └─────────┘ │           │ └─────────┘ │                │
│  └──────┬──────┘           └──────┬──────┘                │
│         │                         │                        │
│         │ Encrypted Envelopes     │                        │
│         └────────────┬────────────┘                        │
└──────────────────────┼──────────────────────────────────────┘
                       │
                       ▼
┌──────────────────────────────────────────────────────────────┐
│                     SUPABASE (Server)                        │
│                                                              │
│  ┌────────────────┐  ┌──────────────┐  ┌───────────────┐   │
│  │  Auth Service   │  │   Postgres   │  │   Realtime    │   │
│  │  (JWT tokens)   │  │  (Metadata   │  │  (Push-based  │   │
│  │                 │  │   + Cipher)  │  │   delivery)   │   │
│  └────────────────┘  └──────────────┘  └───────────────┘   │
│                                                              │
│  ┌────────────────────────────────────────────────────────┐  │
│  │                  Edge Functions                         │  │
│  │  register-device | rotate-prekeys | send-envelopes     │  │
│  │  fetch-queue    | ack-envelope   | create-link-session │  │
│  └────────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────┘
                       │
                       ▼
┌──────────────────────────────────────────────────────────────┐
│                  CLOUDFLARE R2 (Media)                       │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  Encrypted media blobs ONLY                          │   │
│  │  (Decryption keys are inside encrypted envelopes,    │   │
│  │   NOT stored alongside the blobs)                    │   │
│  └──────────────────────────────────────────────────────┘   │
└──────────────────────────────────────────────────────────────┘
```

## What Lives Where

| Data                    | Location          | Encrypted? |
|-------------------------|-------------------|------------|
| Plaintext messages      | Client only       | At rest in local DB |
| Encrypted envelopes     | Supabase Postgres | Yes (ciphertext) |
| User profiles           | Supabase Postgres | No (public metadata) |
| Device registry         | Supabase Postgres | No (public keys) |
| Prekey bundles          | Supabase Postgres | No (public keys) |
| Conversation metadata   | Supabase Postgres | No (routing only) |
| Media blobs             | Cloudflare R2     | Yes (AES-GCM) |
| Media keys              | Inside envelopes  | Yes (per-device) |
| Delivery receipts       | Supabase Postgres | No (metadata) |
| Sync cursors            | Supabase Postgres | No (pointers) |

## Security Boundaries

1. **Server never sees plaintext messages** — only encrypted envelopes transit through Supabase.
2. **Media keys are inside encrypted payloads** — the `media_objects` table stores only the ciphertext blob pointer and IV, never the decryption key.
3. **Each device has its own keys** — messages are encrypted per-device, not per-user.
4. **Identity keys are public** — stored in `users.identity_public_key` for key verification.
5. **One-time prekeys are consumed** — each session init consumes a prekey, providing forward secrecy.
6. **RLS enforces access** — users can only read their own device's envelopes and manage their own devices.

## Table Purpose Summary

| Table                    | Purpose |
|--------------------------|---------|
| `users`                  | Profile metadata + identity public key |
| `devices`                | Per-device registration + signed prekeys |
| `one_time_prekeys`       | Consumable prekeys for X3DH session init |
| `conversations`          | Routing metadata (type, creator) — no names/previews |
| `conversation_members`   | User ↔ conversation membership with roles |
| `device_envelopes`       | Encrypted message routing (ciphertext only) |
| `media_objects`          | Encrypted blob metadata (R2 pointers) |
| `device_sync_cursors`    | Last-processed envelope per device |
| `linked_device_sessions` | QR linking state machine |
| `delivery_events`        | Delivered/read/played receipts |

## Implementation Parts

- **Part 1** (Current): Foundation, auth, device registry, server schema
- **Part 2**: Local storage, crypto, direct messaging
- **Part 3**: QR linking, multi-device sync, receipts
- **Part 4**: Encrypted media (R2), push notifications
- **Part 5**: Group chat, typing/presence, cleanup jobs
