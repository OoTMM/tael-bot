import typescript from 'rollup-plugin-typescript2';

/** @type {import('rollup').RollupOptions} */
const config = {
  input: 'src/index.ts',
  plugins: [typescript()],
  output: {
    file: 'dist/app.min.js',
    format: 'cjs',
  },
};

export default config;
