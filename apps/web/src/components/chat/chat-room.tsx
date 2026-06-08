"use client";

// ============================================================
//  Chat Room — Message display and compose area
// ============================================================

import { useEffect, useState, useRef, useCallback } from "react";
import { getLocalMessages } from "@/lib/services/message-service";
import { sendMessage } from "@/lib/services/message-service";
import type { LocalMessage } from "@/lib/db/local-db";
import { getOrCreateDeviceId } from "@/lib/device/register";

interface Props {
  conversationId: string;
  peerName: string;
}

export default function ChatRoom({ conversationId, peerName }: Props) {
  const [messages, setMessages] = useState<LocalMessage[]>([]);
  const [inputValue, setInputValue] = useState("");
  const [sending, setSending] = useState(false);
  const messagesEndRef = useRef<HTMLDivElement>(null);
  const inputRef = useRef<HTMLInputElement>(null);

  const loadMessages = useCallback(async () => {
    const msgs = await getLocalMessages(conversationId);
    setMessages(msgs);
  }, [conversationId]);

  useEffect(() => {
    loadMessages();
    const interval = setInterval(loadMessages, 1500);
    return () => clearInterval(interval);
  }, [loadMessages]);

  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: "smooth" });
  }, [messages]);

  const handleSend = async () => {
    const text = inputValue.trim();
    if (!text || sending) return;

    setSending(true);
    setInputValue("");

    try {
      const deviceId = getOrCreateDeviceId();
      await sendMessage(conversationId, text, deviceId);
      await loadMessages();
    } catch (e) {
      console.error("Send failed:", e);
    }

    setSending(false);
    inputRef.current?.focus();
  };

  const formatTime = (date: Date) => {
    return new Date(date).toLocaleTimeString([], {
      hour: "2-digit",
      minute: "2-digit",
    });
  };

  const getInitials = (name: string) => {
    const parts = name.trim().split(" ");
    if (parts.length >= 2) return `${parts[0][0]}${parts[1][0]}`.toUpperCase();
    return name.charAt(0).toUpperCase();
  };

  const statusIcon = (status: string) => {
    switch (status) {
      case "pending": return "⏳";
      case "sent": return "✓";
      case "delivered": return "✓✓";
      case "read": return "✓✓";
      case "failed": return "⚠";
      default: return "";
    }
  };

  return (
    <div className="chat-room-container">
      {/* Header */}
      <div className="chat-room-header">
        <div className="chat-room-avatar">
          {getInitials(peerName)}
        </div>
        <div className="chat-room-header-info">
          <span className="chat-room-peer-name">{peerName}</span>
          <span className="chat-room-e2e">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" width="10" height="10">
              <rect x="3" y="11" width="18" height="11" rx="2" ry="2" />
              <path d="M7 11V7a5 5 0 0 1 10 0v4" />
            </svg>
            End-to-end encrypted
          </span>
        </div>
      </div>

      {/* Messages */}
      <div className="chat-room-messages">
        {messages.length === 0 ? (
          <div className="chat-room-empty">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1" width="48" height="48" style={{ opacity: 0.3 }}>
              <rect x="3" y="11" width="18" height="11" rx="2" ry="2" />
              <path d="M7 11V7a5 5 0 0 1 10 0v4" />
            </svg>
            <p>Messages are end-to-end encrypted. No one outside of this chat can read them.</p>
          </div>
        ) : (
          messages.map((msg) => (
            <div
              key={msg.id}
              className={`message-bubble ${msg.isMine ? "mine" : "theirs"}`}
            >
              <p className="message-text">{msg.content}</p>
              <div className="message-meta">
                <span className="message-time">{formatTime(msg.sentAt)}</span>
                {msg.isMine && (
                  <span className={`message-status ${msg.status === "read" ? "read" : ""}`}>
                    {statusIcon(msg.status)}
                  </span>
                )}
              </div>
            </div>
          ))
        )}
        <div ref={messagesEndRef} />
      </div>

      {/* Input */}
      <div className="chat-room-input-bar">
        <input
          ref={inputRef}
          type="text"
          value={inputValue}
          onChange={(e) => setInputValue(e.target.value)}
          onKeyDown={(e) => e.key === "Enter" && handleSend()}
          placeholder="Type a message"
          className="chat-room-input"
          disabled={sending}
        />
        <button
          onClick={handleSend}
          className={`chat-room-send-btn ${inputValue.trim() ? "active" : ""}`}
          disabled={!inputValue.trim() || sending}
        >
          <svg viewBox="0 0 24 24" fill="currentColor" width="20" height="20">
            <path d="M2.01 21L23 12 2.01 3 2 10l15 2-15 2z" />
          </svg>
        </button>
      </div>
    </div>
  );
}
