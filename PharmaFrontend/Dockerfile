FROM node:24-bookworm-slim AS build
WORKDIR /app

COPY package.json package-lock.json ./
RUN npm ci

COPY . ./
RUN npm run build

FROM cgr.dev/chainguard/node:latest
ENV NODE_ENV=production
ENV PORT=8080
ENV API_UPSTREAM=http://hcp-portal-api/api
WORKDIR /app

COPY --from=build /app/dist ./dist
COPY --from=build /app/server.mjs ./server.mjs

EXPOSE 8080

CMD ["server.mjs"]