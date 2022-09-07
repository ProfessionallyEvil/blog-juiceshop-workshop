FROM docker.io/python:3.8
# https://github.com/CircleCI-Public/cimg-python/blob/d0899387b027723c4b8c9684882905a1e3ce5cb8/3.10/node/Dockerfile#L8-L13
RUN curl -sSL "https://raw.githubusercontent.com/CircleCI-Public/cimg-node/main/ALIASES" -o nodeAliases.txt \
    && NODE_VERSION=$(grep "lts" ./nodeAliases.txt | cut -d "=" -f 2-) \
    && curl -L -o node.tar.xz "https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-x64.tar.xz" \
    && tar -xJf node.tar.xz -C /usr/local --strip-components=1 \
    && rm node.tar.xz nodeAliases.txt \
    && ln -s /usr/local/bin/node /usr/local/bin/nodejs
RUN apt-get update \
    && apt-get install -y jq
WORKDIR /aws_cdk/
ENTRYPOINT [ "./docker_entrypoint.sh" ]
USER root
