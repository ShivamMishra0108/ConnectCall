const mongoose = require("mongoose");

const callSchema = new mongoose.Schema(
  {
    callId: {
      type: String,
      required: true,
      unique: true,
      index: true,
    },

    callerId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
    },

    receiverId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
    },

    callerName: {
      type: String,
      required: true,
      trim: true,
    },

    receiverName: {
      type: String,
      required: true,
      trim: true,
    },

    callType: {
      type: String,
      enum: ["audio", "video"],
      required: true,
    },

    status: {
      type: String,
      enum: [
        "ringing",
        "connected",
        "completed",
        "declined",
        "missed",
        "failed",
      ],
      default: "ringing",
    },

    startedAt: {
      type: Date,
      default: null,
    },

    endedAt: {
      type: Date,
      default: null,
    },

    duration: {
      type: Number,
      default: 0,
    },
  },
  {
    timestamps: true,
  }
);

module.exports = mongoose.model("Call", callSchema);