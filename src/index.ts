import discord from './discord';
import './services/twitch';
import { getStreamSystem } from './stream';

const streamSystem = getStreamSystem();

function shutdown() {
  console.log('Shutting down...');

  try {
    streamSystem.stop();
    discord.destroy();
  } catch (e) {
    console.error(e);
    process.exit(1);
  }
}

process.on('SIGINT', shutdown);
process.on('SIGTERM', shutdown);

streamSystem.start();
