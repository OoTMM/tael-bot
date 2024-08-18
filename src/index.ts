import discord from './discord';

function shutdown() {
  console.log('Shutting down...');

  try {
    discord.destroy();
  } catch (e) {
    console.error(e);
    process.exit(1);
  }
}

process.on('SIGINT', shutdown);
process.on('SIGTERM', shutdown);
