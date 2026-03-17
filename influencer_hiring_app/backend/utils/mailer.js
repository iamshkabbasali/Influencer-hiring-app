const nodemailer = require("nodemailer");

const transporter = nodemailer.createTransport({
  service: "gmail",
  auth: {
    user: "abcd@gmail.com", // Your Gmail address
    pass: "abcd1234" // Use an app password for Gmail
  }
});

module.exports = transporter;