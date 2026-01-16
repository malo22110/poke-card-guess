# Stage 1: Build the Flutter Web App
FROM debian:latest AS build-env

# Install dependencies
RUN apt-get update && apt-get install -y \
    curl \
    git \
    unzip \
    libgconf-2-4 \
    gdb \
    libstdc++6 \
    libglu1-mesa \
    fonts-droid-fallback \
    lib32stdc++6 \
    python3 \
    && apt-get clean

# Clone Flutter
RUN git clone https://github.com/flutter/flutter.git /usr/local/flutter

# Set Flutter path
ENV PATH="/usr/local/flutter/bin:/usr/local/flutter/bin/cache/dart-sdk/bin:${PATH}"

# Enable web support
RUN flutter config --enable-web

# Run flutter doctor
RUN flutter doctor

# Copy files
WORKDIR /app
COPY . .

# Get dependencies
RUN flutter pub get

# Build web
RUN flutter build web --release

# Stage 2: Serve with Nginx
FROM nginx:1.21.1-alpine
COPY --from=build-env /app/build/web /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
