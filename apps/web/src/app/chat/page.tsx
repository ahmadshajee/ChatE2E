"use client";

// ============================================================
//  Chat Page — WhatsApp Web-style two-panel layout
//  Left: Conversation list + new chat
//  Right: Active chat room
// ============================================================

import { useEffect, useState, useCallback } from "react";
import { createClient } from "@/lib/supabase/client";
import { useRouter } from "next/navigation";
import { isDeviceRegistered, getOrCreateDeviceId } from "@/lib/device/register";
import { catchUp } from "@/lib/services/message-service";
import ConversationList from "@/components/chat/conversation-list";
import ChatRoom from "@/components/chat/chat-room";
import NewChatDialog from "@/components/chat/new-chat-dialog";
import type { LocalConversation } from "@/lib/db/local-db";

export default function ChatPage() {
  const [activeConversation, setActiveConversation] = useState<LocalConversation | null>(null);
  const [showNewChat, setShowNewChat] = useState(false);
  const [deviceId, setDeviceId] = useState("");
  const [deviceStatus, setDeviceStatus] = useState<"loading" | "registered" | "unregistered">("loading");

  const supabase = createClient();
  const router = useRouter();

  useEffect(() => {
    const id = getOrCreateDeviceId();
    setDeviceId(id);
    setDeviceStatus(isDeviceRegistered() ? "registered" : "unregistered");

    // Catch up pending messages
    if (isDeviceRegistered() && id) {
      catchUp(id);
    }
  }, []);

  const handleSignOut = async () => {
    await supabase.auth.signOut();
    router.push("/auth");
    router.refresh();
  };

  const handleSelectConversation = useCallback((conv: LocalConversation) => {
    setActiveConversation(conv);
    setShowNewChat(false);
  }, []);

  const handleNewConversationCreated = useCallback((convId: string, peerName: string) => {
    setActiveConversation({
      id: convId,
      peerUserId: "",
      peerDisplayName: peerName,
      peerEmail: "",
      unreadCount: 0,
    });
    setShowNewChat(false);
  }, []);

  return (
    <div className="chat-layout">
      {/* Left Sidebar */}
      <div className="chat-sidebar">
        <ConversationList
          activeConversationId={activeConversation?.id}
          onSelectConversation={handleSelectConversation}
          onNewChat={() => setShowNewChat(true)}
        />

        {/* Bottom bar with device info + sign out */}
        <div className="chat-sidebar-footer">
          <div className="device-status">
            <span className={`device-dot ${deviceStatus === "registered" ? "green" : "orange"}`} />
            <span className="device-text">
              {deviceStatus === "loading"
                ? "Loading..."
                : deviceStatus === "registered"
                  ? `${deviceId.slice(0, 8)}...`
                  : "No Device"}
            </span>
          </div>
          <button onClick={handleSignOut} className="sidebar-signout-btn">
            Sign Out
          </button>
        </div>
      </div>

      {/* Right Panel */}
      <div className="chat-main">
        {activeConversation ? (
          <ChatRoom
            key={activeConversation.id}
            conversationId={activeConversation.id}
            peerName={activeConversation.peerDisplayName}
          />
        ) : (
          <div className="chat-welcome">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1" width="64" height="64" style={{ opacity: 0.2 }}>
              <path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z" />
            </svg>
            <h2>Welcome to Chatizy</h2>
            <p>
              Your messages are end-to-end encrypted. Select a conversation
              or start a new chat.
            </p>
          </div>
        )}
      </div>

      {/* New Chat Modal */}
      {showNewChat && (
        <NewChatDialog
          onClose={() => setShowNewChat(false)}
          onConversationCreated={handleNewConversationCreated}
        />
      )}
    </div>
  );
}
