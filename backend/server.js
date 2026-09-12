const express = require("express");
const http = require("http");
const cors = require("cors");
const dotenv = require("dotenv");
const { Server } = require("socket.io");

const connectDB = require("./config/db");
const userRoutes = require("./routes/userRoutes");
const setupCallSocket = require("./sockets/callSocket");

dotenv.config();

const app = express();

const server = http.createServer(app);

const io = new Server(server, {
  cors: {
    origin: "*",
    methods: ["GET", "POST"]
  }
});


// Middleware
app.use(cors());
app.use(express.json());


// Database
connectDB();


// Routes
app.get("/", (req, res) => {
  res.json({
    success: true,
    message: "ConnectCall backend is running"
  });
});

app.use("/api/users", userRoutes);


// Socket.IO
setupCallSocket(io);


// Start server
const PORT = process.env.PORT || 3000;

server.listen(PORT, "0.0.0.0", () => {
  console.log(`ConnectCall server running on port ${PORT}`);
});