import pgPromise from 'pg-promise';

const pgp = pgPromise({
  capSQL: true,
});

const db = pgp(process.env.DATABASE_URL!);

export default db;
