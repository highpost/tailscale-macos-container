FROM alpine:latest

# install dependencies
RUN apk add --no-cache shadow sudo tini tailscale

# create user
RUN adduser -D -s /bin/sh player1

# grant sudo to user (NOPASSWD)
RUN echo "player1 ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/dev-users && \
    chmod 0440                               /etc/sudoers.d/dev-users

# copy the init script into the container image
COPY tini-start.sh /tini-start.sh
RUN  chmod +x      /tini-start.sh

# tini entrypoint
ENTRYPOINT ["/sbin/tini", "--", "/tini-start.sh"]
