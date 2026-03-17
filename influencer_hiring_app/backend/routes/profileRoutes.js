const express = require('express');
const router = express.Router();
const db = require('../config/db');
const { verifyToken } = require('../middleware/authMiddleware');
const upload = require('../middleware/uploadMiddleware');


// ==========================================
// GET MY PROFILE
// ==========================================
router.get('/me', verifyToken, async (req, res) => {

  try {

    const [[user]] = await db.query(
      `SELECT id, name, bio, is_private, profile_picture
       FROM users
       WHERE id = ?`,
      [req.user.id]
    );

    res.json(user);

  } catch (err) {
    console.log("GET ME ERROR:", err);
    res.status(500).json({ error: "Server Error" });
  }

});


// ==========================================
// PROFILE SUMMARY
// ==========================================
router.get('/:userId', async (req, res) => {

  try {

    const userId = req.params.userId;

    const [[user]] = await db.query(
      `SELECT id, name, bio, is_private, profile_picture
       FROM users
       WHERE id = ?`,
      [userId]
    );

    if (!user) {
      return res.status(404).json({ error: "User not found" });
    }

    const [[followers]] = await db.query(
      `SELECT COUNT(*) AS count
       FROM follows
       WHERE following_id = ?
       AND status = 'accepted'`,
      [userId]
    );

    const [[following]] = await db.query(
      `SELECT COUNT(*) AS count
       FROM follows
       WHERE follower_id = ?
       AND status = 'accepted'`,
      [userId]
    );

    const [[posts]] = await db.query(
      `SELECT COUNT(*) AS count
       FROM posts
       WHERE user_id = ?`,
      [userId]
    );

    res.json({
      user,
      followers: followers.count || 0,
      following: following.count || 0,
      posts: posts.count || 0
    });

  } catch (err) {
    console.log("PROFILE SUMMARY ERROR:", err);
    res.status(500).json({ error: "Server Error" });
  }

});


// ==========================================
// UPDATE PROFILE (BIO + PRIVATE)
// ==========================================
router.put('/update', verifyToken, async (req, res) => {

  try {

    const { bio, is_private } = req.body;

    await db.query(
      `UPDATE users
       SET bio = ?, is_private = ?
       WHERE id = ?`,
      [
        bio || null,
        is_private ? 1 : 0,
        req.user.id
      ]
    );

    res.json({
      message: "Profile updated successfully"
    });

  } catch (err) {
    console.log("UPDATE PROFILE ERROR:", err);
    res.status(500).json({ error: "Server Error" });
  }

});


// ==========================================
// UPLOAD PROFILE PICTURE
// ==========================================
router.post(
  '/upload-avatar',
  verifyToken,
  upload.single('avatar'),
  async (req, res) => {

    try {

      if (!req.file) {
        return res
          .status(400)
          .json({ error: "No file uploaded" });
      }

      const imagePath =
        req.file.path.replace(/\\/g, "/");

      await db.query(
        `UPDATE users
         SET profile_picture = ?
         WHERE id = ?`,
        [imagePath, req.user.id]
      );

      res.json({
        message: "Avatar updated successfully",
        profile_picture: imagePath
      });

    } catch (err) {
      console.log("UPLOAD AVATAR ERROR:", err);
      res.status(500).json({ error: "Server Error" });
    }

  }
);


// ==========================================
// REMOVE PROFILE PICTURE
// ==========================================
router.delete('/remove-avatar', verifyToken, async (req, res) => {

  try {

    await db.query(
      `UPDATE users
       SET profile_picture = NULL
       WHERE id = ?`,
      [req.user.id]
    );

    res.json({
      message: "Avatar removed successfully"
    });

  } catch (err) {
    console.log("REMOVE AVATAR ERROR:", err);
    res.status(500).json({ error: "Server Error" });
  }

});


module.exports = router;