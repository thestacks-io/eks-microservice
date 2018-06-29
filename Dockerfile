FROM node:latest

# Create app directory
WORKDIR /usr/src/app

# Install app dependencies
COPY src/package.json /usr/src/app/.
# For npm@5 or later, copy package-lock.json as well
# COPY package.json package-lock.json ./

# Install dependencies
RUN npm install

# Bundle app source
COPY ./src/ /usr/src/app/

# Run tests
RUN npm test

ENV PORT 8000
EXPOSE 8000

# Add supervisord
RUN apt-get update \
 && apt-get -y install supervisor
RUN mkdir /var/logs
RUN touch /var/logs/supervisord.log
RUN chmod a+rw /var/logs/supervisord.log
ADD supervisord.conf /etc/supervisor/conf.d/supervisord.conf
CMD ["/usr/bin/supervisord", "--nodaemon", "-c", "/etc/supervisor/conf.d/supervisord.conf"]