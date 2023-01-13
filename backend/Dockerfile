FROM node:18-alpine
ENV NODE_ENV=production
ENV MONGO_SERVER=

WORKDIR /app

COPY ["package.json", "package-lock.json*", "./"]

RUN npm install --production

COPY . .

CMD [ "node", "src/index.js" ]