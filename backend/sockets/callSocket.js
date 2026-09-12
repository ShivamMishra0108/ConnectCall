const User = require("../models/User");

const onlineUsers = new Map();

const setupCallSocket = (io) => {
  io.on("connection", (socket) => {
    console.log("Socket connected:", socket.id);

    // User comes online
    socket.on("user-online", async (userId) => {
      try {
        onlineUsers.set(userId, socket.id);

        await User.findByIdAndUpdate(userId, {
          online: true,
          socketId: socket.id
        });

        io.emit("online-users", Array.from(onlineUsers.keys()));

        console.log("User online:", userId);
      } catch (error) {
        console.error("User online error:", error);
      }
    });


    // Start call
    socket.on("call-user", ({ callerId, receiverId, callType }) => {
      const receiverSocketId = onlineUsers.get(receiverId);

      if (!receiverSocketId) {
        socket.emit("call-error", {
          message: "User is offline"
        });

        return;
      }

      io.to(receiverSocketId).emit("incoming-call", {
        callerId,
        receiverId,
        callType
      });

      console.log(
        `Call: ${callerId} -> ${receiverId} (${callType})`
      );
    });


    // Call accepted
    socket.on("accept-call", ({ callerId, receiverId }) => {
      const callerSocketId = onlineUsers.get(callerId);

      if (callerSocketId) {
        io.to(callerSocketId).emit("call-accepted", {
          callerId,
          receiverId
        });
      }
    });


    // Call rejected
    socket.on("reject-call", ({ callerId, receiverId }) => {
      const callerSocketId = onlineUsers.get(callerId);

      if (callerSocketId) {
        io.to(callerSocketId).emit("call-rejected", {
          callerId,
          receiverId
        });
      }
    });


    // WebRTC offer
    socket.on("offer", ({ receiverId, offer }) => {
      const receiverSocketId = onlineUsers.get(receiverId);

      if (receiverSocketId) {
        io.to(receiverSocketId).emit("offer", {
          offer
        });
      }
    });


    // WebRTC answer
    socket.on("answer", ({ receiverId, answer }) => {
      const receiverSocketId = onlineUsers.get(receiverId);

      if (receiverSocketId) {
        io.to(receiverSocketId).emit("answer", {
          answer
        });
      }
    });


    // ICE candidate
    socket.on("ice-candidate", ({ receiverId, candidate }) => {
      const receiverSocketId = onlineUsers.get(receiverId);

      if (receiverSocketId) {
        io.to(receiverSocketId).emit("ice-candidate", {
          candidate
        });
      }
    });


    // End call
    socket.on("end-call", ({ receiverId }) => {
      const receiverSocketId = onlineUsers.get(receiverId);

      if (receiverSocketId) {
        io.to(receiverSocketId).emit("call-ended");
      }
    });


    // Disconnect
    socket.on("disconnect", async () => {
      console.log("Socket disconnected:", socket.id);

      for (const [userId, socketId] of onlineUsers.entries()) {
        if (socketId === socket.id) {
          onlineUsers.delete(userId);

          try {
            await User.findByIdAndUpdate(userId, {
              online: false,
              socketId: null
            });
          } catch (error) {
            console.error("Disconnect update error:", error);
          }

          break;
        }
      }

      io.emit("online-users", Array.from(onlineUsers.keys()));
    });
  });
};

module.exports = setupCallSocket;