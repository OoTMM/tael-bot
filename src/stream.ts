import { ChannelType, MessageCreateOptions as DiscordMessageCreateOptions, Message, MessageFlags, hyperlink, EmbedBuilder, Embed, Channel, SendableChannels } from 'discord.js';

import discordClient from './discord';
import { db, DatabaseTransaction } from './db';
import { getTwitchClient, TwitchStream, TwitchStreamsQuery } from './services/twitch';
import CONFIG from './config';

const GAME_IDS = {
  ZELDA_OOT: '11557',
  ZELDA_OOT_MQ: '15849',
  ZELDA_MM: '12482',
  RETRO: '27284',
  GAME_DEV: '1469308723',
}

function isComboStream(stream: TwitchStream) {
  const isGameZelda = stream.game_id === GAME_IDS.ZELDA_OOT || stream.game_id === GAME_IDS.ZELDA_OOT_MQ || stream.game_id === GAME_IDS.ZELDA_MM;

  if (stream.title.match(/\b(ootr?|zootr)(x|\+| )?mmr?\b/i)) {
    return true;
  }

  if (isGameZelda && stream.title.match(/\bcombo rando(mizer)?\b/i)) {
    return true;
  }

  return false;
}

function zeroPad(num: number, places: number) {
  return String(num).padStart(places, '0');
}

function durationString(timeInSeconds: number) {
  const hours = Math.floor(timeInSeconds / 3600);
  const minutes = Math.floor((timeInSeconds % 3600) / 60);
  const seconds = Math.floor(timeInSeconds % 60);

  if (hours > 0) {
    return `${zeroPad(hours, 2)}:${zeroPad(minutes, 2)}:${zeroPad(seconds, 2)}`;
  } else {
    return `${minutes}:${zeroPad(seconds, 2)}`;
  }
}

function streamEmbed(stream: TwitchStream): EmbedBuilder {
  const url = `https://www.twitch.tv/${stream.user_name}`;
  const cacheBustKey = Math.floor(Date.now() / (1000 * 60 * 5));
  const thumbnail_url_raw = stream.thumbnail_url.replace('{width}', '640').replace('{height}', '360');
  const thumbnail_url = `${thumbnail_url_raw}&_t_cache=${cacheBustKey}`;
  const streamDateStart = new Date(stream.started_at);
  const streamDateCurrent = new Date();
  const durationSeconds = (streamDateCurrent.getTime() - streamDateStart.getTime()) / 1000;
  const embed = new EmbedBuilder()
    .setURL(url)
    .setAuthor({ name: stream.user_name, url: url })
    .setTitle(stream.title)
    .setFooter({ text: `Viewers: ${stream.viewer_count} \u2022 Duration: ${durationString(durationSeconds)} \u2022 Language: ${stream.language}` })
    .setImage(thumbnail_url);

  return embed;
}

type StoredTwitchStream = {
  id: string;
  user_id: string;
  discord_message_id: string;
  updated_at: Date;
}

class StreamSystem {
  private stopped: boolean;
  private timeoutHandle: NodeJS.Timeout | null;

  constructor() {
    this.stopped = false;
    this.timeoutHandle = null;
  }

  start() {
    this.tick();
  }

  stop() {
    this.stopped = true;
    if (this.timeoutHandle) {
      clearTimeout(this.timeoutHandle);
      this.timeoutHandle = null;
    }
  }

  private async tick() {
    try {
      await this.tickImpl();
    } catch (e) {
      console.error(e);
    } finally {
      if (!this.stopped) {
        this.timeoutHandle = setTimeout(() => this.tick(), 1000 * 60);
      }
    }
  }

  private async handleTwitchStreamNewMessage(tx: DatabaseTransaction, channel: SendableChannels, stream: TwitchStream) {
    const msg = await channel.send({ embeds: [streamEmbed(stream)], flags: MessageFlags.SuppressNotifications });
    await tx.none('INSERT INTO streams_twitch (id, user_id, discord_message_id) VALUES ($1, $2, $3)', [stream.id, stream.user_id, msg.id]);
  }

  private async handleTwitchStreamUpdateMessage(tx: DatabaseTransaction, channel: SendableChannels, stream: TwitchStream, storedStream: StoredTwitchStream) {
    return Promise.all([
      channel.messages.fetch(storedStream.discord_message_id).catch((x) => null).then((msg) => msg && msg.edit({ embeds: [streamEmbed(stream)] })),
      tx.none('UPDATE streams_twitch SET updated_at = NOW() WHERE id = $1', [stream.id]),
    ]);
  }

  private async handleTwitchStreams(streams: TwitchStream[]) {
    if (streams.length === 0) return;

    const discordChannel = await discordClient.channels.fetch(CONFIG.discord.twitchChannel);
    if (!discordChannel) {
      console.error('Stream integration: Failed to fetch discord channel');
      return;
    }
    if (discordChannel.type !== ChannelType.GuildText) {
      console.error('Stream integration: Discord channel is not a text channel');
      return;
    }

    /* Start a transaction */
    await db.tx(async (tx) => {
      const promises: Promise<any>[] = [];

      /* Check which streams are banned */
      const bannedUserIds = await tx.manyOrNone<{ user_id: string }>('SELECT user_id FROM streams_twitch_blacklist WHERE user_id = ANY($1)', [streams.map(x => x.user_id)]);
      const bannedUserIdsSet = new Set(bannedUserIds.map(x => x.user_id));

      /* Check which streams already existed */
      const rawStoredExistingStreams = await tx.manyOrNone<StoredTwitchStream>('SELECT * FROM streams_twitch WHERE id = ANY($1) FOR UPDATE', [streams.map(x => x.id)]);
      const storedExistingStreamsMap = new Map(rawStoredExistingStreams.map(x => [x.id, x]));

      for (const s of streams) {
        if (bannedUserIdsSet.has(s.user_id)) {
          continue;
        }

        const storedStream = storedExistingStreamsMap.get(s.id);
        if (!storedStream) {
          /* Create the stream */
          promises.push(this.handleTwitchStreamNewMessage(tx, discordChannel, s));
        } else {
          /* Update the stream */
          promises.push(this.handleTwitchStreamUpdateMessage(tx, discordChannel, s, storedStream));
        }
      }

      await Promise.all(promises);
    });
  }

  private async pollTwitch() {
    const data: TwitchStream[] = [];
    const seen = new Set<string>();
    const twitch = await getTwitchClient();
    let params: TwitchStreamsQuery = {
      type: 'live',
      game_id: [
        GAME_IDS.ZELDA_OOT,
        GAME_IDS.ZELDA_OOT_MQ,
        GAME_IDS.ZELDA_MM,
        GAME_IDS.RETRO,
        GAME_IDS.GAME_DEV,
      ],
      first: 100,
    }

    for (;;) {
      const streams = await twitch.streams(params);
      if (streams.data.length === 0) {
        break;
      }
      params.after = streams.pagination.cursor;

      for (const stream of streams.data) {
        if (seen.has(stream.id)) {
          continue;
        }
        if (isComboStream(stream)) {
          data.push(stream);
          seen.add(stream.id);
        }
      }
    }

    await this.handleTwitchStreams(data);
  }

  private async checkExpiredTwitch() {
    const channel = await discordClient.channels.fetch(CONFIG.discord.twitchChannel);
    if (!channel) {
      console.error('Stream integration: Failed to fetch discord channel');
      return;
    }
    if (channel.type !== ChannelType.GuildText) {
      console.error('Stream integration: Discord channel is not a text channel');
      return;
    }

    await db.tx(async (tx) => {
      const expired = await tx.manyOrNone<{ id: string, discord_message_id: string }>("SELECT id, discord_message_id FROM streams_twitch WHERE updated_at < (NOW() - '3 minutes'::interval) FOR UPDATE");
      await Promise.all(expired.map(async (ex) => {
        let discordMsg: Message | null;
        try {
          discordMsg = await channel.messages.fetch(ex.discord_message_id);
        } catch (e) {
          discordMsg = null;
        }

        if (discordMsg) {
          await discordMsg.delete();
        }

        await tx.none('DELETE FROM streams_twitch WHERE id = $1', [ex.id]);
      }));
    });
  }

  private async tickImpl() {
    await this.pollTwitch();
    await this.checkExpiredTwitch();
  }

  async blacklist(username: string) {
    /* Fetch the ID from twitch */
    const twitch = await getTwitchClient();
    const userQuery = await twitch.users({ login: username });
    const user = userQuery.data[0];
    if (!user) {
      throw new Error('User not found');
    }

    /* Ban */
    await db.none(`
      INSERT INTO streams_twitch_blacklist (user_id, user_login)
      VALUES ($1, $2)
      ON CONFLICT (user_id)
      DO UPDATE SET user_login = EXCLUDED.user_login
    `, [user.id, user.login]);

    /* Force expire */
    await db.none("UPDATE streams_twitch SET updated_at = (NOW() - '12 hours'::interval) WHERE user_id = $1", [user.id]);
    await this.checkExpiredTwitch();
  }

  async unblacklist(username: string) {
    await db.none('DELETE FROM streams_twitch_blacklist WHERE user_login = $1', [username]);
  }
}

const streamSystem = new StreamSystem();
export default streamSystem;
