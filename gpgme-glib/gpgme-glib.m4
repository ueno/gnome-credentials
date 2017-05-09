dnl The option stuff below is based on the similar code from Automake

# _GPGME_GLIB_MANGLE_OPTION(NAME)
# -------------------------
# Convert NAME to a valid m4 identifier, by replacing invalid characters
# with underscores, and prepend the _GPGME_GLIB_OPTION_ suffix to it.
AC_DEFUN([_GPGME_GLIB_MANGLE_OPTION],
[[_GPGME_GLIB_OPTION_]m4_bpatsubst($1, [[^a-zA-Z0-9_]], [_])])

# _GPGME_GLIB_SET_OPTION(NAME)
# ----------------------
# Set option NAME.  If NAME begins with a digit, treat it as a requested
# Guile version number, and define _GPGME_GLIB_GUILE_VERSION to that number.
# Otherwise, define the option using _GPGME_GLIB_MANGLE_OPTION.
AC_DEFUN([_GPGME_GLIB_SET_OPTION],
[m4_define(_GPGME_GLIB_MANGLE_OPTION([$1]), 1)])

# _GPGME_GLIB_SET_OPTIONS(OPTIONS)
# ----------------------------------
# OPTIONS is a space-separated list of gpgme_glib options.
AC_DEFUN([_GPGME_GLIB_SET_OPTIONS],
[m4_foreach_w([_GPGME_GLIB_Option], [$1], [_GPGME_GLIB_SET_OPTION(_GPGME_GLIB_Option)])])

# _GPGME_GLIB_IF_OPTION_SET(NAME,IF-SET,IF-NOT-SET)
# -------------------------------------------
# Check if option NAME is set.
AC_DEFUN([_GPGME_GLIB_IF_OPTION_SET],
[m4_ifset(_GPGME_GLIB_MANGLE_OPTION([$1]),[$2],[$3])])

dnl GPGME_GLIB_INIT([OPTIONS], [DIR])
dnl ----------------------------
dnl OPTIONS      A whitespace-seperated list of options.
dnl DIR          gpgme_glib submodule directory (defaults to 'gpgme_glib')
AC_DEFUN([GPGME_GLIB_INIT], [
    _GPGME_GLIB_SET_OPTIONS([$1])
    AC_SUBST([GPGME_GLIB_MODULE_DIR],[m4_if([$2],,[gpgme_glib],[$2])])

    AC_REQUIRE([LT_INIT])
    AC_REQUIRE([AM_PATH_GPGME_PTHREAD])
    AM_PATH_GPGME_PTHREAD([1.7.1])
    AC_REQUIRE([VAPIGEN_CHECK])

    GPGME_GLIB_MODULES="gio-2.0 >= 2.44"
    PKG_CHECK_MODULES([GPGME_GLIB_DEPS], [$GPGME_GLIB_MODULES])
    GPGME_GLIB_CFLAGS="$GPGME_GLIB_DEPS_CFLAGS $GPGME_PTHREAD_CFLAGS"
    AC_SUBST([GPGME_GLIB_CFLAGS])
    GPGME_GLIB_LIBS="$GPGME_GLIB_DEPS_LIBS $GPGME_PTHREAD_LIBS"
    AC_SUBST([GPGME_GLIB_LIBS])

    GPGME_GLIB_GIR_INCLUDES="Gio-2.0"
    GPGME_GLIB_SOURCES=""

    AM_CONDITIONAL([GPGME_GLIB_STATIC],[_GPGME_GLIB_IF_OPTION_SET([static],[true],[false])])

    # vapi: vala bindings support
    AM_CONDITIONAL([GPGME_GLIB_VAPI],[ _GPGME_GLIB_IF_OPTION_SET([vapi],[true],[false])])
    _GPGME_GLIB_IF_OPTION_SET([vapi],[
        _GPGME_GLIB_SET_OPTION([gir])
	VAPIGEN_CHECK
    ])

    # gir: gobject introspection support
    AM_CONDITIONAL([GPGME_GLIB_GIR],[ _GPGME_GLIB_IF_OPTION_SET([gir],[true],[false])])
    _GPGME_GLIB_IF_OPTION_SET([gir],[
        GOBJECT_INTROSPECTION_REQUIRE([0.9.6])
    ])

    AC_SUBST(GPGME_GLIB_GIR_INCLUDES)
    AC_SUBST(GPGME_GLIB_SOURCES)
])
