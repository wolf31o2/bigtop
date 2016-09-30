#!/bin/bash

# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -e

usage() {
  echo "
usage: $0 <options>
  Required not-so-options:
     --build-dir=DIR             path to dist.dir
     --source-dir=DIR            path to package shared files dir
     --prefix=PREFIX             path to install into

  Optional options:
     --doc-dir=DIR               path to install docs into [/usr/share/doc/tephra]
     --lib-dir=DIR               path to install Zeppelin home [/usr/lib/tephra]
     --installed-lib-dir=DIR     path where lib-dir will end up on target system
     --bin-dir=DIR               path to install bins [/usr/bin]
     ... [ see source for more similar options ]
  "
  exit 1
}

OPTS=$(getopt \
  -n $0 \
  -o '' \
  -l 'prefix:' \
  -l 'doc-dir:' \
  -l 'lib-dir:' \
  -l 'installed-lib-dir:' \
  -l 'bin-dir:' \
  -l 'source-dir:' \
  -l 'build-dir:' -- "$@")

if [ $? != 0 ] ; then
    usage
fi

eval set -- "$OPTS"
while true ; do
    case "$1" in
        --prefix)
        PREFIX=$2 ; shift 2
        ;;
        --build-dir)
        BUILD_DIR=$2 ; shift 2
        ;;
        --source-dir)
        SOURCE_DIR=$2 ; shift 2
        ;;
        --doc-dir)
        DOC_DIR=$2 ; shift 2
        ;;
        --lib-dir)
        LIB_DIR=$2 ; shift 2
        ;;
        --installed-lib-dir)
        INSTALLED_LIB_DIR=$2 ; shift 2
        ;;
        --bin-dir)
        BIN_DIR=$2 ; shift 2
        ;;
        --)
        shift ; break
        ;;
        *)
        echo "Unknown option: $1"
        usage
        exit 1
        ;;
    esac
done

for var in PREFIX BUILD_DIR SOURCE_DIR; do
  if [ -z "$(eval "echo \$$var")" ]; then
    echo Missing param: $var
    usage
  fi
done

if [ -f "$SOURCE_DIR/bigtop.bom" ]; then
  . $SOURCE_DIR/bigtop.bom
fi

MAN_DIR=${MAN_DIR:-/usr/share/man/man1}
DOC_DIR=${DOC_DIR:-/usr/share/doc/tephra}
LIB_DIR=${LIB_DIR:-/usr/lib/tephra}
INSTALLED_LIB_DIR=${INSTALLED_LIB_DIR:-/usr/lib/tephra}
BIN_DIR=${BIN_DIR:-/usr/bin}
CONF_DIR=${CONF_DIR:-/etc/tephra/conf.dist}

install -d -m 0755 $PREFIX/$LIB_DIR
install -d -m 0755 $PREFIX/$LIB_DIR/bin
install -d -m 0755 $PREFIX/$LIB_DIR/lib
install -d -m 0755 $PREFIX/$CONF_DIR
install -d -m 0755 $PREFIX/$DOC_DIR

install -d -m 0755 $PREFIX/var/lib/tephra/
install -d -m 0755 $PREFIX/var/log/tephra/
install -d -m 0755 $PREFIX/var/run/tephra/

tar --wildcards --strip-components=1 -C $PREFIX/$LIB_DIR -zxf ${BUILD_DIR}/tephra-distribution/target/tephra-*.tar.gz \*/bin/\*
tar --wildcards --strip-components=1 -C $PREFIX/$LIB_DIR -zxf ${BUILD_DIR}/tephra-distribution/target/tephra-*.tar.gz \*/interpreter/\*
tar --wildcards --strip-components=1 -C $PREFIX/$LIB_DIR -zxf ${BUILD_DIR}/tephra-distribution/target/tephra-*.tar.gz \*/lib/\*
tar --wildcards --strip-components=1 -C $PREFIX/$LIB_DIR -zxf ${BUILD_DIR}/tephra-distribution/target/tephra-*.tar.gz \*tephra-server\*.jar
tar --wildcards --strip-components=1 -C $PREFIX/$LIB_DIR -zxf ${BUILD_DIR}/tephra-distribution/target/tephra-*.tar.gz \*tephra-web\*.war
tar --wildcards --strip-components=1 -C $PREFIX/var/lib/tephra -zxf ${BUILD_DIR}/tephra-distribution/target/tephra-*.tar.gz \*/notebook/\*

chmod 755 $PREFIX/$LIB_DIR/bin/*

cp -a ${BUILD_DIR}/{LICENSE,README.md} $PREFIX/$LIB_DIR

cp -a ${BUILD_DIR}/conf/* $PREFIX/$CONF_DIR
cp -a ${SOURCE_DIR}/tephra-env.sh $PREFIX/$CONF_DIR
ln -s /etc/tephra/conf $PREFIX/$LIB_DIR/conf
