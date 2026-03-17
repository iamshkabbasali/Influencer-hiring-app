const db = require('../config/db');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const nodemailer = require('nodemailer');


// ===================================
// REGISTER
// ===================================
exports.register = async (req, res) => {
    try {

        const { name, email, password, role } = req.body;

        const checkUser = "SELECT * FROM users WHERE email = ?";

        db.query(checkUser, [email], async (err, result) => {

            if (err) return res.status(500).json({ error: err });

            if (result.length > 0) {
                return res.status(400).json({
                    message: "Email already exists"
                });
            }

            const hashedPassword = await bcrypt.hash(password, 10);

            const insertUser = `
                INSERT INTO users (name, email, password, role)
                VALUES (?, ?, ?, ?)
            `;

            db.query(
                insertUser,
                [name, email, hashedPassword, role],
                (err, result) => {

                    if (err)
                        return res.status(500).json({ error: err });

                    res.status(201).json({
                        message: "User registered successfully ✅"
                    });

                }
            );

        });

    } catch (error) {

        res.status(500).json({
            error: error.message
        });

    }
};


// ===================================
// LOGIN
// ===================================
exports.login = (req, res) => {

    const { email, password } = req.body;

    const findUser = "SELECT * FROM users WHERE email = ?";

    db.query(findUser, [email], async (err, results) => {

        if (err)
            return res.status(500).json({ error: err });

        if (results.length === 0) {

            return res.status(400).json({
                message: "User not found"
            });

        }

        const user = results[0];

        const isMatch = await bcrypt.compare(
            password,
            user.password
        );

        if (!isMatch) {

            return res.status(400).json({
                message: "Invalid password"
            });

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

    });

};


// ===================================
// FORGOT PASSWORD (SMTP)
// ===================================
exports.forgotPassword = async (req, res) => {

    const { email } = req.body;

    try {

        const findUser = "SELECT * FROM users WHERE email = ?";

        db.query(findUser, [email], async (err, result) => {

            if (err)
                return res.status(500).json({ error: err });

            if (result.length === 0) {

                return res.status(404).json({
                    message: "Email not registered"
                });

            }

            const transporter = nodemailer.createTransport({

                service: "gmail",

                auth: {
                    user: "abcd@gmail.com", // Your Gmail address
                    pass: "abcdefghijklmnop" // Use an app password for Gmail
                }

            });

            const mailOptions = {

                from: "abcd@gmail.com", // Your Gmail address

                to: email,

                subject: "Password Reset Request",

                text:
                    "Someone requested to reset your password. If it wasn't you please ignore this email."

            };

            transporter.sendMail(mailOptions, (error, info) => {

                if (error) {

                    return res.status(500).json({
                        error: "Email sending failed"
                    });

                }

                res.json({
                    message: "Password reset email sent successfully 📧"
                });

            });

        });

    } catch (error) {

        res.status(500).json({
            error: error.message
        });

    }

};