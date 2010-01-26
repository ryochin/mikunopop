#!/bin/sh
# [Mikunopop Project]
# 

BASE=/web/mikunopop
MPM="prefork"

APACHE_OPT="
	--with-mpm=${MPM} \
	--enable-layout=Apache \
	--with-apr=/usr/local/apr \
	--with-apr-util=/usr/local/apr \
	--prefix=${BASE} \
	--with-included-apr \
	--enable-http \
	--enable-deflate \
	--enable-rewrite \
	--disable-cache \
	--disable-expires \
	--disable-authn-default \
	--disable-authz-groupfile \
	--disable-authz-default \
	--disable-authn-file \
	--disable-authz-user \
	--disable-auth-basic \
	--disable-setenvif \
	--disable-include \
	--disable-status \
	--disable-autoindex \
	--disable-asis \
	--disable-cgi \
	--disable-cgid \
	--disable-actions \
	--disable-userdir \
	--disable-negotiation \
	--disable-filter \
	--with-module=user:./mod_dosdetector.c \
"

#	--disable-authz-host \
#	--enable-dumpio \
#	--with-module=user:./mod_loadavg2.c \
