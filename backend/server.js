const express = require("express");
const http = require("http");
const cors = require("cors");
const dotenv = require("dotenv");
const { Server } = require("socket.io");

const connectDB = require("./config/db");
const userRoutes = require("./routes/userRoutes");
const callRoutes = require("./routes/callRoutes");
const setupCallSocket = require("./sockets/callSocket");

dotenv.config();

const app = express();

const server = http.createServer(app);

const io = new Server(server, {
  cors: {
    origin: "*",
    methods: ["GET", "POST", "PATCH"],
  },
});

// ============================================================
// MIDDLEWARE
// ============================================================

app.use(cors());
app.use(express.json());

// ============================================================
// DATABASE
// ============================================================

connectDB();

// ============================================================
// ROUTES
// ============================================================

app.get("/", (req, res) => {
  res.json({
    success: true,
    message: "ConnectCall backend is running",
  });
});

app.use("/api/users", userRoutes);
app.use("/api/calls", callRoutes);

// ============================================================
// SOCKET.IO
// ============================================================

setupCallSocket(io);

// ============================================================
// START SERVER
// ============================================================

const PORT = process.env.PORT || 3000;

server.listen(PORT, "0.0.0.0", () => {
  console.log(
    `ConnectCall server running on port ${PORT}`
  );
});