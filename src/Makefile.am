bin_PROGRAMS = gnome-credentials

gnome_credentials_SOURCES =			\
	main.vala				\
	window.vala				\
	backend.vala				\
	editor.vala				\
	generator.vala				\
	widget-factory.vala			\
	list-panel.vala				\
	password-list-panel.vala		\
	key-list-panel.vala			\
	secret-backend.vala			\
	secret-editor.vala			\
	secret-widget-factory.vala		\
	gpg-backend.vala			\
	gpg-editor.vala				\
	gpg-generator.vala			\
	gpg-fetcher.vala			\
	gpg-widget-factory.vala			\
	gpg-helper.vala				\
	ssh-backend.vala			\
	ssh-parser.vala				\
	ssh-editor.vala				\
	ssh-generator.vala			\
	ssh-widget-factory.vala			\
	model-button.vala			\
	list-box-helper.vala			\
	utils.vala				\
	resources.c

gnome_credentials_LDADD =				\
	$(DEPS_LIBS)					\
	$(LIBGCRYPT_LIBS)				\
	$(top_builddir)/gpgme-glib/libgpgme-glib.la	\
	$(top_builddir)/libgd/libgd.la

gresource_file = $(top_srcdir)/data/org.gnome.Credentials.gresource.xml

AM_CPPFLAGS = -I$(top_srcdir) -include config.h \
	$(DEPS_CFLAGS) $(LIBGCRYPT_CFLAGS) -I$(top_srcdir)/libgd
AM_VALAFLAGS =					\
	--target-glib=2.38			\
	--vapidir=$(srcdir)			\
	--vapidir=$(top_srcdir)/gpgme-glib	\
	--vapidir=$(top_builddir)/gpgme-glib	\
	--vapidir=$(top_srcdir)/libgd		\
	--vapidir=$(top_builddir)/libgd		\
	--pkg config				\
	--pkg gcrypt				\
	--pkg gd-1.0				\
	--pkg gpgme-glib-1.0			\
	--pkg gtk+-3.0				\
	--pkg libsecret-1			\
	--pkg pango				\
	--pkg posix				\
	--gresources $(gresource_file)

resource_files = $(shell $(GLIB_COMPILE_RESOURCES) --generate-dependencies --sourcedir=$(top_srcdir)/data $(gresource_file))
resources.c: $(gresource_file) $(resource_files)
	$(AM_V_GEN) $(GLIB_COMPILE_RESOURCES) --target=$@ --sourcedir=$(top_srcdir)/data --generate-source $<

EXTRA_DIST = config.vapi

GITIGNOREFILES = *.c *.stamp

-include $(top_srcdir)/git.mk
