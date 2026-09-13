const express = require("express");
const router = express.Router();

const Call = require("../models/Call");

// ============================================================
// CREATE CALL
// POST /api/calls
// ============================================================

router.post("/", async (req, res) => {
  try {
    const {
      callId,
      callerId,
      receiverId,
      callerName,
      receiverName,
      callType,
    } = req.body;

    if (
      !callId ||
      !callerId ||
      !receiverId ||
      !callerName ||
      !receiverName ||
      !callType
    ) {
      return res.status(400).json({
        success: false,
        message: "Required call information is missing.",
      });
    }

    const existingCall = await Call.findOne({
      callId,
    });

    if (existingCall) {
      return res.status(409).json({
        success: false,
        message: "Call already exists.",
      });
    }

    const call = await Call.create({
      callId,
      callerId,
      receiverId,
      callerName,
      receiverName,
      callType,
      status: "ringing",
    });

    return res.status(201).json({
      success: true,
      message: "Call created successfully.",
      call,
    });
  } catch (error) {
    console.error(
      "CREATE CALL ERROR:",
      error,
    );

    return res.status(500).json({
      success: false,
      message: "Unable to create call.",
    });
  }
});

// ============================================================
// UPDATE CALL
// PATCH /api/calls/:callId
// ============================================================

router.patch("/:callId", async (req, res) => {
  try {
    const { callId } = req.params;

    const {
      status,
      startedAt,
      endedAt,
      duration,
    } = req.body;

    const updateData = {};

    if (status != null) {
      updateData.status = status;
    }

    if (startedAt != null) {
      updateData.startedAt = startedAt;
    }

    if (endedAt != null) {
      updateData.endedAt = endedAt;
    }

    if (duration != null) {
      updateData.duration = duration;
    }

    const call = await Call.findOneAndUpdate(
      {
        callId,
      },
      updateData,
      {
        new: true,
      },
    );

    if (!call) {
      return res.status(404).json({
        success: false,
        message: "Call not found.",
      });
    }

    return res.status(200).json({
      success: true,
      message: "Call updated successfully.",
      call,
    });
  } catch (error) {
    console.error(
      "UPDATE CALL ERROR:",
      error,
    );

    return res.status(500).json({
      success: false,
      message: "Unable to update call.",
    });
  }
});

// ============================================================
// GET USER CALL HISTORY
// GET /api/calls/user/:userId
// ============================================================

router.get("/user/:userId", async (req, res) => {
  try {
    const { userId } = req.params;

    const calls = await Call.find({
      $or: [
        {
          callerId: userId,
        },
        {
          receiverId: userId,
        },
      ],
    })
        .sort({
          createdAt: -1,
        })
        .lean();

    return res.status(200).json({
      success: true,
      calls,
    });
  } catch (error) {
    console.error(
      "GET CALL HISTORY ERROR:",
      error,
    );

    return res.status(500).json({
      success: false,
      message: "Unable to load call history.",
    });
  }
});

module.exports = router;