#!/bin/sh
# [Mikunopop Project]
# 

# note: run it in mod_perl directory.

BASE=/web/mikunopop
APACHE=../httpd-2.2.14-mikunopop
PERL=/usr/bin/perl
APR_CONFIG=/usr/local/apr/bin/apr-1-config 

# loading $APACHE_OPT
. ./build_apache2_config.sh

renice +10 -p $$

echo "base: ${BASE}"

CFLAGS="-O2"
$PERL Makefile.PL \
	MP_USE_STATIC=1 \
	MP_AP_PREFIX=$APACHE \
	MP_AP_CONFIGURE="$APACHE_OPT" \
	MP_GENERATE_XS=1 \
	&& make \
	&& strip ${APACHE}/.libs/httpd \
	&& ${APACHE}/httpd -V \
	&& ${APACHE}/httpd -l

#if [ -e  ${APACHE}/.libs/httpd -a `uname` != "Darwin" ]; then
#	strip  ${APACHE}/.libs/httpd
#fi

#	MP_TRACE=1    # for PerlTrace switch
#	MP_APR_CONFIG=$APR_CONFIG \
#	MP_AP_PREFIX=$APACHE \

