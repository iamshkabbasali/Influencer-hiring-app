const express = require('express');
const router = express.Router();
const db = require('../config/db');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const nodemailer = require('nodemailer');
const crypto = require('crypto');


// ===============================
// REGISTER
// ===============================
router.post('/register', async (req, res) => {

  const { name, email, password, role } = req.body;

  try {

    const hashedPassword = await bcrypt.hash(password, 10);

    await db.query(
      `INSERT INTO users (name, email, password, role)
       VALUES (?, ?, ?, ?)`,
      [name, email, hashedPassword, role]
    );

    res.status(201).json({ message: "User registered successfully" });

  } catch (err) {
    console.log("REGISTER ERROR:", err);
    res.status(500).json({ error: "Server Error" });
  }
});


// ===============================
// LOGIN
// ===============================
router.post('/login', async (req, res) => {

  const { email, password } = req.body;

  try {

    const [rows] = await db.query(
      `SELECT * FROM users WHERE email = ?`,
      [email]
    );

    if (rows.length === 0) {
      return res.status(400).json({ error: "Invalid credentials" });
    }

    const user = rows[0];

    const isMatch = await bcrypt.compare(password, user.password);

    if (!isMatch) {
      return res.status(400).json({ error: "Invalid credentials" });
    }

    const token = jwt.sign(
      { id: user.id, role: user.role },
      process.env.JWT_SECRET || "secretkey",
      { expiresIn: "1d" }
    );

    res.json({
      message: "Login successful ✅",
      token,
      user: {
        id: user.id,
        name: user.name,
        email: user.email,
        role: user.role
      }
    });

  } catch (err) {
    console.log("LOGIN ERROR:", err);
    res.status(500).json({ error: "Server Error" });
  }
});


// ===============================
// FORGOT PASSWORD
// ===============================
router.post('/forgot-password', async (req, res) => {

  const { email } = req.body;

  try {

    const [rows] = await db.query(
      `SELECT * FROM users WHERE email = ?`,
      [email]
    );

    if (rows.length === 0) {
      return res.status(404).json({
        message: "Email not registered"
      });
    }

    const user = rows[0];

    // Generate reset token
    const resetToken = crypto.randomBytes(32).toString("hex");

    // IMPORTANT FIX (add /api/auth)
    const resetLink =
      `http://localhost:5000/api/auth/reset-password/${resetToken}`;

    // Save token in database
    await db.query(
      `UPDATE users SET reset_token = ? WHERE id = ?`,
      [resetToken, user.id]
    );

    const transporter = nodemailer.createTransport({
      service: "gmail",
      auth: {
        user: "abcd@gmail.com", // Your Gmail address
        pass: "abcd1234" // Use an app password for Gmail
      }
    });

    const mailOptions = {
      from: "abcd@gmail.com", // Your Gmail address
      to: email,
      subject: "Reset Your Password",
      html: `
        <h3>Password Reset Request</h3>
        <p>Click the link below to reset your password:</p>
        <a href="${resetLink}">${resetLink}</a>
      `
    };

    await transporter.sendMail(mailOptions);

    res.json({
      message: "Password reset email sent 📧"
    });

  } catch (err) {

    console.log("FORGOT PASSWORD ERROR:", err);

    res.status(500).json({
      error: "Server error"
    });

  }

});


// ===============================
// RESET PASSWORD PAGE
// ===============================
router.get('/reset-password/:token', (req, res) => {

  const { token } = req.params;

  res.send(`
    <html>
      <body style="font-family:Arial;text-align:center;margin-top:50px">

        <h2>Reset Password</h2>

        <form action="/api/auth/reset-password/${token}" method="POST">

          <input
            type="password"
            name="password"
            placeholder="Enter new password"
            required
            style="padding:10px;width:250px"
          />

          <br><br>

          <button style="padding:10px 20px">
            Reset Password
          </button>

        </form>

      </body>
    </html>
  `);

});


// ===============================
// RESET PASSWORD API
// ===============================
router.post('/reset-password/:token', async (req, res) => {

  const { token } = req.params;
  const { password } = req.body;

  try {

    const [rows] = await db.query(
      `SELECT * FROM users WHERE reset_token = ?`,
      [token]
    );

    if (rows.length === 0) {
      return res.status(400).json({
        error: "Invalid or expired token"
      });
    }

    const user = rows[0];

    const hashedPassword = await bcrypt.hash(password, 10);

    await db.query(
      `UPDATE users 
       SET password = ?, reset_token = NULL
       WHERE id = ?`,
      [hashedPassword, user.id]
    );

    res.send("Password reset successful ✅");

  } catch (err) {

    console.log("RESET PASSWORD ERROR:", err);

    res.status(500).json({
      error: "Server error"
    });

  }

});

module.exports = router;