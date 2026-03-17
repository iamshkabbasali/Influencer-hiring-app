const db = require('../config/db');

// ======================
// SEND MESSAGE
// ======================
exports.sendMessage = (req, res) => {

  const sender_id = parseInt(req.user.id);
  const receiver_id = parseInt(req.body.receiver_id);

  if (!receiver_id) {
    return res.status(400).json({ error: "Receiver ID missing" });
  }

  let message = req.body.message || '';
  let type = 'text';
  let filePath = null;

  if (req.file) {
    type = 'image';
    message = '';
    filePath = req.file.path.replace(/\\/g, '/');
  }

  const sql = `
    INSERT INTO messages 
    (sender_id, receiver_id, message, type, file) 
    VALUES (?, ?, ?, ?, ?)
  `;

  db.query(sql, [sender_id, receiver_id, message, type, filePath], (err) => {
    if (err) {
      console.error("SEND MESSAGE ERROR:", err);
      return res.status(500).json({ error: "Server Error" });
    }

    res.status(201).json({ message: "Message sent successfully" });
  });
};


// ======================
// GET CONVERSATION
// ======================
exports.getConversation = (req, res) => {

  const myId = parseInt(req.user.id);
  const otherId = parseInt(req.params.userId);

  const sql = `
    SELECT * FROM messages
    WHERE 
      (sender_id = ? AND receiver_id = ?)
      OR
      (sender_id = ? AND receiver_id = ?)
    ORDER BY created_at ASC
  `;

  db.query(sql, [myId, otherId, otherId, myId], (err, results) => {
    if (err) {
      console.error("GET CONVERSATION ERROR:", err);
      return res.status(500).json({ error: "Server Error" });
    }

    res.json(results);
  });
};


// ======================
// GET CHAT LIST
// ======================
exports.getChatList = (req, res) => {

  const myId = req.user.id;

  const sql = `
    SELECT 
      users.id AS user_id,
      users.name,
      MAX(messages.created_at) AS last_time,
      SUBSTRING_INDEX(
        GROUP_CONCAT(messages.message ORDER BY messages.created_at DESC),
        ',', 1
      ) AS last_message
    FROM messages
    JOIN users 
      ON (
        (users.id = messages.sender_id AND messages.receiver_id = ?)
        OR
        (users.id = messages.receiver_id AND messages.sender_id = ?)
      )
    WHERE users.id != ?
    GROUP BY users.id
    ORDER BY last_time DESC
  `;

  db.query(sql, [myId, myId, myId], (err, results) => {
    if (err) {
      console.error("GET CHAT LIST ERROR:", err);
      return res.status(500).json({ error: "Server Error" });
    }

    res.json(results);
  });
};