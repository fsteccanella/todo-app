FROM docker.io/node:18-alpine as builder
ENV NODE_ENV=production

WORKDIR /app

COPY ["package.json", "package-lock.json*", "./"]
RUN npm install --production

COPY . .
RUN npm run build

FROM docker.io/nginxinc/nginx-unprivileged:1.22-alpine
ENV TODO_API_BASE_URL=

COPY nginx/default.conf.template /etc/nginx/templates/default.conf.template
COPY --from=builder /app/build /usr/share/nginx/html