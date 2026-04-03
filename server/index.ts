import cors from 'cors';
import express from 'express';
import { pool } from './db.js';
import { router as accounts } from './routes/accounts.js';
import { router as budgets } from './routes/budgets.js';
import { router as categories } from './routes/categories.js';
import { router as goldAssets } from './routes/goldAssets.js';
import { router as goldPrices } from './routes/goldPrices.js';
import { router as init } from './routes/init.js';
import { router as settings } from './routes/settings.js';
import { router as transactions } from './routes/transactions.js';

const app = express();

app.use(cors({ origin: 'http://localhost:3000' }));
app.use(express.json({ limit: '10mb' }));

app.use('/api', init);
app.use('/api', categories);
app.use('/api', accounts);
app.use('/api', transactions);
app.use('/api', budgets);
app.use('/api', goldAssets);
app.use('/api', goldPrices);
app.use('/api', settings);

// Global error handler
app.use((err: any, _req: express.Request, res: express.Response, _next: express.NextFunction) => {
  console.error(err);
  res.status(500).json({ error: err.message });
});

const PORT = 3001;
const server = app.listen(PORT, () => {
  console.log(`saveMoney API server running on http://localhost:${PORT}`);
});

server.on('error', (err: NodeJS.ErrnoException) => {
  if (err.code === 'EADDRINUSE') {
    console.error(`Port ${PORT} is already in use. Run: lsof -ti:${PORT} | xargs kill -9`);
    process.exit(1);
  }
  throw err;
});

async function shutdown() {
  server.close();
  await pool.end();
  process.exit(0);
}

process.on('SIGINT', shutdown);
process.on('SIGTERM', shutdown);
