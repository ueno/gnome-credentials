AUTOMAKE_OPTIONS = subdir-objects
CLEANFILES =
DISTCLEANFILES =
MAINTAINERCLEANFILES =
EXTRA_DIST =
noinst_DATA =

noinst_LTLIBRARIES = libegg-secmem.la libegg-private.la

libegg_secmem_la_SOURCES =			\
	egg-secure-memory.h			\
	egg-secure-memory.c

libegg_private_la_sources =			\
	egg-secure-entry-buffer.c
libegg_private_la_headers =			\
	egg-secure-entry-buffer.h

libegg_private_la_SOURCES = $(libegg_private_la_sources)
libegg_private_la_CFLAGS = $(EGG_CFLAGS) -I$(top_srcdir)
libegg_private_la_LIBADD = $(EGG_LIBS) libegg-secmem.la

noinst_HEADERS = $(libegg_private_la_headers)

if HAVE_INTROSPECTION
-include $(INTROSPECTION_MAKEFILE)
INTROSPECTION_GIRS = Egg-1.0.gir

Egg-1.0.gir: libegg-private.la
Egg_1_0_gir_SCANNERFLAGS =			\
	--warn-all				\
	--c-include="egg-private.h"		\
	--namespace=Egg
Egg_1_0_gir_INCLUDES = Gio-2.0 Gdk-3.0 Gtk-3.0
Egg_1_0_gir_CFLAGS = $(libegg_private_la_CFLAGS)
Egg_1_0_gir_LIBS = libegg-private.la
Egg_1_0_gir_FILES = $(libegg_private_la_sources) $(libegg_private_la_headers)

noinst_DATA += $(srcdir)/Egg-1.0.gir
EXTRA_DIST += $(srcdir)/Egg-1.0.gir
MAINTAINERCLEANFILES += $(srcdir)/Egg-1.0.gir
endif

if ENABLE_VAPIGEN
-include $(VAPIGEN_MAKEFILE)

egg-private-1.0.vapi: Egg-1.0.gir

VAPIGEN_VAPIS = egg-private-1.0.vapi

egg_private_1_0_vapi_DEPS = gio-2.0 gtk+-3.0
egg_private_1_0_vapi_METADATADIRS = $(srcdir)
egg_private_1_0_vapi_FILES = Egg-1.0.gir

egg-private.deps: Makefile
	$(AM_V_GEN) echo $(egg_private_vapi_DEPS) | tr ' ' '\n' > $@

noinst_DATA += $(VAPIGEN_VAPIS)
EXTRA_DIST += $(VAPIGEN_VAPIS) egg-private.deps
MAINTAINERCLEANFILES += $(VAPIGEN_VAPIS) egg-private.deps
endif

-include $(top_srcdir)/git.mk
