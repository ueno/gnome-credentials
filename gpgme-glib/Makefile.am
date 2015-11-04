noinst_LTLIBRARIES = libgpgme-glib.la

libgpgme_glib_la_sources = gpgme-glib.c gpgme-glib-enumtypes.c
libgpgme_glib_la_headers = gpgme-glib.h gpgme-glib-enums.h gpgme-glib-enumtypes.h
libgpgme_glib_la_SOURCES = $(libgpgme_glib_la_sources)
libgpgme_glib_la_CFLAGS = $(GIO_CFLAGS) $(GPGME_PTHREAD_CFLAGS) -I$(top_srcdir)
libgpgme_glib_la_LIBADD = $(GIO_LIBS) $(GPGME_PTHREAD_LIBS)

noinst_HEADERS = $(libgpgme_glib_la_headers)

BUILT_SOURCES = gpgme-glib-enumtypes.h gpgme-glib-enumtypes.c

gpgme-glib-enumtypes.h: gpgme-glib-enums.h gpgme-glib-enumtypes.h.template
	$(AM_V_GEN) $(GLIB_MKENUMS) --identifier-prefix GGpg --symbol-prefix g_gpg --template gpgme-glib-enumtypes.h.template gpgme-glib-enums.h > $@-t && mv $@-t $@ || rm $@-t
gpgme-glib-enumtypes.c: gpgme-glib-enums.h gpgme-glib-enumtypes.c.template
	$(AM_V_GEN) $(GLIB_MKENUMS) --identifier-prefix GGpg --symbol-prefix g_gpg --template gpgme-glib-enumtypes.c.template gpgme-glib-enums.h > $@-t && mv $@-t $@ || rm $@-t

EXTRA_DIST =
CLEANFILES =
DISTCLEANFILES =
MAINTAINERCLEANFILES =

EXTRA_DIST += gpgme-glib-enumtypes.h.template gpgme-glib-enumtypes.c.template
CLEANFILES += *-t

if HAVE_INTROSPECTION
-include $(INTROSPECTION_MAKEFILE)
INTROSPECTION_GIRS = Gpgme-1.0.gir
INTROSPECTION_SCANNER_ARGS = --add-include-path=$(builddir)
INTROSPECTION_COMPILER_ARGS = --includedir=$(srcdir)

Gpgme-1.0.gir: libgpgme-glib.la
Gpgme_1_0_gir_SCANNERFLAGS = --warn-all --pkg-export=gpgme-glib --namespace=Gpgme --identifier-prefix=GGpg --symbol-prefix=g_gpg $(GPGME_GLIB_STATIC_DEPENDENCIES)
Gpgme_1_0_gir_INCLUDES = GLib-2.0 GObject-2.0 Gio-2.0
Gpgme_1_0_gir_CFLAGS = $(libgpgme_glib_la_CFLAGS)
Gpgme_1_0_gir_LIBS = libgpgme-glib.la
Gpgme_1_0_gir_FILES = $(libgpgme_glib_la_sources) $(libgpgme_glib_la_headers)

CLEANFILES += $(INTROSPECTION_GIRS)
endif

if ENABLE_VAPIGEN
-include $(VAPIGEN_MAKEFILE)

gpgme-glib-1.0.vapi: Gpgme-1.0.gir

VAPIGEN_VAPIS = gpgme-glib-1.0.vapi

gpgme_glib_1_0_vapi_DEPS = gio-2.0
gpgme_glib_1_0_vapi_METADATADIRS = $(srcdir)
gpgme_glib_1_0_vapi_FILES = Gpgme-1.0.gir

noinst_DATA = $(VAPIGEN_VAPIS)

DISTCLEANFILES += $(VAPIGEN_VAPIS)
EXTRA_DIST += Gpgme-1.0.metadata
endif

-include $(top_srcdir)/git.mk
