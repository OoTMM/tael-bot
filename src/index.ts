import discord from './discord';
import './services/twitch';
import StreamSystem from './stream';

function shutdown() {
  console.log('Shutting down...');

  try {
    StreamSystem.stop();
    discord.destroy();
  } catch (e) {
    console.error(e);
    process.exit(1);
  }
}

process.on('SIGINT', shutdown);
process.on('SIGTERM', shutdown);

StreamSystem.start();
