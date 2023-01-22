# Bash CI Server
![Version][b3]
[![Test Build Status][b1]][bl]
[![Docker Image Size][b2]][bl]

Lightweight CI/CD server written in Bash.

This is simply the combination of the [Bash CI scripts][1] by Shumpei
Iinuma and an [Ncat server][2]. Together they are able to serve as a
lightweight CI server for other services such as a git server.

Image source at: https://github.com/rockstorm101/bash-ci-server

[1]: https://github.com/iinm/bash-ci
[2]: https://nmap.org/ncat/guide/index.html


## Usage

Setting up automated CI/CD tasks requires 3 steps:

 * Set up a CI/CD action on your repository
 * Register the desired action on the CI server
 * Notify the CI server of updates


### Setting up a CI/CD action on your repository

When using CI services like GitHub Actions you would define your CI/CD
actions at `.github/workflows`. In this case you are free to define
them wherever you want as long as it is coherent with what will be
registered on the CI server. As an example, our repository could have
a file `.actions/deploy.sh` like:

```
#!/usr/bin/env bash

mkdir -p tmp
echo "FROM alpine:3.17" > ./tmp/Dockerfile

bash ${BASH_CI_DIR}/with_dockerfile --verbose \
     --build-path ./tmp \
     --task-id 'deploy' \
     sh -c 'build ...'

rsync build repote-ip:/deploy
```

The action script is guaranteed to run at the root of your repository
checked out at the commit that triggered the action.

Variables that are available to the script:

 * BASH_CI_DIR: Directory with scripts like `with_dockerfile`. See
   [iinm's repository][1] for more information on what they can do.


### Registering the desired action on the CI server

The CI server will receive the update notifications from the git
server and act upon them in accordance with what's defined in files
called `hooks.ltsv`. These files reside at the CI server at the
location defined by HOOKS_DIR (by default this is
`/srv/bash-ci/hooks`). For each registered repository there will be a
sub-folder named after an ID of your choosing, e.g. 'repository.git',
and the relevant `hooks.ltsv` file for this repository shall be within
it.

Following on with the example, the CI server would have a file
`/srv/bash-ci/hooks/repository.git/hooks.ltsv` like:

```
hook_id:deploy  refs_pattern:master cmd:bash .actions/deploy.sh
```

From [iinm's][3]:

 * `hook_id`: Unique ID (Used as a part of log file name)
 * `refs_pattern`: pattern to filter branches or tags
 * `cmd` : Command you want to execute when branch is pushed

[3]: https://github.com/iinm/bash-ci#git


### Notifying the CI server of updates

The CI server listens for notifications in the form of 4 fields,
separated by space or tab and with a new line at the end:

```
<REPO-ID>   <URL>  <SHA-1>   <REF>
```

 1. Repository ID: Can be anything but must uniquely identify a
    particular repository. Must match that expected by the CI server
    in order to locate the relevant `hooks.ltsv` file
    (e.g. 'repository.git')

 2. Repository URL: The URL that allows fetching this repository. The
    CI server will attempt to clone this repository
    (e.g. 'https://example.com/user/repository.git')

 3. Commit ID: 40 hexadecimal characters that identify the Git commit
    that triggers the action. The CI server will checkout the
    repository at this commit
    (e.g. '1a410efbd13591db07496601ebc7a059dd55cfe9')

 4. Ref: Git reference for this commit (e.g. 'refs/heads/master')


As an example, we could set up a post-receive hook in a git server to
deliver this notification. Following on in our example we would have a
file `/srv/git/repository.git/hooks/post-receive` like:

```
#!/bin/sh

repo_id="repository.git"
url="https://example.com/user/repository.git"

while read -r old_sha new_sha ref; do
    echo -e "${repo_id}\t${url}\t${new_sha}\t${ref}" | \
        nc ci.example.com 1337
done
```

Note that in this case the notification is sent using the `nc` command
which is usually installed by default on Linux distributions. For
this, the CI server URL and the port where it listens (1337 by
default) are required.

See [official Git documentation][4] for more information about the
post-receive server hook and how it is intended to work.

[4]: https://git-scm.com/book/en/v2/Customizing-Git-Git-Hooks


### Example configuration

Example configuration for this CI server running alongside a [git
server][5].

```
services:
  git-server:
    # git server configuration

  bash-ci:
    image: rockstorm/bash-ci-server

    environment:
      # Must match the locations defined below
      JOBS_DIR: /tmp/bash-ci

    volumes:
      - ./hooks:/srv/bash-ci/hooks:ro

      # Volume to make job logs persistent
      - ci-logs:/srv/bash-ci/logs

      # Required to be able to run Docker containers
      - /tmp/bash-ci:/tmp/bash-ci
      - /var/run/docker.sock:/var/run/docker.sock
```


## Disclaimer

Note that, at the current stage, no authentication mechanism is
implemented. This server is **not** suitable to be exposed to the
internet. User caution is advised.

In the examples above the host's Docker socket is shared with the CI
server. Doing this has security implications since the CI server user
will be able to run and have access to _any_ and _all_ containers on
the host.


## Tags and Variants

This image uses the stable Alpine image.

 - **'X.Y-bZ'**: Immutable tag. Points to a specific image build and will
   not be reused.

 - **'X.Y'**: Stable tag for specific Git major and minor versions. It
   follows the latest build for Git version X.Y and therefore changes
   on every patch change (i.e. 1.2.3 to 1.2.4), on every change on
   Nginx and every change on the base Alpine image.

 - **'latest'**: This tag follows the very latest build regardless any
   major/minor versions.


## See Also

 * [git-server][5]: A lightweight, simple to configure git server
   over SSH.
 * [gitweb][6]: A lightweight git repositories server over HTTP.


[5]: https://github.com/rockstorm101/git-server-docker
[6]: https://github.com/rockstorm101/bash-ci-server


## License

View [license information][7] for the software contained in this
image.

As with all Docker images, these likely also contain other software
which may be under other licenses (such as bash, etc from the base
distribution, along with any direct or indirect dependencies of the
primary software being contained).

As for any pre-built image usage, it is the image user's
responsibility to ensure that any use of this image complies with any
relevant licenses for all software contained within.

[7]: https://github.com/rockstorm101/bash-ci-server/blob/master/LICENSE


[b3]: https://img.shields.io/github/v/release/rockstorm101/bash-ci-server?include_prereleases&label=version
[b1]: https://img.shields.io/github/actions/workflow/status/rockstorm101/bash-ci-server/test-build.yml?branch=master
[b2]: https://img.shields.io/docker/image-size/rockstorm/bash-ci-server?logo=docker
[bl]: https://hub.docker.com/r/rockstorm/bash-ci-server
