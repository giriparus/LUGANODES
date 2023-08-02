FROM ubuntu:latest

RUN apt-get update -y
RUN apt-get upgrade -y

RUN apt-get install automake \
build-essential \
pkg-config \
libffi-dev \
libgmp-dev \
libssl-dev \
libtinfo-dev \
libsystemd-dev \
zlib1g-dev \
make \
g++ \
tmux \
git \
jq \
wget \
curl \
libncursesw5 \
libtool \
autoconf \
cabal-install -y

# Install GHCUP (Haskell Toolchain Installer)
RUN curl --proto '=https' --tlsv1.2 -sSf https://get-ghcup.haskell.org | sh \
    && echo 'export PATH="/root/.ghcup/bin:$PATH"' >> ~/.bashrc \
    && /bin/bash -c "source /root/.ghcup/env && ghcup install ghc 8.10.7 && ghcup set ghc 8.10.7 && ghcup install cabal 3.6.2.0 && ghcup set cabal 3.6.2.0" 

ENV PATH="/root/.ghcup/bin:${PATH}"

# Set the working directory
WORKDIR /root/cardano-src

# Clone the repositories
RUN git clone https://github.com/input-output-hk/libsodium ; cd libsodium ; git checkout dbb48cc ; ./autogen.sh ; ./configure ; make ; make install

RUN git clone https://github.com/bitcoin-core/secp256k1 ; cd secp256k1 ; git checkout ac83be33 ; ./autogen.sh ; ./configure --enable-module-schnorrsig --enable-experimental ; make ; make check ; make install 

RUN git clone https://github.com/input-output-hk/cardano-node.git

ENV LD_LIBRARY_PATH=/usr/local/lib

# Set the working directory to cardano-node
WORKDIR /root/cardano-src/cardano-node

# Fetch the tags
RUN git fetch --all --recurse-submodules --tags \
    && git checkout master


# Edit the cabal.project file to set index-state to "HEAD"
COPY ./cabal.project /root/cardano-src/cardano-node/ 

# Continue with the rest of the instructions
RUN cabal update

# # Continue with the rest of the instructions
RUN cabal configure --with-compiler=ghc-8.10.7

ENV PATH="/root/.local/bin:${PATH}"


RUN cabal update \
    && cabal build all \
    && mkdir -p $HOME/.local/bin \
    &&  cp -p "$(./scripts/bin-path.sh cardano-node)" $HOME/.local/bin/ \
    && cp -p "$(./scripts/bin-path.sh cardano-cli)" $HOME/.local/bin/ \
    && curl -O -J https://book.world.dev.cardano.org/environments/preview/config.json \
    && curl -O -J https://book.world.dev.cardano.org/environments/preview/db-sync-config.json \
    && curl -O -J https://book.world.dev.cardano.org/environments/preview/submit-api-config.json \
    && curl -O -J https://book.world.dev.cardano.org/environments/preview/topology.json \
    && curl -O -J https://book.world.dev.cardano.org/environments/preview/byron-genesis.json \
    && curl -O -J https://book.world.dev.cardano.org/environments/preview/shelley-genesis.json \
    && curl -O -J https://book.world.dev.cardano.org/environments/preview/alonzo-genesis.json \
    && curl -O -J https://book.world.dev.cardano.org/environments/preview/conway-genesis.json \
    &&  cardano-node run \
    --config $HOME/cardano-src/testnet/config.json \
    --database-path $HOME/cardano-src/testnet/db/ \
    --socket-path $HOME/cardano-src/testnet/db/node.socket \
    --host-addr 127.0.0.1 \
    --port 1337 \
    --topology $HOME/cardano-src/testnet/topology.json
