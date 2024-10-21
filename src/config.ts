const env = process.env.NODE_ENV || 'development';
const prod = env === 'production';

const CONFIG_BASE = {

};

const CONFIG_DEV = {
  discord: {
    twitchChannel: '1297982410608349337'
  }
};

const CONFIG_PROD = {
  discord: {
    twitchChannel: '1274821923280523334'
  }
};

const CONFIG_ENV = prod ? CONFIG_PROD : CONFIG_DEV;

export default { ...CONFIG_BASE, ...CONFIG_ENV };
