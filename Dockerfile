FROM node:20

WORKDIR /app

ENTRYPOINT [ "/app/docker-entrypoint.sh" ]
CMD [ "/app/docker-start.sh" ]
