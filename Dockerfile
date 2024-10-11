# build environment
FROM node:14.19-slim as build
WORKDIR /app
ENV PATH /app/node_modules/.bin:$PATH

ARG SERVER_HOST=https://f2c7f522-ef47-48ce-a429-3fc2f15d2011-dev.e1-us-east-azure.choreoapis.dev/ldf/my-local-service/v1.0

RUN apt-get update && apt-get install python -y && \
    apt-get install git -y && \
    apt-get install build-essential -y

COPY package.json ./
COPY package-lock.json ./
RUN npm ci 
RUN npm install react-scripts@3.4.1 -g --silent
COPY . .
ENV REACT_APP_SERVER_HOST=$SERVER_HOST
ENV BUILD_PATH='./build/mylocal'

RUN npm run build

# production environment
FROM nginx:1.21

# Create the choreo user and group
RUN addgroup --gid 10014 choreo && \
    adduser --disabled-password --no-create-home --uid 10014 --ingroup choreo choreouser

COPY --from=build /app/build/mylocal /usr/share/nginx/html/mylocal
COPY --from=build /app/nginx/nginx.conf /etc/nginx/nginx.conf
COPY --from=build /app/nginx/mime.types /etc/nginx/mime.types

# Create necessary directories and set permissions
RUN mkdir -p /tmp/nginx/client_temp /tmp/nginx/proxy_temp /tmp/nginx/fastcgi_temp /tmp/nginx/uwsgi_temp /tmp/nginx/scgi_temp /var/cache/nginx /var/run/nginx && \
    chmod -R 777 /tmp/nginx /var/cache/nginx /usr/share/nginx/html/mylocal /var/run/nginx && \
    chmod -R 755 /etc/nginx && \
    chown -R choreouser:choreo /var/cache/nginx /var/run/nginx /usr/share/nginx/html/mylocal /tmp/nginx

USER choreouser
EXPOSE 8080
CMD ["nginx", "-g", "daemon off;"]