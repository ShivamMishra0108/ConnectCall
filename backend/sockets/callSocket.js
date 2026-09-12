const User = require("../models/User");

const onlineUsers = new Map();

const setupCallSocket = (io) => {
  io.on("connection", (socket) => {
    console.log("Socket connected:", socket.id);

    // ==========================================
    // USER COMES ONLINE
    // ==========================================
    socket.on("user-online", async (userId) => {
      try {
        onlineUsers.set(userId, socket.id);

        await User.findByIdAndUpdate(userId, {
          online: true,
          socketId: socket.id,
        });

        io.emit(
          "online-users",
          Array.from(onlineUsers.keys())
        );

        console.log("User online:", userId);
        console.log(
          "Current online users:",
          Array.from(onlineUsers.keys())
        );
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
    // Flutter sends: call-user
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
          const receiverSocketId =
            onlineUsers.get(receiverId);

          if (!receiverSocketId) {
            socket.emit("call-error", {
              message: "User is offline",
            });

            console.log(
              "Call failed. User offline:",
              receiverId
            );

            return;
          }

          io.to(receiverSocketId).emit(
            "incoming-call",
            {
              callId,
              callerId,
              callerName,
              receiverId,
              callType,
            }
          );

          console.log(
            `Call: ${callerName} (${callerId}) -> ${receiverId} [${callType}]`
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
    // Flutter sends: call-accepted
    // ==========================================
    socket.on(
      "call-accepted",
      ({ receiverId, callId }) => {
        const receiverSocketId =
          onlineUsers.get(receiverId);

        if (!receiverSocketId) {
          console.log(
            "Caller is no longer online:",
            receiverId
          );

          return;
        }

        io.to(receiverSocketId).emit(
          "call-accepted",
          {
            callId,
          }
        );

        console.log(
          "Call accepted:",
          callId
        );
      }
    );

    // ==========================================
    // CALL DECLINED
    // Flutter sends: call-declined
    // ==========================================
    socket.on(
      "call-declined",
      ({ receiverId, callId }) => {
        const receiverSocketId =
          onlineUsers.get(receiverId);

        if (!receiverSocketId) {
          return;
        }

        io.to(receiverSocketId).emit(
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
    // Flutter sends: webrtc-offer
    // ==========================================
    socket.on(
      "webrtc-offer",
      ({ receiverId, offer }) => {
        const receiverSocketId =
          onlineUsers.get(receiverId);

        if (!receiverSocketId) {
          console.log(
            "Offer receiver offline:",
            receiverId
          );

          return;
        }

        io.to(receiverSocketId).emit(
          "webrtc-offer",
          {
            offer,
          }
        );

        console.log(
          "WebRTC offer forwarded to:",
          receiverId
        );
      }
    );

    // ==========================================
    // WEBRTC ANSWER
    // Flutter sends: webrtc-answer
    // ==========================================
    socket.on(
      "webrtc-answer",
      ({ receiverId, answer }) => {
        const receiverSocketId =
          onlineUsers.get(receiverId);

        if (!receiverSocketId) {
          console.log(
            "Answer receiver offline:",
            receiverId
          );

          return;
        }

        io.to(receiverSocketId).emit(
          "webrtc-answer",
          {
            answer,
          }
        );

        console.log(
          "WebRTC answer forwarded to:",
          receiverId
        );
      }
    );

    // ==========================================
    // ICE CANDIDATE
    // ==========================================
    socket.on(
      "ice-candidate",
      ({ receiverId, candidate }) => {
        const receiverSocketId =
          onlineUsers.get(receiverId);

        if (!receiverSocketId) {
          return;
        }

        io.to(receiverSocketId).emit(
          "ice-candidate",
          {
            candidate,
          }
        );
      }
    );

    // ==========================================
    // END CALL
    // Flutter sends: call-ended
    // ==========================================
    socket.on(
      "call-ended",
      ({ receiverId, callId }) => {
        const receiverSocketId =
          onlineUsers.get(receiverId);

        if (!receiverSocketId) {
          return;
        }

        io.to(receiverSocketId).emit(
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

        for (
          const [userId, socketId]
          of onlineUsers.entries()
        ) {
          if (socketId === socket.id) {
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

            break;
          }
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
