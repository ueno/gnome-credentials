ACLOCAL_AMFLAGS = -I m4 -I libgd -I gpgme-glib ${ACLOCAL_FLAGS}
DISTCHECK_CONFIGURE_FLAGS = --disable-dogtail --disable-vala

SUBDIRS = po data gpgme-glib libgd egg src tests

MAINTAINERCLEANFILES = \
	INSTALL \
	aclocal.m4 \
	autoscan.log \
	compile \
	config.guess \
	config.h.in \
	config.sub \
	configure.scan \
	depcomp \
	install-sh \
	ltmain.sh \
	missing \
	mkinstalldirs

GITIGNOREFILES = \
	.anjuta \
	.anjuta_sym_db.db \
	m4/intltool.m4 \
	m4/libtool.m4 \
	m4/lt* \
	ABOUT-NLS \
	config.rpath \
	m4/appstream-xml.m4 \
	m4/codeset.m4 \
	m4/extern-inline.m4 \
	m4/fcntl-o.m4 \
	m4/gettext.m4 \
	m4/glib-2.0.m4 \
	m4/glibc2.m4 \
	m4/glibc21.m4 \
	m4/gsettings.m4 \
	m4/iconv.m4 \
	m4/intdiv0.m4 \
	m4/intl.m4 \
	m4/intldir.m4 \
	m4/intlmacosx.m4 \
	m4/intmax.m4 \
	m4/introspection.m4 \
	m4/inttypes-pri.m4 \
	m4/inttypes_h.m4 \
	m4/lcmessage.m4 \
	m4/lib-ld.m4 \
	m4/lib-link.m4 \
	m4/lib-prefix.m4 \
	m4/libgcrypt.m4 \
	m4/lock.m4 \
	m4/longlong.m4 \
	m4/nls.m4 \
	m4/pkg.m4 \
	m4/po.m4 \
	m4/printf-posix.m4 \
	m4/progtest.m4 \
	m4/size_max.m4 \
	m4/stdint_h.m4 \
	m4/threadlib.m4 \
	m4/uintmax_t.m4 \
	m4/vala.m4 \
	m4/visibility.m4 \
	m4/wchar_t.m4 \
	m4/wint_t.m4 \
	m4/xsize.m4 \
	po/Makevars.template \
	po/Rules-quot \
	po/boldquot.sed \
	po/en@boldquot.header \
	po/en@quot.header \
	po/insert-header.sin \
	po/quot.sed \
	po/remove-potcdate.sed \
	po/remove-potcdate.sin \
	po/stamp-po \
	rpms/

rpmdefines = \
	--define "_name $(PACKAGE_NAME)" \
	--define "_version $(PACKAGE_VERSION)" \
	--define "_distdir $(PACKAGE_TARNAME)" \
	--define "_sourcedir $(abs_builddir)" \
	--define "_specdir $(abs_srcdir)" \
	--define "_builddir $(abs_builddir)/rpms" \
	--define "_srcrpmdir $(abs_builddir)/rpms" \
	--define "_rpmdir $(abs_builddir)/rpms"

rpm: dist
	@rm -fR $(builddir)/rpms
	@mkdir $(builddir)/rpms
	env -i PATH=/usr/bin/:/bin SHELL=$(SHELL) HOSTNAME=$${HOSTNAME} HOME=$${HOME} \
	rpmbuild $(rpmdefines) -ba $(srcdir)/$(PACKAGE_NAME).spec

clean-local:
	rm -fR $(builddir)/rpms

EXTRA_DIST = $(PACKAGE_NAME).spec

-include $(top_srcdir)/git.mk
