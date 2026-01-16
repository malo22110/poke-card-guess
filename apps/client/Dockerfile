# Stage 1: Build the Flutter Web App
FROM debian:latest AS build-env

# Install dependencies
# Install dependencies
RUN apt-get update && apt-get install -y \
    curl \
    git \
    unzip \
    xz-utils \
    zip \
    libglu1-mesa \
    && apt-get clean

# Clone Flutter (Shallow clone for speed)
RUN git clone --depth 1 -b stable https://github.com/flutter/flutter.git /usr/local/flutter

# Set Flutter path
ENV PATH="/usr/local/flutter/bin:/usr/local/flutter/bin/cache/dart-sdk/bin:${PATH}"

# Enable web support (and disable analytics to speed up first run)
RUN flutter config --no-analytics --enable-web

# Run flutter doctor
RUN flutter doctor

# Copy files
WORKDIR /app
COPY . .

# Get dependencies
RUN flutter pub get

# Build web
# Build args
ARG API_URL=http://localhost:3000
# Build web with environment variables
RUN flutter build web --release --dart-define=API_URL=$API_URL --dart-define=SOCKET_URL=$API_URL

# Stage 2: Serve with Nginx
FROM nginx:1.21.1-alpine
COPY --from=build-env /app/build/web /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
