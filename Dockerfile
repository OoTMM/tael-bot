FROM node:22

WORKDIR /app

RUN apt-get update && apt-get install -y \
  dumb-init \
  && corepack enable pnpm

ENTRYPOINT [ "dumb-init", "/app/docker-entrypoint.sh" ]
CMD [ "pnpm", "start" ]
