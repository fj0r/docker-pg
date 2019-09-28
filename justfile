img:
    #!/bin/bash
    docker build . -t pg:build \
        -f Dockerfile-build
    docker build . -t pg:runtime \
        -f Dockerfile-runtime
    docker build . -t pg:3stage \
        -f Dockerfile-new \
        --build-arg pg_url=http://172.178.1.204:2015/postgresql.tar.bz2

i:
    docker build . -t pg \
        --build-arg pg_url=http://172.178.1.204:2015/postgresql.tar.bz2

# pg: 339M 380M
# pip numpy-1.17.2  py-numpy 1.16.4