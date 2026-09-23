FROM node:16-bullseye-slim

WORKDIR /app

COPY package.json package-lock.json ./
RUN npm ci --omit=dev --no-audit \
    && npm cache clean --force

COPY --chown=node:node app.js server.js ./

USER node
EXPOSE 8080

CMD ["node", "server.js"]
