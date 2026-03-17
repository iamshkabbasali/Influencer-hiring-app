const mysql = require('mysql2/promise');
require('dotenv').config();

const db = mysql.createPool({
  host: 'localshost',
  user: 'r0oot',
  password: '',
  database: 'influencer_app'
});

module.exports = db;