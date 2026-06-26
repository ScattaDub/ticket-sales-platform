import 'dotenv/config';
import { Pool } from 'pg';
import PDFDocument from 'pdfkit';
import { createWriteStream } from "node:fs";

const pool = new Pool({
    host: process.env.DB_HOST,
    port: Number(process.env.DB_PORT),
    database: process.env.DB_NAME,
    user: process.env.DB_USER,
    password: String(process.env.DB_PASSWORD),
});

const generateTicketPDF = async () => {
    const client = await pool.connect();
    const code = process.argv.slice(2)[0] || 'XXXX';

    try {
        const result = await client.query(`
            SELECT t.code, e.title, u.full_name, issued_at FROM tickets t
            JOIN users u ON t.owner_id = u.id
            JOIN ticket_types tt ON t.ticket_type_id = tt.id
            JOIN events e ON tt.event_id = e.id
            WHERE code = $1
        `, [code]);
        const ticket = result.rows[0];

        if (!ticket) {
            console.error(`Ticket with code "${code}" not found`);
            return;
        }

        const doc = new PDFDocument();
        doc.pipe(createWriteStream(`./ticket-${code}.pdf`));

        doc.text(
            `Code: ${ticket.code}\n` +
            `Event: ${ticket.title}\n` +
            `Owner: ${ticket.full_name}\n` +
            `Issued: ${ticket.issued_at.toISOString().split('T')[0]}`
        );

        doc.end();
    } catch (error) {
        console.error(error);
    } finally {
        client.release();
    }
};

generateTicketPDF();