FROM alpine:3.20.0

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
    mkdir -p $HOOKS_DIR; \
    mkdir -p $LOGS_DIR;
COPY \
    bash-ci/git.bash \
    bash-ci/github.bash \
    bash-ci/gitlab.bash \
    bash-ci/slack.bash \
    bash-ci/with_dockerfile \
    bash-ci/with_github_checks \
    bash-ci/with_github_pr_comment \
    bash-ci/with_gitlab_mr_comment \
    bash-ci/with_gitlab_pipeline \
    bash-ci/with_slack_message \
    $BASH_CI_DIR/

# Server setup
COPY bash-ci-server.sh /

ENV SERVER_PORT=1337
EXPOSE $SERVER_PORT

ENTRYPOINT ["/bash-ci-server.sh"]
