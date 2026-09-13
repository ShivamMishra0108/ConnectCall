const User = require("../models/User");

// userId -> Set of socket IDs
const onlineUsers = new Map();

const setupCallSocket = (io) => {
  io.on("connection", (socket) => {
    console.log("Socket connected:", socket.id);

    // --------------------------------------------------
    // Helper: add a socket for a user
    // --------------------------------------------------
    const registerUser = async (userId) => {
      if (!userId) {
        console.log("Cannot register socket without userId");
        return;
      }

      const normalizedUserId = String(userId);

      if (!onlineUsers.has(normalizedUserId)) {
        onlineUsers.set(normalizedUserId, new Set());
      }

      onlineUsers.get(normalizedUserId).add(socket.id);

      // Keep the user ID attached to this socket.
      socket.userId = normalizedUserId;

      try {
        await User.findByIdAndUpdate(normalizedUserId, {
          online: true,
          socketId: socket.id,
        });
      } catch (error) {
        console.error("User online database update error:", error);
      }

      io.emit(
        "online-users",
        Array.from(onlineUsers.keys())
      );

      console.log("User online:", normalizedUserId);
      console.log(
        "Current online users:",
        Array.from(onlineUsers.keys())
      );
    };

    // --------------------------------------------------
    // Helper: get all sockets belonging to a user
    // --------------------------------------------------
    const getUserSockets = (userId) => {
      const normalizedUserId = String(userId);
      return onlineUsers.get(normalizedUserId) || new Set();
    };

    // --------------------------------------------------
    // Helper: check whether a user is online
    // --------------------------------------------------
    const isUserOnline = (userId) => {
      const sockets = getUserSockets(userId);
      return sockets.size > 0;
    };

    // --------------------------------------------------
    // Helper: emit to all sockets of a user
    // --------------------------------------------------
    const emitToUser = (userId, event, data) => {
      const sockets = getUserSockets(userId);

      if (sockets.size === 0) {
        return false;
      }

      for (const socketId of sockets) {
        io.to(socketId).emit(event, data);
      }

      return true;
    };

    // ==========================================
    // USER COMES ONLINE
    // ==========================================
    socket.on("user-online", async (userId) => {
      try {
        await registerUser(userId);
      } catch (error) {
        console.error("User online error:", error);
      }
    });

    // ==========================================
    // GET CURRENT ONLINE USERS
    // ==========================================
    socket.on("get-online-users", () => {
      const currentOnlineUsers =
        Array.from(onlineUsers.keys());

      socket.emit(
        "online-users",
        currentOnlineUsers
      );

      console.log(
        "Sent online users to:",
        socket.id,
        currentOnlineUsers
      );
    });

    // ==========================================
    // START CALL
    // ==========================================
    socket.on(
      "call-user",
      async ({
        callerId,
        callerName,
        receiverId,
        callId,
        callType,
      }) => {
        try {
          if (!callerId || !receiverId || !callId) {
            socket.emit("call-error", {
              message: "Invalid call information",
            });

            return;
          }

          const normalizedCallerId = String(callerId);
          const normalizedReceiverId = String(receiverId);

          console.log(
            `Call request: ${normalizedCallerId} -> ${normalizedReceiverId}`
          );

          console.log(
            "Receiver sockets:",
            Array.from(
              getUserSockets(normalizedReceiverId)
            )
          );

          if (!isUserOnline(normalizedReceiverId)) {
            socket.emit("call-error", {
              message: "User is offline",
            });

            console.log(
              "Call failed. User offline:",
              normalizedReceiverId
            );

            return;
          }

          const delivered = emitToUser(
            normalizedReceiverId,
            "incoming-call",
            {
              callId,
              callerId: normalizedCallerId,
              callerName,
              receiverId: normalizedReceiverId,
              callType,
            }
          );

          if (!delivered) {
            socket.emit("call-error", {
              message: "User is offline",
            });

            return;
          }

          console.log(
            `Call sent: ${callerName} (${normalizedCallerId}) -> ${normalizedReceiverId} [${callType}]`
          );
        } catch (error) {
          console.error(
            "Call user error:",
            error
          );

          socket.emit("call-error", {
            message: "Unable to start call",
          });
        }
      }
    );

    // ==========================================
    // CALL ACCEPTED
    // ==========================================
    socket.on(
      "call-accepted",
      ({ receiverId, callId }) => {
        try {
          if (!receiverId || !callId) {
            return;
          }

          const normalizedReceiverId = String(receiverId);

          console.log(
            "Call accepted:",
            callId,
            "forwarding to:",
            normalizedReceiverId
          );

          const delivered = emitToUser(
            normalizedReceiverId,
            "call-accepted",
            {
              callId,
            }
          );

          if (!delivered) {
            console.log(
              "Caller is no longer online:",
              normalizedReceiverId
            );
          }
        } catch (error) {
          console.error(
            "Call accepted error:",
            error
          );
        }
      }
    );

    // ==========================================
    // CALL DECLINED
    // ==========================================
    socket.on(
      "call-declined",
      ({ receiverId, callId }) => {
        if (!receiverId || !callId) {
          return;
        }

        const normalizedReceiverId = String(receiverId);

        emitToUser(
          normalizedReceiverId,
          "call-declined",
          {
            callId,
          }
        );

        console.log(
          "Call declined:",
          callId
        );
      }
    );

    // ==========================================
    // WEBRTC OFFER
    // ==========================================
    socket.on(
      "webrtc-offer",
      ({ receiverId, offer }) => {
        if (!receiverId || !offer) {
          console.log(
            "Invalid WebRTC offer"
          );

          return;
        }

        const normalizedReceiverId = String(receiverId);

        const delivered = emitToUser(
          normalizedReceiverId,
          "webrtc-offer",
          {
            offer,
          }
        );

        if (!delivered) {
          console.log(
            "Offer receiver offline:",
            normalizedReceiverId
          );

          return;
        }

        console.log(
          "WebRTC offer forwarded to:",
          normalizedReceiverId
        );
      }
    );

    // ==========================================
    // WEBRTC ANSWER
    // ==========================================
    socket.on(
      "webrtc-answer",
      ({ receiverId, answer }) => {
        if (!receiverId || !answer) {
          console.log(
            "Invalid WebRTC answer"
          );

          return;
        }

        const normalizedReceiverId = String(receiverId);

        const delivered = emitToUser(
          normalizedReceiverId,
          "webrtc-answer",
          {
            answer,
          }
        );

        if (!delivered) {
          console.log(
            "Answer receiver offline:",
            normalizedReceiverId
          );

          return;
        }

        console.log(
          "WebRTC answer forwarded to:",
          normalizedReceiverId
        );
      }
    );

    // ==========================================
    // ICE CANDIDATE
    // ==========================================
    socket.on(
      "ice-candidate",
      ({ receiverId, candidate }) => {
        if (!receiverId || !candidate) {
          return;
        }

        const normalizedReceiverId = String(receiverId);

        emitToUser(
          normalizedReceiverId,
          "ice-candidate",
          {
            candidate,
          }
        );
      }
    );

    // ==========================================
    // END CALL
    // ==========================================
    socket.on(
      "call-ended",
      ({ receiverId, callId }) => {
        if (!receiverId || !callId) {
          return;
        }

        const normalizedReceiverId = String(receiverId);

        emitToUser(
          normalizedReceiverId,
          "call-ended",
          {
            callId,
          }
        );

        console.log(
          "Call ended:",
          callId
        );
      }
    );

    // ==========================================
    // DISCONNECT
    // ==========================================
    socket.on(
      "disconnect",
      async () => {
        console.log(
          "Socket disconnected:",
          socket.id
        );

        const userId = socket.userId;

        if (!userId) {
          console.log(
            "Disconnected socket had no registered user."
          );

          return;
        }

        const sockets = onlineUsers.get(userId);

        if (!sockets) {
          return;
        }

        // Remove only this socket.
        sockets.delete(socket.id);

        // IMPORTANT:
        // If another socket for the same user is still
        // connected, the user must remain online.
        if (sockets.size > 0) {
          console.log(
            `User ${userId} still has ${sockets.size} active socket(s).`
          );

          return;
        }

        // No sockets remain for this user.
        onlineUsers.delete(userId);

        try {
          await User.findByIdAndUpdate(
            userId,
            {
              online: false,
              socketId: null,
            }
          );

          console.log(
            "User offline:",
            userId
          );
        } catch (error) {
          console.error(
            "Disconnect update error:",
            error
          );
        }

        io.emit(
          "online-users",
          Array.from(onlineUsers.keys())
        );

        console.log(
          "Current online users:",
          Array.from(onlineUsers.keys())
        );
      }
    );
  });
};

module.exports = setupCallSocket;