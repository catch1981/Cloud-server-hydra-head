FROM node:20-alpine
WORKDIR /app
COPY package.json package-lock.json* ./
RUN npm ci || npm install
COPY . .
ENV NODE_ENV=production PORT=3000
EXPOSE 3000
CMD ["node","src/runner.js"]
