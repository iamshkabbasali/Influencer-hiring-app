const express = require('express');
const router = express.Router();
const db = require('../config/db');
const { verifyToken } = require('../middleware/authMiddleware');


// ==========================================
// FOLLOW USER
// ==========================================
router.post('/:id', verifyToken, async (req, res) => {

  const followerId = req.user.id;
  const targetId = parseInt(req.params.id);

  if (followerId === targetId) {
    return res.status(400).json({ error: "You cannot follow yourself" });
  }

  try {

    // Check if already followed or requested
    const [existing] = await db.query(
      `SELECT * FROM follows 
       WHERE follower_id = ? AND following_id = ?`,
      [followerId, targetId]
    );

    if (existing.length > 0) {
      return res.status(400).json({ error: "Already followed/requested" });
    }

    // Check if target exists
    const [[targetUser]] = await db.query(
      `SELECT is_private FROM users WHERE id = ?`,
      [targetId]
    );

    if (!targetUser) {
      return res.status(404).json({ error: "User not found" });
    }

    const status = targetUser.is_private ? 'pending' : 'accepted';

    // Insert follow
    await db.query(
      `INSERT INTO follows (follower_id, following_id, status)
       VALUES (?, ?, ?)`,
      [followerId, targetId, status]
    );

    // Insert notification
    const notificationType = targetUser.is_private
      ? 'follow_request'
      : 'follow';

    await db.query(
      `INSERT INTO notifications (sender_id, receiver_id, type)
       VALUES (?, ?, ?)`,
      [followerId, targetId, notificationType]
    );

    res.json({
      message: status === 'pending'
        ? "Follow request sent"
        : "Started following"
    });

  } catch (err) {
    console.log("FOLLOW ERROR:", err);
    res.status(500).json({ error: "Server Error" });
  }
});


// ==========================================
// UNFOLLOW / REJECT REQUEST
// ==========================================
router.delete('/:id', verifyToken, async (req, res) => {

  const followerId = req.user.id;
  const targetId = parseInt(req.params.id);

  try {

    await db.query(
      `DELETE FROM follows
       WHERE follower_id = ? AND following_id = ?`,
      [followerId, targetId]
    );

    res.json({ message: "Unfollowed successfully" });

  } catch (err) {
    console.log("UNFOLLOW ERROR:", err);
    res.status(500).json({ error: "Server Error" });
  }
});


// ==========================================
// ACCEPT FOLLOW REQUEST
// ==========================================
router.post('/accept/:id', verifyToken, async (req, res) => {

  const currentUserId = req.user.id;
  const followerId = parseInt(req.params.id);

  try {

    const [result] = await db.query(
      `UPDATE follows
       SET status = 'accepted'
       WHERE follower_id = ? AND following_id = ?`,
      [followerId, currentUserId]
    );

    if (result.affectedRows === 0) {
      return res.status(404).json({ error: "Request not found" });
    }

    res.json({ message: "Follow request accepted" });

  } catch (err) {
    console.log("ACCEPT ERROR:", err);
    res.status(500).json({ error: "Server Error" });
  }
});


// ==========================================
// GET FOLLOW STATUS
// ==========================================
router.get('/status/:id', verifyToken, async (req, res) => {

  const followerId = req.user.id;
  const targetId = parseInt(req.params.id);

  try {

    const [rows] = await db.query(
      `SELECT status FROM follows
       WHERE follower_id = ? AND following_id = ?`,
      [followerId, targetId]
    );

    if (rows.length === 0) {
      return res.json({ status: "none" });
    }

    res.json({ status: rows[0].status });

  } catch (err) {
    console.log("FOLLOW STATUS ERROR:", err);
    res.status(500).json({ error: "Server Error" });
  }
});


// ==========================================
// GET FOLLOWERS
// ==========================================
router.get('/followers/:id', async (req, res) => {

  try {

    const [rows] = await db.query(
      `SELECT u.id, u.name
       FROM follows f
       JOIN users u ON f.follower_id = u.id
       WHERE f.following_id = ?
       AND f.status = 'accepted'`,
      [req.params.id]
    );

    res.json(rows);

  } catch (err) {
    console.log("GET FOLLOWERS ERROR:", err);
    res.status(500).json({ error: "Server Error" });
  }
});


// ==========================================
// GET FOLLOWING
// ==========================================
router.get('/following/:id', async (req, res) => {

  try {

    const [rows] = await db.query(
      `SELECT u.id, u.name
       FROM follows f
       JOIN users u ON f.following_id = u.id
       WHERE f.follower_id = ?
       AND f.status = 'accepted'`,
      [req.params.id]
    );

    res.json(rows);

  } catch (err) {
    console.log("GET FOLLOWING ERROR:", err);
    res.status(500).json({ error: "Server Error" });
  }
});

module.exports = router;