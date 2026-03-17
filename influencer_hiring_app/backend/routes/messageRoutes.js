const express = require('express');
const router = express.Router();
const db = require('../config/db');
const { verifyToken } = require('../middleware/authMiddleware');
const upload = require('../middleware/uploadMiddleware');


// ================================
// SEND MESSAGE
// ================================
router.post(
  '/send',
  verifyToken,
  upload.single('file'),
  async (req, res) => {
    const senderId = req.user.id;
    const { receiver_id, message } = req.body;

    try {
      let type = 'text';
      let filePath = null;

      if (req.file) {
        type = 'image';
        filePath = req.file.path.replace(/\\/g, "/");
      }

      await db.query(
        `INSERT INTO messages (sender_id, receiver_id, message, type, file)
         VALUES (?, ?, ?, ?, ?)`,
        [
          senderId,
          receiver_id,
          message || null,
          type,
          filePath
        ]
      );

      res.status(201).json({ message: "Message sent successfully" });

    } catch (err) {
      console.log(err);
      res.status(500).json({ error: "Server Error" });
    }
  }
);


// ================================
// GET CONVERSATION
// ================================
router.get(
  '/conversation/:id',
  verifyToken,
  async (req, res) => {
    const userId = req.user.id;
    const otherUserId = req.params.id;

    try {
      const [rows] = await db.query(
        `SELECT * FROM messages
         WHERE 
           (sender_id = ? AND receiver_id = ?)
           OR
           (sender_id = ? AND receiver_id = ?)
         ORDER BY created_at ASC`,
        [
          userId,
          otherUserId,
          otherUserId,
          userId
        ]
      );

      res.json(rows);

    } catch (err) {
      console.log(err);
      res.status(500).json({ error: "Server Error" });
    }
  }
);


// ================================
// CHAT LIST
// ================================
router.get(
  '/chat-list',
  verifyToken,
  async (req, res) => {
    const userId = req.user.id;

    try {
      const [rows] = await db.query(
        `
        SELECT 
          u.id AS user_id,
          u.name,
          m.message AS last_message,
          m.created_at
        FROM messages m
        JOIN users u
          ON (u.id = m.sender_id AND m.receiver_id = ?)
          OR (u.id = m.receiver_id AND m.sender_id = ?)
        WHERE m.id IN (
          SELECT MAX(id)
          FROM messages
          WHERE sender_id = ? OR receiver_id = ?
          GROUP BY 
            CASE 
              WHEN sender_id = ? THEN receiver_id
              ELSE sender_id
            END
        )
        ORDER BY m.created_at DESC
        `,
        [userId, userId, userId, userId, userId]
      );

      res.json(rows);

    } catch (err) {
      console.log(err);
      res.status(500).json({ error: "Server Error" });
    }
  }
);

module.exports = router;