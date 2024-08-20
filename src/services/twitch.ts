import Axios, { AxiosInstance } from 'axios';

export type TwitchStream = {
  id: string;
  user_id: string;
  user_login: string;
  user_name: string;
  game_id: string;
  game_name: string;
  type: 'live';
  title: string;
  viewer_count: number;
  started_at: string;
  language: string;
  thumbnail_url: string;
  tag_ids: string[];
  tags: string[] | null;
  is_mature: boolean;
};

export type TwitchStreamsResponse = {
  data: TwitchStream[];
  pagination: {
    cursor: string;
  };
};

export type TwitchStreamsQuery = {
  type: 'live';
  first?: number;
  after?: string;
  before?: string;
  game_id?: string | string[];
};

export type TwitchUser = {
  id: string;
  login: string;
  display_name: string;
  type: string;
  broadcaster_type: string;
  description: string;
  profile_image_url: string;
  offline_image_url: string;
  view_count: number;
  email: string;
  created_at: Date;
};

export type TwitchUsersQuery = {
  id?: string | string[];
  login?: string | string[];
};

export type TwitchUsersResponse = {
  data: TwitchUser[];
};

class TwitchClient {
  private httpClient: AxiosInstance;
  private httpAuthClient: AxiosInstance;
  private token: Promise<string>;
  private tokenError: boolean;

  constructor() {
    this.httpClient = Axios.create({
      baseURL: 'https://api.twitch.tv/helix/',
      headers: {
        'Client-ID': process.env.TWITCH_CLIENT!,
      },
    });

    this.httpAuthClient = Axios.create({
      baseURL: 'https://id.twitch.tv/oauth2/'
    });

    this.tokenError = false;
    this.token = this.getToken();
    this.token.catch(() => { this.tokenError = true; });

    this.httpClient.interceptors.request.use(async (request) => {
      let tokenPromise = this.token;
      if (this.tokenError) {
        this.tokenError = false;
        tokenPromise = this.getToken();
        this.token = tokenPromise;
        tokenPromise.catch(() => { this.tokenError = true; });
      }

      const token = await tokenPromise;
      request.headers['Authorization'] = `Bearer ${token}`;

      return request;
    });

    this.httpClient.interceptors.response.use(response => response, async (error) => {
      if (error.status !== 401) {
        return Promise.reject(error);
      }

      const originalRequest = error.config;
      if (originalRequest.headers['X-Retry']) {
        return Promise.reject(error);
      }
      const tokenPromise = this.getToken();
      this.tokenError = false;
      this.token = tokenPromise;
      tokenPromise.catch(() => { this.tokenError = true; });
      const token = await tokenPromise;
      originalRequest.headers['Authorization'] = `Bearer ${token}`;
      originalRequest.headers['X-Retry'] = 1;
      return this.httpClient(originalRequest);
    });
  }

  private async getToken(): Promise<string> {
    const reply = await this.httpAuthClient.post('token', {
      client_id: process.env.TWITCH_CLIENT!,
      client_secret: process.env.TWITCH_SECRET!,
      grant_type: 'client_credentials',
    }, {
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
    });

    if (reply.status !== 200) {
      throw new Error('Failed to get twitch token, status: ' + reply.status);
    }

    return reply.data.access_token as string;
  }

  async streams(query: TwitchStreamsQuery): Promise<TwitchStreamsResponse> {
    const params = new URLSearchParams();
    if (query.type) {
      params.append('type', query.type);
    }
    if (query.after) {
      params.append('after', query.after);
    }
    if (query.before) {
      params.append('before', query.before);
    }
    if (query.game_id) {
      const gameIds = Array.isArray(query.game_id) ? query.game_id : [query.game_id];
      gameIds.forEach((gameId) => params.append('game_id', gameId));
    }

    const response = await this.httpClient.get<TwitchStreamsResponse>('streams', { params });
    return response.data;
  }

  async users(query: TwitchUsersQuery): Promise<TwitchUsersResponse> {
    const params = new URLSearchParams();
    if (query.id) {
      const ids = Array.isArray(query.id) ? query.id : [query.id];
      ids.forEach((id) => params.append('id', id));
    }
    if (query.login) {
      const logins = Array.isArray(query.login) ? query.login : [query.login];
      logins.forEach((login) => params.append('login', login));
    }

    const response = await this.httpClient.get<TwitchUsersResponse>('users', { params });
    return response.data;
  }
}

let twitchClient: TwitchClient | null = null;

export async function getTwitchClient() {
  if (!twitchClient) {
    twitchClient = new TwitchClient();
  }

  return twitchClient;
}
