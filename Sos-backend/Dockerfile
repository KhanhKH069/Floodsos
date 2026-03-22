# Dockerfile for Node.js Backend (Sos-backend)
FROM node:18-alpine

WORKDIR /app

# Copy package files first (layer caching)
COPY package*.json ./
RUN npm ci --omit=dev

# Copy application source
COPY . .

# Ensure uploads directory exists
RUN mkdir -p uploads

EXPOSE 3002

CMD ["node", "server.js"]
