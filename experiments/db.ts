import 'dotenv/config';
import { Pool } from 'pg';

const pool = new Pool({
    host: process.env.DB_HOST,
    port: Number(process.env.DB_PORT),
    database: process.env.DB_NAME,
    user: process.env.DB_USER,
    password: String(process.env.DB_PASSWORD),
});

const testConnection = async () => {
    try {
        const response = await pool.query('SELECT * FROM users');
        console.log('Database connection successful', response.rows);
    }
    catch (error) {
        console.error('Database connection failed', error);
    } finally {
        pool.end();
    }
};

testConnection();