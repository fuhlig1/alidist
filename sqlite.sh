package: sqlite
version: "%(tag_basename)s"
tag: "v3.15.0"
source: https://github.com/alisw/sqlite
prefer_system: (?!slc5)
prefer_system_check: |
  printf '#include <sqlite3.h>\nint main(){}\n' | cc -xc - -lsqlite3 -o /dev/null;
  if [ $? -ne 0 ]; then printf "SQLite not found.\n * On RHEL-compatible systems you probably need: sqlite sqlite-devel\n * On Ubuntu-compatible systems you probably need: libsqlite3-0 libsqlite3-dev\n"; exit 1; fi
build_requires:
  - curl
  - autotools
---
#!/bin/bash -ex
rsync -av $SOURCEDIR/ ./
autoreconf -ivf

# Set the environment variables CC and CXX if a compiler is defined in the defaults file
# In case CC and CXX are defined the corresponding compilers are used during compilation 
[[ -z "$CXX_COMPILER" ]] || export CXX=$CXX_COMPILER
[[ -z "$C_COMPILER" ]] || export CC=$C_COMPILER

./configure --disable-tcl --disable-readline --disable-static --prefix=$INSTALLROOT
make
make install
rm -f $INSTALLROOT/lib/*.la
rm -rf $INSTALLROOT/share

# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
MODULEFILE="$MODULEDIR/$PKGNAME"
mkdir -p "$MODULEDIR"
cat > "$MODULEFILE" <<EoF
#%Module1.0
proc ModulesHelp { } {
  global version
  puts stderr "ALICE Modulefile for $PKGNAME $PKGVERSION-@@PKGREVISION@$PKGHASH@@"
}
set version $PKGVERSION-@@PKGREVISION@$PKGHASH@@
module-whatis "ALICE Modulefile for $PKGNAME $PKGVERSION-@@PKGREVISION@$PKGHASH@@"
# Dependencies
module load BASE/1.0
# Our environment
setenv SQLITE_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path PATH $::env(SQLITE_ROOT)/bin
prepend-path LD_LIBRARY_PATH $::env(SQLITE_ROOT)/lib
$([[ ${ARCHITECTURE:0:3} == osx ]] && echo "prepend-path DYLD_LIBRARY_PATH $::env(SQLITE_ROOT)/lib")
EoF
