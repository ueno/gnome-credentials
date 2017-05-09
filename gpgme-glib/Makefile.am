AUTOMAKE_OPTIONS = subdir-objects
CLEANFILES =
DISTCLEANFILES =
MAINTAINERCLEANFILES =
EXTRA_DIST =
noinst_DATA =

if GPGME_GLIB_STATIC
noinst_LTLIBRARIES = libgpgme-glib.la
else
pkglib_LTLIBRARIES = libgpgme-glib.la
endif

libgpgme_glib_la_sources =			\
	gpgme-glib/gpgme-glib.c			\
	gpgme-glib/gpgme-glib-enumtypes.c
libgpgme_glib_la_headers =			\
	gpgme-glib/gpgme-glib.h			\
	gpgme-glib/gpgme-glib-enums.h		\
	gpgme-glib/gpgme-glib-enumtypes.h

libgpgme_glib_la_SOURCES = $(libgpgme_glib_la_sources)
libgpgme_glib_la_CFLAGS = $(GPGME_GLIB_CFLAGS) -I$(top_srcdir)
libgpgme_glib_la_LIBADD = $(GPGME_GLIB_LIBS)

noinst_HEADERS = $(libgpgme_glib_la_headers)

BUILT_SOURCES =					\
	gpgme-glib/gpgme-glib-enumtypes.h	\
	gpgme-glib/gpgme-glib-enumtypes.c

gpgme-glib/gpgme-glib-enumtypes.h: gpgme-glib/gpgme-glib-enums.h gpgme-glib/gpgme-glib-enumtypes.h.template
	$(AM_V_GEN) $(MKDIR_P) gpgme-glib && \
	  $(GLIB_MKENUMS) --identifier-prefix GGpg --symbol-prefix g_gpg --template gpgme-glib/gpgme-glib-enumtypes.h.template gpgme-glib/gpgme-glib-enums.h > $@-t && mv $@-t $@ || rm $@-t
gpgme-glib/gpgme-glib-enumtypes.c: gpgme-glib/gpgme-glib-enums.h gpgme-glib/gpgme-glib-enumtypes.c.template
	$(AM_V_GEN) $(MKDIR_P) gpgme-glib && \
	  $(GLIB_MKENUMS) --identifier-prefix GGpg --symbol-prefix g_gpg --template gpgme-glib/gpgme-glib-enumtypes.c.template gpgme-glib/gpgme-glib-enums.h > $@-t && mv $@-t $@ || rm $@-t

EXTRA_DIST +=						\
	gpgme-glib/gpgme-glib-enumtypes.h.template	\
	gpgme-glib/gpgme-glib-enumtypes.c.template
CLEANFILES += gpgme-glib/*-t

if HAVE_INTROSPECTION
-include $(INTROSPECTION_MAKEFILE)
INTROSPECTION_GIRS = Gpgme-1.0.gir

Gpgme-1.0.gir: libgpgme-glib.la
Gpgme_1_0_gir_SCANNERFLAGS =			\
	--warn-all				\
	--pkg-export=gpgme-glib			\
	--namespace=Gpgme			\
	--identifier-prefix=GGpg		\
	--symbol-prefix=g_gpg
Gpgme_1_0_gir_INCLUDES = $(GPGME_GLIB_GIR_INCLUDES)
Gpgme_1_0_gir_CFLAGS = $(libgpgme_glib_la_CFLAGS)
Gpgme_1_0_gir_LIBS = libgpgme-glib.la
Gpgme_1_0_gir_FILES = $(libgpgme_glib_la_sources) $(libgpgme_glib_la_headers)

if GPGME_GLIB_STATIC
noinst_DATA += $(srcdir)/Gpgme-1.0.gir
EXTRA_DIST += $(srcdir)/Gpgme-1.0.gir
MAINTAINERCLEANFILES += $(srcdir)/Gpgme-1.0.gir
else
girdir = $(pkgdatadir)/gir-1.0
typelibdir = $(pkglibdir)/girepository-1.0

gir_DATA = $(INTROSPECTION_GIRS)
typelib_DATA = $(gir_DATA:.gir=.typelib)

CLEANFILES += $(gir_DATA) $(typelib_DATA)
endif
endif

if ENABLE_VAPIGEN
if GPGME_GLIB_VAPI
-include $(VAPIGEN_MAKEFILE)

gpgme-glib-1.0.vapi: Gpgme-1.0.gir

VAPIGEN_VAPIS = gpgme-glib-1.0.vapi

gpgme_glib_1_0_vapi_DEPS = gio-2.0
gpgme_glib_1_0_vapi_METADATADIRS = $(srcdir)
gpgme_glib_1_0_vapi_FILES = Gpgme-1.0.gir

noinst_DATA += $(VAPIGEN_VAPIS)
EXTRA_DIST += $(VAPIGEN_VAPIS) Gpgme-1.0.metadata
MAINTAINERCLEANFILES += $(VAPIGEN_VAPIS)
endif
endif
