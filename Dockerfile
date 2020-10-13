# vim:set ft=dockerfile:
FROM postgres:13

ENV BUILD_DEPS \
	git \
	cmake \
	wget \
	build-essential \
	ca-certificates \
	libpq-dev \
	libssl-dev \
	postgresql-server-dev-${PG_MAJOR}

ENV TIMESCALEDB_VERSION=2.0.0-rc1

#ENV LANG zh_CN.utf8
ENV TIMEZONE=Asia/Shanghai
RUN set -eux \
	; ln -sf /usr/share/zoneinfo/$TIMEZONE /etc/localtime \
  	; echo "$TIMEZONE" > /etc/timezone \
	; sed -i /etc/locale.gen \
		-e 's/# \(en_US.UTF-8 UTF-8\)/\1/' \
		-e 's/# \(zh_CN.UTF-8 UTF-8\)/\1/' \
	; locale-gen \
	; apt-get update \
	; apt-get install -y --no-install-recommends \
		postgresql-plpython3-${PG_MAJOR} \
		postgresql-${PG_MAJOR}-wal2json \
		# postgresql-12-python3-multicorn
		python3-pip python3-setuptools \
		${BUILD_DEPS:-} \
	; pip3 --no-cache-dir install \
		numpy requests pyyaml furl \
		cachetools more-itertools PyParsing \
	\
	; build_dir=/root/build \
	; mkdir -p $build_dir \
	; cd $build_dir \
	\
	#; git clone https://github.com/postgrespro/rum.git \
	#; cd rum \
	#; make USE_PGXS=1 \
	#; make USE_PGXS=1 install \
	\
	; cd $build_dir \
	; git clone https://github.com/jaiminpan/pg_jieba \
  	; cd pg_jieba \
  	; git submodule update --init --recursive  \
	; mkdir build \
	; cd build \
	; cmake .. \
		-DPostgreSQL_TYPE_INCLUDE_DIR=/usr/include/postgresql/${PG_MAJOR}/server \
	; make \
	; make install \
	\
	#; cd $build_dir \
    #; wget -q -O- https://github.com/timescale/timescaledb/archive/${TIMESCALEDB_VERSION}.tar.gz | tar zxf - \
    #; cd timescaledb-${TIMESCALEDB_VERSION} \
    #; ./bootstrap -DREGRESS_CHECKS=OFF \
    #; cd build && make \
    #; make install \
	\
	; rm -rf $build_dir \
	\
	; apt-get purge -y --auto-remove ${BUILD_DEPS:-} \
	; apt-get clean -y && rm -rf /var/lib/apt/lists/*


COPY .psqlrc /root
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN ln -sf usr/local/bin/docker-entrypoint.sh / # backwards compat

ENV PG_JIEBA_HMM_MODEL=
ENV PG_JIEBA_BASE_DICT=
ENV PG_JIEBA_USER_DICT=
ENV PGCONF_SHARED_BUFFERS=2GB
ENV PGCONF_WORK_MEM=32MB
ENV PGCONF_EFFECTIVE_CACHE_SIZE=8GB
ENV PGCONF_EFFECTIVE_IO_CONCURRENCY=200
ENV PGCONF_RANDOM_PAGE_COST=1.1
ENV PGCONF_WAL_LEVEL=logical
ENV PGCONF_MAX_REPLICATION_SLOTS=10
#ENV PGCONF_SHARED_PRELOAD_LIBRARIES="'pg_stat_statements,timescaledb,pg_jieba.so'"
ENV PGCONF_SHARED_PRELOAD_LIBRARIES="'pg_stat_statements,pg_jieba.so'"
