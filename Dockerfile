FROM alpine:3.17

RUN set -ex; \
    apk add --no-cache \
        bash \
        docker-cli \
        git \
        nmap-ncat \
    ;

# Install and setup Bash-CI
ENV BASH_CI_ROOT_DIR=/srv/bash-ci
ENV BASH_CI_DIR=$BASH_CI_ROOT_DIR/scripts \
    HOOKS_DIR=$BASH_CI_ROOT_DIR/hooks \
    LOGS_DIR=$BASH_CI_ROOT_DIR/logs
RUN set -ex; \
    mkdir -p $BASH_CI_DIR; \
    cd $BASH_CI_DIR; \
    git clone https://github.com/iinm/bash-ci.git .; \
    git checkout 33d8d68aab427cc5b7f5e45fd5835a458ef99060; \
    rm -rf .git .gitignore .github; \
    mkdir -p $HOOKS_DIR; \
    mkdir -p $LOGS_DIR;

# Server setup
COPY bash-ci-server.sh /

ENV SERVER_PORT=1337
EXPOSE $SERVER_PORT

ENTRYPOINT ["/bash-ci-server.sh"]
