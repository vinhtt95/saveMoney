import mysql from 'mysql2/promise';

export const pool = mysql.createPool({
  host: 'localhost',
  user: 'root',
  password: '123@123a',
  database: 'savemoney_db',
  waitForConnections: true,
  connectionLimit: 10,
  dateStrings: true, // Return DATE columns as 'YYYY-MM-DD' strings
});
