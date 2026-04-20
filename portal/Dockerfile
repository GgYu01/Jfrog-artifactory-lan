FROM node:24-alpine

WORKDIR /app

COPY server.js /app/server.js
COPY lib /app/lib
COPY public /app/public

EXPOSE 8080

CMD ["node", "server.js"]

