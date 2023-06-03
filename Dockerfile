FROM node:20

WORKDIR /app

ENTRYPOINT [ "/app/docker-entrypoint.sh" ]
CMD [ "npm", "run", "start" ]
