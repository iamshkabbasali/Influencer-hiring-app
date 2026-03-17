const express = require('express');
const router = express.Router();
const db = require('../config/db');
const { verifyToken } = require('../middleware/authMiddleware');
const upload = require('../middleware/uploadMiddleware');


// ==========================================
// CREATE POST
// ==========================================
router.post('/', verifyToken, upload.single('image'), async (req, res) => {
  try {

    let imagePath = null;

    if (req.file) {
      imagePath = req.file.path.replace(/\\/g, "/");
    }

    await db.query(
      `INSERT INTO posts (user_id, caption, image)
       VALUES (?, ?, ?)`,
      [req.user.id, req.body.caption || null, imagePath]
    );

    res.json({ message: "Post created successfully" });

  } catch (err) {
    console.log("CREATE POST ERROR:", err);
    res.status(500).json({ error: "Server Error" });
  }
});


// ==========================================
// DELETE POST
// ==========================================
router.delete('/:postId', verifyToken, async (req, res) => {
  try {

    const postId = req.params.postId;

    const [rows] = await db.query(
      `SELECT * FROM posts WHERE id = ?`,
      [postId]
    );

    if (rows.length === 0) {
      return res.status(404).json({ error: "Post not found" });
    }

    if (rows[0].user_id !== req.user.id) {
      return res.status(403).json({ error: "Unauthorized" });
    }

    await db.query(
      `DELETE FROM posts WHERE id = ?`,
      [postId]
    );

    res.json({ message: "Post deleted successfully" });

  } catch (err) {
    console.log("DELETE POST ERROR:", err);
    res.status(500).json({ error: "Server Error" });
  }
});


// ==========================================
// GET USER POSTS (PRIVATE ACCOUNT LOGIC)
// ==========================================
router.get('/user/:userId', verifyToken, async (req, res) => {
  try {

    const targetId = req.params.userId;
    const viewerId = req.user.id;

    const [[user]] = await db.query(
      `SELECT is_private FROM users WHERE id = ?`,
      [targetId]
    );

    if (!user) {
      return res.status(404).json({ error: "User not found" });
    }

    if (user.is_private && viewerId != targetId) {

      const [follow] = await db.query(
        `SELECT * FROM follows
         WHERE follower_id = ?
         AND following_id = ?
         AND status = 'accepted'`,
        [viewerId, targetId]
      );

      if (follow.length === 0) {
        return res.status(403).json({ error: "Private account" });
      }
    }

    const [posts] = await db.query(
      `SELECT p.*, 
        (SELECT COUNT(*) FROM post_likes WHERE post_id = p.id) AS like_count
       FROM posts p
       WHERE p.user_id = ?
       ORDER BY p.id DESC`,
      [targetId]
    );

    res.json(posts);

  } catch (err) {
    console.log("GET USER POSTS ERROR:", err);
    res.status(500).json({ error: "Server Error" });
  }
});


// ==========================================
// FEED (POSTS FROM FOLLOWING)
// ==========================================
router.get('/feed/me', verifyToken, async (req, res) => {
  try {

    const [posts] = await db.query(
      `SELECT p.*, u.name,
       (SELECT COUNT(*) FROM post_likes WHERE post_id = p.id) AS like_count
       FROM posts p
       JOIN users u ON p.user_id = u.id
       WHERE p.user_id IN (
          SELECT following_id
          FROM follows
          WHERE follower_id = ?
          AND status = 'accepted'
       )
       ORDER BY p.id DESC`,
      [req.user.id]
    );

    res.json(posts);

  } catch (err) {
    console.log("FEED ERROR:", err);
    res.status(500).json({ error: "Server Error" });
  }
});


// ==========================================
// EXPLORE (PUBLIC POSTS)
// ==========================================
router.get('/explore', async (req, res) => {
  try {

    const [posts] = await db.query(
      `SELECT p.*, u.name,
       (SELECT COUNT(*) FROM post_likes WHERE post_id = p.id) AS like_count
       FROM posts p
       JOIN users u ON p.user_id = u.id
       ORDER BY p.id DESC
       LIMIT 20`
    );

    res.json(posts);

  } catch (err) {
    console.log("EXPLORE ERROR:", err);
    res.status(500).json({ error: "Server Error" });
  }
});


// ==========================================
// TOGGLE LIKE
// ==========================================
router.post('/like/:postId', verifyToken, async (req, res) => {
  try {

    const postId = req.params.postId;
    const userId = req.user.id;

    const [existing] = await db.query(
      `SELECT id FROM post_likes 
       WHERE post_id = ? AND user_id = ?`,
      [postId, userId]
    );

    if (existing.length > 0) {

      await db.query(
        `DELETE FROM post_likes
         WHERE post_id = ? AND user_id = ?`,
        [postId, userId]
      );

      const [[count]] = await db.query(
        `SELECT COUNT(*) AS like_count
         FROM post_likes WHERE post_id = ?`,
        [postId]
      );

      return res.json({
        liked: false,
        like_count: count.like_count
      });
    }

    await db.query(
      `INSERT INTO post_likes (post_id, user_id)
       VALUES (?, ?)`,
      [postId, userId]
    );

    const [[count]] = await db.query(
      `SELECT COUNT(*) AS like_count
       FROM post_likes WHERE post_id = ?`,
      [postId]
    );

    res.json({
      liked: true,
      like_count: count.like_count
    });

  } catch (err) {
    console.log("LIKE ERROR:", err);
    res.status(500).json({ error: "Server Error" });
  }
});


// ==========================================
// GET LIKE STATUS
// ==========================================
router.get('/:postId/like-status', verifyToken, async (req, res) => {
  try {

    const postId = req.params.postId;
    const userId = req.user.id;

    const [[like]] = await db.query(
      `SELECT id FROM post_likes
       WHERE post_id = ? AND user_id = ?`,
      [postId, userId]
    );

    const [[count]] = await db.query(
      `SELECT COUNT(*) AS like_count
       FROM post_likes
       WHERE post_id = ?`,
      [postId]
    );

    res.json({
      is_liked: !!like,
      like_count: count.like_count
    });

  } catch (err) {
    console.log("LIKE STATUS ERROR:", err);
    res.status(500).json({ error: "Server Error" });
  }
});


// ==========================================
// ADD COMMENT
// ==========================================
router.post('/comment/:postId', verifyToken, async (req, res) => {
  try {

    const { text } = req.body;

    if (!text || text.trim() === "") {
      return res.status(400).json({ error: "Comment empty" });
    }

    await db.query(
      `INSERT INTO comments (post_id, user_id, text)
       VALUES (?, ?, ?)`,
      [req.params.postId, req.user.id, text]
    );

    const [[comment]] = await db.query(
      `SELECT c.*, u.name
       FROM comments c
       JOIN users u ON c.user_id = u.id
       WHERE c.post_id = ?
       ORDER BY c.id DESC
       LIMIT 1`,
      [req.params.postId]
    );

    res.json(comment);

  } catch (err) {
    console.log("COMMENT ERROR:", err);
    res.status(500).json({ error: "Server Error" });
  }
});


// ==========================================
// GET COMMENTS
// ==========================================
router.get('/comments/:postId', async (req, res) => {
  try {

    const [rows] = await db.query(
      `SELECT c.*, u.name
       FROM comments c
       JOIN users u ON c.user_id = u.id
       WHERE c.post_id = ?
       ORDER BY c.id DESC`,
      [req.params.postId]
    );

    res.json(rows);

  } catch (err) {
    console.log("GET COMMENTS ERROR:", err);
    res.status(500).json({ error: "Server Error" });
  }
});

module.exports = router;