const db = require('../config/db');

// =======================
// CREATE CAMPAIGN (Brand)
// =======================
exports.createCampaign = (req, res) => {

    if (req.user.role !== 'brand') {
        return res.status(403).json({ error: "Only brands can create campaigns" });
    }

    const { title, description } = req.body;
    const brandId = req.user.id;

    const sql = `
        INSERT INTO campaigns (brand_id, title, description)
        VALUES (?, ?, ?)
    `;

    db.query(sql, [brandId, title, description], (err, result) => {
        if (err) {
            console.error("CREATE CAMPAIGN ERROR:", err);
            return res.status(500).json({ error: "Server Error" });
        }

        res.status(201).json({
            message: "Campaign created successfully",
            campaignId: result.insertId
        });
    });
};


// =======================
// GET ALL CAMPAIGNS (Influencer)
// =======================
exports.getAllCampaigns = (req, res) => {

    const sql = `
        SELECT campaigns.*, users.name AS brand_name
        FROM campaigns
        JOIN users ON campaigns.brand_id = users.id
        ORDER BY campaigns.created_at DESC
    `;

    db.query(sql, (err, results) => {
        if (err) {
            console.error("GET ALL CAMPAIGNS ERROR:", err);
            return res.status(500).json({ error: "Server Error" });
        }

        res.json(results);
    });
};


// =======================
// GET MY CAMPAIGNS (Brand)
// =======================
exports.getMyCampaigns = (req, res) => {

    if (req.user.role !== 'brand') {
        return res.status(403).json({ error: "Unauthorized" });
    }

    const brandId = req.user.id;

    const sql = `
        SELECT * FROM campaigns
        WHERE brand_id = ?
        ORDER BY created_at DESC
    `;

    db.query(sql, [brandId], (err, results) => {
        if (err) {
            console.error("GET MY CAMPAIGNS ERROR:", err);
            return res.status(500).json({ error: "Server Error" });
        }

        res.json(results);
    });
};


// =======================
// APPLY CAMPAIGN (Influencer)
// =======================
exports.applyCampaign = (req, res) => {

    if (req.user.role !== 'influencer') {
        return res.status(403).json({ error: "Only influencers can apply" });
    }

    const influencerId = req.user.id;
    const campaignId = req.params.campaignId;

    const sql = `
        INSERT INTO applications (campaign_id, influencer_id, status)
        VALUES (?, ?, 'pending')
    `;

    db.query(sql, [campaignId, influencerId], (err, result) => {
        if (err) {
            console.error("APPLY ERROR:", err);
            return res.status(500).json({ error: "Server Error" });
        }

        res.status(201).json({
            message: "Applied successfully"
        });
    });
};


// =======================
// GET APPLICANTS (Brand)
// =======================
exports.getApplicants = (req, res) => {

    if (req.user.role !== 'brand') {
        return res.status(403).json({ error: "Unauthorized" });
    }

    const campaignId = req.params.campaignId;

    const sql = `
        SELECT applications.id AS application_id,
               users.name,
               users.email,
               applications.status
        FROM applications
        JOIN users ON applications.influencer_id = users.id
        WHERE applications.campaign_id = ?
    `;

    db.query(sql, [campaignId], (err, results) => {
        if (err) {
            console.error("GET APPLICANTS ERROR:", err);
            return res.status(500).json({ error: "Server Error" });
        }

        res.json(results);
    });
};


// =======================
// UPDATE APPLICATION STATUS (Brand)
// =======================
exports.updateApplicationStatus = (req, res) => {

    if (req.user.role !== 'brand') {
        return res.status(403).json({ error: "Unauthorized" });
    }

    const applicationId = req.params.applicationId;
    const { status } = req.body;

    const sql = `
        UPDATE applications
        SET status = ?
        WHERE id = ?
    `;

    db.query(sql, [status, applicationId], (err, result) => {
        if (err) {
            console.error("UPDATE STATUS ERROR:", err);
            return res.status(500).json({ error: "Server Error" });
        }

        res.json({
            message: "Status updated successfully"
        });
    });
};