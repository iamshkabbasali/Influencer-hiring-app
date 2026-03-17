// routes/searchRoutes.js

const express = require('express');
const router = express.Router();
const db = require('../config/db');


// SEARCH USERS
router.get('/', async (req, res) => {

  const keyword = req.query.q;

  if (!keyword) {
    return res.json([]);
  }

  const [users] = await db.query(
    `SELECT id, name, bio
     FROM users
     WHERE name LIKE ?`,
    [`%${keyword}%`]
  );

  res.json(users);
});

module.exports = router;