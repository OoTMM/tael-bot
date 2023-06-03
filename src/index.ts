import 'dotenv/config';

import { Client } from 'discord.js';

const client = new Client({
  intents: [
    'Guilds',
    'GuildMessages',
  ]
});

client.on('ready', (c) => {
  console.log(`Logged in as ${c.user?.tag}!`);
});

client.login(process.env.DISCORD_TOKEN);
