FROM node:22

WORKDIR /app

RUN apt-get update && apt-get install -y \
  dumb-init

ENTRYPOINT [ "dumb-init", "/app/docker-entrypoint.sh" ]
CMD [ "/app/docker-start.sh", "tsx", "src/index.ts" ]
