bin_PROGRAMS = gnome-credentials

gnome_credentials_SOURCES =			\
	main.vala				\
	window.vala				\
	backend.vala				\
	widget-factory.vala			\
	list-panel.vala				\
	password-list-panel.vala		\
	secret-backend.vala			\
	secret-widget-factory.vala		\
	key-list-panel.vala			\
	gpg-backend.vala			\
	gpg-widget-factory.vala			\
	gpg-helper.vala				\
	list-box-helper.vala			\
	utils.vala				\
	resources.c

gnome_credentials_LDADD =				\
	$(DEPS_LIBS)					\
	$(top_builddir)/gpgme-glib/libgpgme-glib.la	\
	$(top_builddir)/libgd/libgd.la

gresource_file = $(top_srcdir)/data/org.gnome.Credentials.gresource.xml

AM_CPPFLAGS = -include config.h $(DEPS_CFLAGS) -I$(top_srcdir)/libgd
AM_VALAFLAGS =					\
	--target-glib=2.38			\
	--vapidir=$(srcdir)			\
	--vapidir=$(top_srcdir)/gpgme-glib	\
	--vapidir=$(top_builddir)/gpgme-glib	\
	--vapidir=$(top_srcdir)/libgd		\
	--vapidir=$(top_builddir)/libgd		\
	--pkg config				\
	--pkg gtk+-3.0				\
	--pkg pango				\
	--pkg libsecret-1			\
	--pkg gpgme-glib			\
	--pkg gd-1.0				\
	--pkg posix				\
	--gresources $(gresource_file)

resource_files = $(shell $(GLIB_COMPILE_RESOURCES) --generate-dependencies --sourcedir=$(top_srcdir)/data $(gresource_file))
resources.c: $(gresource_file) $(resource_files)
	$(AM_V_GEN) $(GLIB_COMPILE_RESOURCES) --target=$@ --sourcedir=$(top_srcdir)/data --generate-source $<

EXTRA_DIST = config.vapi

GITIGNOREFILES = *.c *.stamp

-include $(top_srcdir)/git.mk
