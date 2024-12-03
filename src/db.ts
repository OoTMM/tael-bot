import pgPromise from 'pg-promise';

const pgp = pgPromise({
  capSQL: true,
});

export const db = pgp(process.env.DATABASE_URL!);
export type DatabaseTransaction = Parameters<Parameters<typeof db.tx>[1]>[0];
