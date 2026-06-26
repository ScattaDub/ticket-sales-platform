import 'dotenv/config';
import { Pool } from 'pg';
import QueryStream from 'pg-query-stream';
import { createWriteStream } from 'node:fs';
import { once } from 'node:events';
import { Transform } from 'node:stream';
import { pipeline } from 'node:stream/promises';


const pool = new Pool({
    host: process.env.DB_HOST,
    port: Number(process.env.DB_PORT),
    database: process.env.DB_NAME,
    user: process.env.DB_USER,
    password: String(process.env.DB_PASSWORD),
});

const csvField = (value: unknown): string => {
    const s = value == null ? '' : String(value);
    if (s.includes(',') || s.includes('"') || s.includes('\n')) {
        return '"' + s.replace(/"/g, '""') + '"';
    }
    return s;
}

const toCsvLine = (values: unknown[]): string => {
    return values.map(csvField).join(',') + '\n';
}

const exportDataToCSVWithEvents = async () => {
    const client = await pool.connect();
    const fileStream = createWriteStream('participants.csv');

    try {
        fileStream.write(toCsvLine(['code', 'full_name', 'email', 'title']));

        const query = new QueryStream(`
            SELECT t.code, u.full_name, u.email, e.title
            FROM tickets t
            JOIN users u ON t.owner_id = u.id
            JOIN ticket_types tt ON t.ticket_type_id = tt.id
            JOIN events e ON tt.event_id = e.id
            ORDER BY t.id
        `);
        const stream = client.query(query);

        let count = 0;
        for await (const row of stream) {
            const line = toCsvLine([row.code, row.full_name, row.email, row.title]);
            const ok = fileStream.write(line);

            if (!ok) {
                await once(fileStream, 'drain');
            }
            count++;
        }
        console.log(`Exported ${count} rows`);
    } catch (error) {
        console.error(error);
    } finally {
        client.release();
        fileStream.end();
    }
};


const exportDataToCSVWithStream = async () => {
    const client = await pool.connect();
    const fileStream = createWriteStream('participants.csv');

    try {
        const query = new QueryStream(`
            SELECT t.code, u.full_name, u.email, e.title
            FROM tickets t
            JOIN users u ON t.owner_id = u.id
            JOIN ticket_types tt ON t.ticket_type_id = tt.id
            JOIN events e ON tt.event_id = e.id
            ORDER BY t.id
        `);
        const stream = client.query(query);

        const toCSV = new Transform({
            objectMode: true,
            transform(row, _enc, callback) {
                callback(null, toCsvLine([row.code, row.full_name, row.email, row.title]));
            },
        });
        fileStream.write(toCsvLine(['code', 'full_name', 'email', 'title']));

        await pipeline(stream, toCSV, fileStream);

        console.log('Export done');
    } catch (error) {
        console.error(error);
    } finally {
        client.release();
        fileStream.end();
    }
};

exportDataToCSVWithStream();