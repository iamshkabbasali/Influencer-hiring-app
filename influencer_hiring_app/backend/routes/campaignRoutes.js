const express = require('express');
const router = express.Router();
const db = require('../config/db');
const { verifyToken } = require('../middleware/authMiddleware');
const upload = require('../middleware/uploadMiddleware');


// =====================================================
// CREATE CAMPAIGN
// =====================================================
router.post('/create', verifyToken, upload.single('image'), async (req, res) => {

  const brandId = req.user.id;
  const { title, description, budget } = req.body;

  if (!title || !description) {
    return res.status(400).json({ error: "Title and description are required" });
  }

  try {

    let imagePath = null;

    if (req.file) {
      imagePath = req.file.path.replace(/\\/g, "/");
    }

    const [result] = await db.query(
      `INSERT INTO campaigns 
       (brand_id, title, description, budget, image, status)
       VALUES (?, ?, ?, ?, ?, 'active')`,
      [brandId, title, description, budget || null, imagePath]
    );

    res.status(201).json({
      message: "Campaign created successfully",
      campaignId: result.insertId
    });

  } catch (err) {
    console.error("CREATE CAMPAIGN ERROR:", err);
    res.status(500).json({ error: "Server Error" });
  }
});


// =====================================================
// ADD REVIEW
// =====================================================
router.post('/review', verifyToken, async (req, res) => {

  const { campaign_id, reviewee_id, rating, comment } = req.body;
  const reviewer_id = req.user.id;

  if (!campaign_id || !reviewee_id || !rating) {
    return res.status(400).json({ error: "Missing required fields" });
  }

  if (rating < 1 || rating > 5) {
    return res.status(400).json({ error: "Rating must be between 1 and 5" });
  }

  try {

    const [existing] = await db.query(
      `SELECT * FROM reviews 
       WHERE campaign_id = ? AND reviewer_id = ?`,
      [campaign_id, reviewer_id]
    );

    if (existing.length > 0) {
      return res.status(400).json({ error: "Already reviewed" });
    }

    await db.query(
      `INSERT INTO reviews 
       (campaign_id, reviewer_id, reviewee_id, rating, comment, created_at)
       VALUES (?, ?, ?, ?, ?, NOW())`,
      [campaign_id, reviewer_id, reviewee_id, rating, comment || null]
    );

    res.status(201).json({ message: "Review added successfully" });

  } catch (err) {
    console.error("REVIEW ERROR:", err);
    res.status(500).json({ error: "Server Error" });
  }
});


// =====================================================
// GET ALL REVIEWS FOR A USER (VISIBLE TO EVERYONE)
// =====================================================
router.get('/reviews/:revieweeId', async (req, res) => {

  const revieweeId = req.params.revieweeId;

  try {

    const [rows] = await db.query(
      `SELECT 
          r.id,
          r.campaign_id,
          r.rating,
          r.comment,
          r.created_at,
          u.name AS reviewer_name
       FROM reviews r
       JOIN users u ON r.reviewer_id = u.id
       WHERE r.reviewee_id = ?
       ORDER BY r.id DESC`,
      [revieweeId]
    );

    res.json(rows);

  } catch (err) {
    console.error("GET REVIEWS ERROR:", err);
    res.status(500).json({ error: "Server Error" });
  }
});


// =====================================================
// GET MY RATING
// =====================================================
router.get('/rating/me', verifyToken, async (req, res) => {

  const userId = req.user.id;

  try {

    const [rows] = await db.query(
      `SELECT 
         IFNULL(AVG(rating),0) AS average_rating,
         COUNT(*) AS total_reviews
       FROM reviews
       WHERE reviewee_id = ?`,
      [userId]
    );

    res.json(rows[0]);

  } catch (err) {
    res.status(500).json({ error: "Server Error" });
  }
});


// =====================================================
// GET USER RATING
// =====================================================
router.get('/rating/:userId', async (req, res) => {

  const userId = req.params.userId;

  try {

    const [rows] = await db.query(
      `SELECT 
         IFNULL(AVG(rating),0) AS average_rating,
         COUNT(*) AS total_reviews
       FROM reviews
       WHERE reviewee_id = ?`,
      [userId]
    );

    res.json(rows[0]);

  } catch (err) {
    res.status(500).json({ error: "Server Error" });
  }
});


// =====================================================
// GET ALL CAMPAIGNS (Influencer Feed)
// =====================================================
router.get('/all', verifyToken, async (req, res) => {

  const userId = req.user.id;

  try {

    const [rows] = await db.query(
      `SELECT 
        c.*,
        u.name AS brand_name,
        a.status AS application_status,
        IFNULL(r.avg_rating, 0) AS average_rating,
        IFNULL(r.total_reviews, 0) AS total_reviews
       FROM campaigns c
       JOIN users u ON c.brand_id = u.id
       LEFT JOIN applications a 
         ON a.campaign_id = c.id 
         AND a.influencer_id = ?
       LEFT JOIN (
         SELECT 
           reviewee_id,
           AVG(rating) AS avg_rating,
           COUNT(*) AS total_reviews
         FROM reviews
         GROUP BY reviewee_id
       ) r 
         ON r.reviewee_id = c.brand_id
       ORDER BY c.id DESC`,
      [userId]
    );

    res.json(rows);

  } catch (err) {
    console.error("GET ALL ERROR:", err);
    res.status(500).json({ error: "Server Error" });
  }
});


// =====================================================
// GET BRAND CAMPAIGNS
// =====================================================
router.get('/my', verifyToken, async (req, res) => {

  const brandId = req.user.id;

  try {

    const [rows] = await db.query(
      `SELECT c.*, 
        (SELECT COUNT(*) 
         FROM applications a 
         WHERE a.campaign_id = c.id) AS applicant_count
       FROM campaigns c
       WHERE c.brand_id = ?
       ORDER BY c.id DESC`,
      [brandId]
    );

    res.json(rows);

  } catch (err) {
    res.status(500).json({ error: "Server Error" });
  }
});


// =====================================================
// GET APPLICANTS
// =====================================================
router.get('/applications/:campaignId', verifyToken, async (req, res) => {

  const campaignId = req.params.campaignId;
  const brandId = req.user.id;

  try {

    const [campaign] = await db.query(
      `SELECT * FROM campaigns WHERE id = ? AND brand_id = ?`,
      [campaignId, brandId]
    );

    if (campaign.length === 0) {
      return res.status(403).json({ error: "Unauthorized access" });
    }

    const [rows] = await db.query(
      `SELECT 
          a.id,
          a.influencer_id,
          a.status,
          u.name,
          u.email
       FROM applications a
       JOIN users u ON a.influencer_id = u.id
       WHERE a.campaign_id = ?`,
      [campaignId]
    );

    res.json(rows);

  } catch (err) {
    res.status(500).json({ error: "Server Error" });
  }
});


// =====================================================
// APPLY TO CAMPAIGN
// =====================================================
router.post('/apply', verifyToken, async (req, res) => {

  const influencerId = req.user.id;
  const { campaign_id } = req.body;

  try {

    const [existing] = await db.query(
      `SELECT * FROM applications 
       WHERE campaign_id = ? AND influencer_id = ?`,
      [campaign_id, influencerId]
    );

    if (existing.length > 0) {
      return res.status(400).json({ error: "Already applied" });
    }

    await db.query(
      `INSERT INTO applications 
       (campaign_id, influencer_id, status)
       VALUES (?, ?, 'pending')`,
      [campaign_id, influencerId]
    );

    res.status(201).json({ message: "Applied successfully" });

  } catch (err) {
    res.status(500).json({ error: "Server Error" });
  }
});


// =====================================================
// GET MY APPLICATIONS
// =====================================================
router.get('/my-applications', verifyToken, async (req, res) => {

  const influencerId = req.user.id;

  try {

    const [rows] = await db.query(
      `SELECT 
         a.id,
         a.campaign_id,
         a.status,
         c.title,
         c.brand_id,
         u.name AS brand_name
       FROM applications a
       JOIN campaigns c ON a.campaign_id = c.id
       JOIN users u ON c.brand_id = u.id
       WHERE a.influencer_id = ?
       ORDER BY a.id DESC`,
      [influencerId]
    );

    res.json(rows);

  } catch (err) {
    res.status(500).json({ error: "Server Error" });
  }
});


// =====================================================
// UPDATE APPLICATION STATUS
// =====================================================
router.post('/update-status', verifyToken, async (req, res) => {

  const { application_id, status, campaign_id } = req.body;
  const brandId = req.user.id;

  try {

    const [campaign] = await db.query(
      `SELECT * FROM campaigns WHERE id = ? AND brand_id = ?`,
      [campaign_id, brandId]
    );

    if (campaign.length === 0) {
      return res.status(403).json({ error: "Unauthorized action" });
    }

    await db.query(
      `UPDATE applications SET status = ? WHERE id = ?`,
      [status, application_id]
    );

    if (status === 'accepted') {
      await db.query(
        `UPDATE campaigns SET status = 'closed' WHERE id = ?`,
        [campaign_id]
      );
    }

    res.json({ message: "Status updated successfully" });

  } catch (err) {
    res.status(500).json({ error: "Server Error" });
  }
});


// =====================================================
// DELETE CAMPAIGN
// =====================================================
router.delete('/delete/:id', verifyToken, async (req, res) => {

  const campaignId = req.params.id;
  const brandId = req.user.id;

  try {

    const [campaign] = await db.query(
      `SELECT * FROM campaigns WHERE id = ? AND brand_id = ?`,
      [campaignId, brandId]
    );

    if (campaign.length === 0) {
      return res.status(403).json({ error: "Unauthorized or not found" });
    }

    await db.query(`DELETE FROM applications WHERE campaign_id = ?`, [campaignId]);
    await db.query(`DELETE FROM campaigns WHERE id = ?`, [campaignId]);

    res.json({ message: "Campaign deleted successfully" });

  } catch (err) {
    res.status(500).json({ error: "Server Error" });
  }
});

module.exports = router;