#!/bin/sh

set -e

BASEFOLDER=../../../../../libzmq/build-msvc

cp $BASEFOLDER/bin/Release/*.dll x86
cp $BASEFOLDER/bin/Debug/*.dll   x86
cp $BASEFOLDER/lib/Release/*.lib x86
cp $BASEFOLDER/lib/Debug/*.lib   x86

BASEFOLDER=../../../../../libzmq/build-msvc-64

cp $BASEFOLDER/bin/Release/*.dll x64
cp $BASEFOLDER/bin/Debug/*.dll   x64
cp $BASEFOLDER/lib/Release/*.lib x64
cp $BASEFOLDER/lib/Debug/*.lib   x64

BASEFOLDER=../../../../../libzmq/include

cp $BASEFOLDER/*.h include
