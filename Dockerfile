FROM buildpack-deps:jessie
MAINTAINER Ian Patton (ian.patton@gmail.com)

RUN useradd --uid 1000 --gid staff --shell /bin/bash --create-home litecoin

RUN echo "deb http://ftp.us.debian.org/debian unstable main contrib non-free" >> /etc/apt/sources.list.d/unstable.list
RUN apt-get update
RUN apt-get install -y -t unstable gcc-5
RUN apt-get install -y build-essential libtool autotools-dev automake pkg-config libssl-dev libevent-dev bsdmainutils libzmq3-dev libboost-system-dev libboost-filesystem-dev libboost-chrono-dev libboost-program-options-dev libboost-test-dev libboost-thread-dev

ENV APP_DIR=/home/litecoin/litecoin

#setup litecoin directory
RUN mkdir -p $APP_DIR
WORKDIR $APP_DIR
RUN chown litecoin:staff -R $APP_DIR

USER litecoin
#build berkley db 4.8
ENV BDB_PREFIX="${APP_DIR}/db4"
RUN mkdir -p $BDB_PREFIX
RUN wget 'http://download.oracle.com/berkeley-db/db-4.8.30.NC.tar.gz' && echo '12edc0df75bf9abd7f82f821795bcee50f42cb2e5f76a6a281b85732798364ef  db-4.8.30.NC.tar.gz' | sha256sum -c
RUN tar -xzvf db-4.8.30.NC.tar.gz && cd db-4.8.30.NC/build_unix/ && ../dist/configure --enable-cxx --disable-shared --with-pic --prefix=$BDB_PREFIX && make install

# Configure Litecoin to use our own-built instance of BDB
USER root
COPY . $APP_DIR
RUN chown litecoin:staff -R $APP_DIR
USER litecoin
RUN cd $APP_DIR && ./autogen.sh && ./configure LDFLAGS="-L${BDB_PREFIX}/lib/" CPPFLAGS="-I${BDB_PREFIX}/include/" && make

USER root
RUN make install

EXPOSE 8332 8333 18332 18333 28332 28333

USER litecoin
CMD ["/usr/local/bin/litecoind","-printtoconsole"]
