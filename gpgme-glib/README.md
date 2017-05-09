gpgme-glib
==========

gpgme-glib is a GObject wrapper around
[GPGME](https://www.gnupg.org/documentation/manuals/gpgme/).

In addtion to wrapping GPGME objects in GObject classes, it also
integrates GPGME's event handling into GLib event loop.

Usage
-----

In order to use gpgme-glib, an application using autotools needs to:

1. from the top-level project directory, add the submodule:
    - `git submodule add git://github.com/ueno/gpgme-glib.git`

2. in `autogen.sh`, it is recommended to add before autoreconf call:
    - `git submodule update --init --recursive`

3. in top-level `Makefile.am`:
    - add `-I gpgme-glib` to `ACLOCAL_AMFLAGS`
    - add `gpgme-glib` to `SUBDIRS`, before the project src directory

4. in project `configure.ac`:
    - add `GPGME_GLIB_INIT([list-of-options])` after your project
      dependencies checks
    - add `gpgme-glib/Makefile` to `AC_CONFIG_FILES`

5. from your program `Makefile.am`, you may now for example:
    - link with `$(top_builddir)/gpgme-glib/gpgme-glib.la`, and include
      `<gpgme-glib/gpgme-glib.h>` (adjust your `AM_CPPFLAGS` as necessary)

GPGME_GLIB_INIT options
-----------------------

- static

- vapi

- gir
