"use client";

// ============================================================
//  New Chat Dialog — Search users and start a conversation
// ============================================================

import { useState, useCallback, useEffect } from "react";
import { getAllUsers, searchUsers, type Contact } from "@/lib/services/contact-service";
import { getOrCreateDirectConversation } from "@/lib/services/conversation-service";

interface Props {
  onClose: () => void;
  onConversationCreated: (conversationId: string, peerName: string) => void;
}

export default function NewChatDialog({ onClose, onConversationCreated }: Props) {
  const [query, setQuery] = useState("");
  const [results, setResults] = useState<Contact[]>([]);
  const [loading, setLoading] = useState(true);
  const [creating, setCreating] = useState(false);

  useEffect(() => {
    getAllUsers().then((users) => {
      setResults(users);
      setLoading(false);
    });
  }, []);

  const handleSearch = useCallback(async (q: string) => {
    setQuery(q);
    if (!q.trim()) {
      setLoading(true);
      const users = await getAllUsers();
      setResults(users);
      setLoading(false);
      return;
    }
    setLoading(true);
    const users = await searchUsers(q);
    setResults(users);
    setLoading(false);
  }, []);

  const handleSelect = async (contact: Contact) => {
    setCreating(true);
    try {
      const convId = await getOrCreateDirectConversation(contact);
      onConversationCreated(convId, contact.displayName);
    } catch (e) {
      console.error("Failed to create conversation:", e);
    }
    setCreating(false);
  };

  const getInitials = (name: string) => {
    const parts = name.trim().split(" ");
    if (parts.length >= 2) return `${parts[0][0]}${parts[1][0]}`.toUpperCase();
    return name.charAt(0).toUpperCase();
  };

  return (
    <div className="new-chat-overlay" onClick={onClose}>
      <div className="new-chat-modal" onClick={(e) => e.stopPropagation()}>
        <div className="new-chat-header">
          <h3>New Chat</h3>
          <button onClick={onClose} className="new-chat-close">&times;</button>
        </div>

        <div className="new-chat-search">
          <input
            type="text"
            value={query}
            onChange={(e) => handleSearch(e.target.value)}
            placeholder="Search by name..."
            autoFocus
          />
        </div>

        <div className="new-chat-results">
          {creating ? (
            <div className="new-chat-creating">Creating conversation...</div>
          ) : loading ? (
            <div className="new-chat-creating">Loading users...</div>
          ) : results.length === 0 ? (
            <div className="new-chat-creating">No users found</div>
          ) : (
            results.map((contact) => (
              <div
                key={contact.id}
                className="new-chat-contact"
                onClick={() => handleSelect(contact)}
              >
                <div
                  className="new-chat-avatar"
                  style={{
                    background: `linear-gradient(135deg, hsl(${Math.abs(contact.id.charCodeAt(0) * 37) % 360}, 60%, 45%), hsl(${Math.abs(contact.id.charCodeAt(0) * 37) % 360 + 30}, 60%, 55%))`,
                  }}
                >
                  {getInitials(contact.displayName)}
                </div>
                <div className="new-chat-contact-info">
                  <span className="new-chat-contact-name">{contact.displayName}</span>
                </div>
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" width="14" height="14" style={{ opacity: 0.3 }}>
                  <rect x="3" y="11" width="18" height="11" rx="2" ry="2" />
                  <path d="M7 11V7a5 5 0 0 1 10 0v4" />
                </svg>
              </div>
            ))
          )}
        </div>
      </div>
    </div>
  );
}
