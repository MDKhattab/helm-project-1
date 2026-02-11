FROM node:18-alpine AS build

WORKDIR /app

COPY package*.json ./
RUN npm install

COPY . .
RUN npm run build

# Install envsubst
RUN apk add --no-cache gettext


FROM nginx:alpine

COPY --from=build /app/build /usr/share/nginx/html
# Copy template config (uses ${BACKEND_URL})
COPY default.conf.template /etc/nginx/templates/default.conf.template


EXPOSE 80

# Substitute BACKEND_URL into nginx config before starting
CMD ["/bin/sh", "-c", "envsubst '$BACKEND_URL' < /etc/nginx/templates/default.conf.template > /etc/nginx/conf.d/default.conf && exec nginx -g 'daemon off;'"]
