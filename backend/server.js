const express = require('express');
const http = require('http');
const cors = require('cors');
const { Server } = require('socket.io');

const app = express();

app.use(cors());
app.use(express.json());

const server = http.createServer(app);

const io = new Server(server, {
  cors: {
    origin: '*',
    methods: ['GET', 'POST'],
  },
});

const PORT = 3000;

// userId -> socketId
const onlineUsers = new Map();

app.get('/', (req, res) => {
  res.json({
    success: true,
    message: 'ConnectCall signaling server is running.',
  });
});

io.on('connection', (socket) => {
  console.log(`Socket connected: ${socket.id}`);

  /*
   * User comes online
   */
  socket.on('user-online', ({ userId }) => {
    if (!userId) {
      return;
    }

    onlineUsers.set(userId, socket.id);

    socket.userId = userId;

    console.log(
      `User online: ${userId} -> ${socket.id}`,
    );

    socket.emit('online-success', {
      userId,
    });
  });

  /*
   * Caller sends a call request.
   */
  socket.on('call-user', (data) => {
    const {
      callId,
      callerId,
      callerName,
      receiverId,
      callType,
    } = data;

    const receiverSocketId =
        onlineUsers.get(receiverId);

    if (!receiverSocketId) {
      socket.emit('call-error', {
        callId,
        message: 'User is currently offline.',
      });

      return;
    }

    io.to(receiverSocketId).emit(
      'incoming-call',
      {
        callId,
        callerId,
        callerName,
        receiverId,
        callType,
      },
    );

    console.log(
      `Call: ${callerId} -> ${receiverId}`,
    );
  });

  /*
   * WebRTC offer.
   */
  socket.on('webrtc-offer', (data) => {
    const {
      receiverId,
      offer,
    } = data;

    const receiverSocketId =
        onlineUsers.get(receiverId);

    if (!receiverSocketId) {
      return;
    }

    io.to(receiverSocketId).emit(
      'webrtc-offer',
      {
        senderId: socket.userId,
        offer,
      },
    );
  });

  /*
   * WebRTC answer.
   */
  socket.on('webrtc-answer', (data) => {
    const {
      receiverId,
      answer,
    } = data;

    const receiverSocketId =
        onlineUsers.get(receiverId);

    if (!receiverSocketId) {
      return;
    }

    io.to(receiverSocketId).emit(
      'webrtc-answer',
      {
        senderId: socket.userId,
        answer,
      },
    );
  });

  /*
   * ICE candidate.
   */
  socket.on('ice-candidate', (data) => {
    const {
      receiverId,
      candidate,
    } = data;

    const receiverSocketId =
        onlineUsers.get(receiverId);

    if (!receiverSocketId) {
      return;
    }

    io.to(receiverSocketId).emit(
      'ice-candidate',
      {
        senderId: socket.userId,
        candidate,
      },
    );
  });

  /*
   * Call accepted.
   */
  socket.on('call-accepted', (data) => {
    const {
      receiverId,
      callId,
    } = data;

    const receiverSocketId =
        onlineUsers.get(receiverId);

    if (!receiverSocketId) {
      return;
    }

    io.to(receiverSocketId).emit(
      'call-accepted',
      {
        callId,
        userId: socket.userId,
      },
    );
  });

  /*
   * Call declined.
   */
  socket.on('call-declined', (data) => {
    const {
      receiverId,
      callId,
    } = data;

    const receiverSocketId =
        onlineUsers.get(receiverId);

    if (!receiverSocketId) {
      return;
    }

    io.to(receiverSocketId).emit(
      'call-declined',
      {
        callId,
        userId: socket.userId,
      },
    );
  });

  /*
   * Call ended.
   */
  socket.on('call-ended', (data) => {
    const {
      receiverId,
      callId,
    } = data;

    const receiverSocketId =
        onlineUsers.get(receiverId);

    if (!receiverSocketId) {
      return;
    }

    io.to(receiverSocketId).emit(
      'call-ended',
      {
        callId,
        userId: socket.userId,
      },
    );
  });

  /*
   * User disconnects.
   */
  socket.on('disconnect', () => {
    if (socket.userId) {
      onlineUsers.delete(socket.userId);

      console.log(
        `User offline: ${socket.userId}`,
      );
    }

    console.log(
      `Socket disconnected: ${socket.id}`,
    );
  });
});

server.listen(PORT, '0.0.0.0', () => {
  console.log(
    `ConnectCall server running on port ${PORT}`,
  );
});