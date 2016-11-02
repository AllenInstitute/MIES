#!/bin/sh

perl xop-stub-generator.pl interface.h
cp functions.* ../src
