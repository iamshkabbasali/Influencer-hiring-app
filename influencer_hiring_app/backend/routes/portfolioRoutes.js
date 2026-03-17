const express = require('express');
const router = express.Router();
const db = require('../config/db');
const { verifyToken } = require('../middleware/authMiddleware');
const multer = require('multer');
const path = require('path');
const fs = require('fs');

// ==========================================
// MULTER CONFIG
// ==========================================

const uploadDir = path.join(__dirname, '../uploads/portfolio');

if (!fs.existsSync(uploadDir)) {
  fs.mkdirSync(uploadDir, { recursive: true });
}

const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    cb(null, uploadDir);
  },
  filename: function (req, file, cb) {
    const uniqueName =
      Date.now() + '-' + file.originalname.replace(/\s/g, '_');
    cb(null, uniqueName);
  },
});

const upload = multer({ storage });

// ==========================================
// UPLOAD PORTFOLIO
// ==========================================

router.post(
  '/',
  verifyToken,
  upload.single('file'),
  async (req, res) => {
    try {
      const { title, description } = req.body;

      if (!title || !req.file) {
        return res.status(400).json({
          error: 'Title and file are required',
        });
      }

      const fileUrl = `uploads/portfolio/${req.file.filename}`;

      await db.query(
        `INSERT INTO portfolios 
         (user_id, title, description, file_url)
         VALUES (?, ?, ?, ?)`,
        [
          req.user.id,
          title,
          description || null,
          fileUrl
        ]
      );

      res.status(201).json({
        message: 'Portfolio uploaded successfully',
        file_url: fileUrl
      });

    } catch (err) {
      console.log('UPLOAD PORTFOLIO ERROR:', err);
      res.status(500).json({ error: 'Server Error' });
    }
  }
);

// ==========================================
// GET USER PORTFOLIO
// ==========================================

router.get('/:userId', async (req, res) => {
  try {
    const userId = req.params.userId;

    const [rows] = await db.query(
      `SELECT id, title, description, file_url, created_at
       FROM portfolios
       WHERE user_id = ?
       ORDER BY id DESC`,
      [userId]
    );

    res.json(rows);

  } catch (err) {
    console.log('GET PORTFOLIO ERROR:', err);
    res.status(500).json({ error: 'Server Error' });
  }
});

// ==========================================
// DELETE PORTFOLIO
// ==========================================

router.delete('/:id', verifyToken, async (req, res) => {
  try {
    const portfolioId = req.params.id;

    const [[portfolio]] = await db.query(
      `SELECT * FROM portfolios WHERE id = ?`,
      [portfolioId]
    );

    if (!portfolio) {
      return res.status(404).json({
        error: 'Portfolio not found',
      });
    }

    if (portfolio.user_id !== req.user.id) {
      return res.status(403).json({
        error: 'Unauthorized',
      });
    }

    // Delete file from server
    const fullPath = path.join(
      __dirname,
      '../',
      portfolio.file_url
    );

    if (fs.existsSync(fullPath)) {
      fs.unlinkSync(fullPath);
    }

    await db.query(
      `DELETE FROM portfolios WHERE id = ?`,
      [portfolioId]
    );

    res.json({
      message: 'Portfolio deleted successfully',
    });

  } catch (err) {
    console.log('DELETE PORTFOLIO ERROR:', err);
    res.status(500).json({ error: 'Server Error' });
  }
});

module.exports = router;