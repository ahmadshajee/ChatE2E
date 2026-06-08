"use client";

// ============================================================
//  Conversation List — Sidebar component
// ============================================================

import { useEffect, useState, useCallback } from "react";
import {
  getConversations,
  syncConversations,
} from "@/lib/services/conversation-service";
import type { LocalConversation } from "@/lib/db/local-db";

interface Props {
  activeConversationId?: string;
  onSelectConversation: (conv: LocalConversation) => void;
  onNewChat: () => void;
}

export default function ConversationList({
  activeConversationId,
  onSelectConversation,
  onNewChat,
}: Props) {
  const [conversations, setConversations] = useState<LocalConversation[]>([]);
  const [loading, setLoading] = useState(true);

  const loadConversations = useCallback(async () => {
    const convs = await getConversations();
    setConversations(convs);
    setLoading(false);
  }, []);

  useEffect(() => {
    syncConversations().then(loadConversations);
    const interval = setInterval(loadConversations, 3000);
    return () => clearInterval(interval);
  }, [loadConversations]);

  const formatTime = (date?: Date) => {
    if (!date) return "";
    const d = new Date(date);
    const now = new Date();
    const diff = now.getTime() - d.getTime();
    if (diff < 86400000) {
      return d.toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" });
    }
    if (diff < 172800000) return "Yesterday";
    return d.toLocaleDateString([], { month: "short", day: "numeric" });
  };

  const getInitials = (name: string) => {
    const parts = name.trim().split(" ");
    if (parts.length >= 2) return `${parts[0][0]}${parts[1][0]}`.toUpperCase();
    return name.charAt(0).toUpperCase();
  };

  return (
    <div className="conv-list-container">
      {/* Header */}
      <div className="conv-list-header">
        <h2>Chats</h2>
        <button onClick={onNewChat} className="new-chat-btn" title="New chat">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" width="20" height="20">
            <path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z" />
            <line x1="12" y1="8" x2="12" y2="14" />
            <line x1="9" y1="11" x2="15" y2="11" />
          </svg>
        </button>
      </div>

      {/* Conversation list */}
      <div className="conv-list-items">
        {loading ? (
          <div className="conv-list-loading">Loading...</div>
        ) : conversations.length === 0 ? (
          <div className="conv-list-empty">
            <p>No conversations yet</p>
            <button onClick={onNewChat} className="conv-list-start-btn">
              Start a chat
            </button>
          </div>
        ) : (
          conversations.map((conv) => (
            <div
              key={conv.id}
              className={`conv-tile ${activeConversationId === conv.id ? "active" : ""}`}
              onClick={() => onSelectConversation(conv)}
            >
              <div
                className="conv-avatar"
                style={{
                  background: `linear-gradient(135deg, hsl(${Math.abs(conv.peerUserId.charCodeAt(0) * 37) % 360}, 60%, 45%), hsl(${Math.abs(conv.peerUserId.charCodeAt(0) * 37) % 360 + 30}, 60%, 55%))`,
                }}
              >
                {getInitials(conv.peerDisplayName)}
              </div>
              <div className="conv-info">
                <div className="conv-top-row">
                  <span className="conv-name">{conv.peerDisplayName}</span>
                  <span className={`conv-time ${conv.unreadCount > 0 ? "unread" : ""}`}>
                    {formatTime(conv.lastMessageAt)}
                  </span>
                </div>
                <div className="conv-bottom-row">
                  <span className={`conv-preview ${conv.unreadCount > 0 ? "unread" : ""}`}>
                    {conv.lastMessage ?? "No messages yet"}
                  </span>
                  {conv.unreadCount > 0 && (
                    <span className="conv-badge">{conv.unreadCount}</span>
                  )}
                </div>
              </div>
            </div>
          ))
        )}
      </div>
    </div>
  );
}
