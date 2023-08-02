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

# Install GHCUP 
RUN curl --proto '=https' --tlsv1.2 -sSf https://get-ghcup.haskell.org | sh \
    && echo 'export PATH="/root/.ghcup/bin:$PATH"' >> ~/.bashrc \
    && /bin/bash -c "source /root/.ghcup/env && ghcup install ghc 8.10.7 && ghcup set ghc 8.10.7 && ghcup install cabal 3.6.2.0 && ghcup set cabal 3.6.2.0" 

#Set environment variable so that other temporary containers for different run commands can access it
ENV PATH="/root/.ghcup/bin:${PATH}"

# Set working directory
WORKDIR /root/cardano-src

# Clone the repositories
RUN git clone https://github.com/input-output-hk/libsodium ; cd libsodium ; git checkout dbb48cc ; ./autogen.sh ; ./configure ; make ; make install

RUN git clone https://github.com/bitcoin-core/secp256k1 ; cd secp256k1 ; git checkout ac83be33 ; ./autogen.sh ; ./configure --enable-module-schnorrsig --enable-experimental ; make ; make check ; make install 

RUN git clone https://github.com/input-output-hk/cardano-node.git

ENV LD_LIBRARY_PATH=/usr/local/lib

# Set working directory to cardano-node
WORKDIR /root/cardano-src/cardano-node

# Fetch tags
RUN git fetch --all --recurse-submodules --tags \
    && git checkout master


# Made manual changes to cabal.project and hence supplied it seperately
COPY ./cabal.project /root/cardano-src/cardano-node/ 


RUN cabal update

RUN cabal configure --with-compiler=ghc-8.10.7

ENV PATH="/root/.local/bin:${PATH}"


RUN cabal update \
    && cabal build all \
    && mkdir -p $HOME/.local/bin \
    &&  cp -p "$(./scripts/bin-path.sh cardano-node)" $HOME/.local/bin/ \
    && cp -p "$(./scripts/bin-path.sh cardano-cli)" $HOME/.local/bin/ 
