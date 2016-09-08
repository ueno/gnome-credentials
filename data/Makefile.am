# I chose to use recursive automake so I can use nobase_ and avoid
# 5 different directory declarations
SUBDIRS = icons

resource_files = $(shell $(GLIB_COMPILE_RESOURCES) --sourcedir=$(srcdir) --generate-dependencies $(srcdir)/$(PACKAGE_DESKTOP_NAME).gresource.xml)

appsdir = $(datadir)/applications
apps_DATA = $(PACKAGE_DESKTOP_NAME).desktop

org.gnome.Credentials.desktop: org.gnome.Credentials.desktop.in
	$(AM_V_GEN) $(MSGFMT) --desktop --template $< -d $(top_srcdir)/po -o $@

gsettings_SCHEMAS = $(PACKAGE_DESKTOP_NAME).gschema.xml

@GSETTINGS_RULES@

appstream_XML = $(PACKAGE_DESKTOP_NAME).appdata.xml

org.gnome.Credentials.appdata.xml: org.gnome.Credentials.appdata.xml.in
	$(AM_V_GEN) $(MSGFMT) --xml --template $< -d $(top_srcdir)/po -o $@

@APPSTREAM_XML_RULES@

$(PACKAGE_DESKTOP_NAME).service: $(PACKAGE_DESKTOP_NAME).service.in
	$(AM_V_GEN) sed \
		-e "s|[@]PACKAGE_NAME@|$(PACKAGE_NAME)|g" \
		-e "s|[@]pkgdatadir@|$(pkgdatadir)|g" \
		-e "s|[@]pkglibdir@|$(pkglibdir)|g" \
		-e "s|[@]bindir@|$(bindir)|g" \
		$< > $@

servicedir = $(datadir)/dbus-1/services
service_DATA = $(PACKAGE_DESKTOP_NAME).service

EXTRA_DIST = \
	$(PACKAGE_DESKTOP_NAME).desktop.in \
	$(PACKAGE_DESKTOP_NAME).service.in \
	$(PACKAGE_DESKTOP_NAME).gresource.xml \
	$(gsettings_SCHEMAS) \
	$(PACKAGE_DESKTOP_NAME).appdata.xml.in \
	$(resource_files) \
	$(apps_DATA) \
	$(appstream_XML) \
	$(NULL)

CLEANFILES = \
	$(PACKAGE_DESKTOP_NAME).service \
	$(PACKAGE_DESKTOP_NAME).appdata.xml \
	$(PACKAGE_DESKTOP_NAME).appdata.valid \
	$(apps_DATA) \
	*.valid \
	gschemas.compiled \
	$(NULL)

# For uninstalled use
all-local:
	$(GLIB_COMPILE_SCHEMAS) $(builddir)

-include $(top_srcdir)/git.mk
