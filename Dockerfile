FROM node:22-alpine
ENV NODE_ENV=production PORT=3000
WORKDIR /app
COPY app/package*.json ./
RUN npm ci --omit=dev && npm cache clean --force
COPY app/ ./
USER node
EXPOSE 3000
HEALTHCHECK --interval=10s --timeout=3s --start-period=5s --retries=5 CMD node -e "require('http').get('http://127.0.0.1:3000/health',r=>process.exit(r.statusCode===200?0:1)).on('error',()=>process.exit(1))"
CMD ["node", "server.js"]
