const express = require('express');
const router = express.Router();
const db = require('../config/db');
const { verifyToken } = require('../middleware/authMiddleware');


// ==========================================
// GET MY NOTIFICATIONS
// ==========================================
router.get('/', verifyToken, async (req, res) => {

  try {

    const [rows] = await db.query(
      `SELECT n.*, u.name AS sender_name
       FROM notifications n
       JOIN users u ON n.sender_id = u.id
       WHERE n.receiver_id = ?
       ORDER BY n.id DESC`,
      [req.user.id]
    );

    res.json(rows);

  } catch (err) {
    console.log("NOTIFICATION ERROR:", err);
    res.status(500).json({ error: "Server Error" });
  }
});


// ==========================================
// MARK AS READ
// ==========================================
router.post('/read/:id', verifyToken, async (req, res) => {

  try {

    await db.query(
      `UPDATE notifications 
       SET is_read = TRUE 
       WHERE id = ?`,
      [req.params.id]
    );

    res.json({ message: "Notification marked as read" });

  } catch (err) {
    console.log("MARK READ ERROR:", err);
    res.status(500).json({ error: "Server Error" });
  }
});


// ==========================================
// DELETE NOTIFICATION (after accept/reject)
// ==========================================
router.delete('/:id', verifyToken, async (req, res) => {

  try {

    await db.query(
      `DELETE FROM notifications 
       WHERE id = ? AND receiver_id = ?`,
      [req.params.id, req.user.id]
    );

    res.json({ message: "Notification removed" });

  } catch (err) {
    console.log("DELETE NOTIFICATION ERROR:", err);
    res.status(500).json({ error: "Server Error" });
  }
});


module.exports = router;