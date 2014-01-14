#! /usr/bin/env python
# -*- coding: utf-8 -*-
#
# bh-ezinterpv.py
 
from os import environ
import sys
from bh import bhlib, actions
import os

 
def _init(b):
    global compiler

    environ["BH_PROJECT_NAME"]    = "ezinterpv"
    environ["BH_PACKAGE_VERSION"] = "1.5c"
    environ["LIBEZINTERPV_VERSION"]="1.5c"

    environ["BH_VGRID_REVISION"] = "3.2.0"
    
    compiler = compiler_in.lower()
    if compiler.startswith("intel"):
        compiler = "intel"
        environ["BH_PACKAGE_NAMES"] = "libezinterpv-intelsp1"
        environ["BH_VGRID_REVISION"] = "4.4.0-a2"

    # Identify a default compiler, according to the platform
    elif b.platform.startswith("ubuntu-10") or b.platform.startswith("ubuntu-12"):
        compiler = "pgi9xx"
        environ["BH_PACKAGE_NAMES"] = "libezinterpv-pgi9xx"

    elif b.platform.startswith("aix"):
        compiler = "xlf13"
        environ["BH_PACKAGE_NAMES"] = "libezinterpv-xlf13"

    else:
        compiler = "unidentified"
        environ["BH_PACKAGE_NAMES"] = "libezinterpv"

    print "\n\nProducing SSM package for compiler, ", compiler, "\n"

    environ["BH_SVN_REVISION"]   = "4"
    environ["SVNDIR"] = "%(BH_HERE_DIR)s/ezinterpv-svn%(BH_SVN_REVISION)s" % environ
    environ["OTHER_UTILS"] = "%(BH_HERE_DIR)s/other_utils_%(BASE_ARCH)s" % environ
    environ["BH_PULL_SOURCE"] = "%(SVNDIR)s.tgz" % environ
    environ["BH_CONTROL_DIR"] = "%s/control/%s/.ssm.d" % (environ["BH_HERE_DIR"],environ["BH_PACKAGE_NAMES"])

    # platform-specific
    if b.platform.dist == "aix":
        environ["OBJECT_MODE"] = b.platform.obj_mode


def _pull(b):
    # Automatically obtain the selected revision, unless unable
    if not os.system("which svn > /dev/null 2>&1"):
        b.shell("""mkdir -p $SVNDIR""") 
        b.shell("""rm -f ${SVNDIR}.tgz; cd ${SVNDIR}; svn co svn://mrbsvn/appllibs/misc/ez_interpv/Trunk@${BH_SVN_REVISION} .""")
        b.shell("""cd ${SVNDIR}; tar czvf ${BH_PULL_SOURCE} .""")
    elif os.system("ls %(SVNDIR)s.tgz > /dev/null 2>&1" % environ):
        print "ERROR:  svn not available.  Execute first on Linux."
        exit(1)


def _clean(b):
    b.shell("""
            cd ${BH_BUILD_DIR}
            make clean
            """)


def _make(b):
    global compiler

    if compiler == "xlf13":
        ssmuse_st = """
           . /ssm/net/hpcs/shortcuts/get_ordenv.sh 20130617
           . ssmuse-sh -d hpcs/13b/03/base
           . s.ssmuse.dot Xlf13.107 devtools
           s.use gmake as make
           s.use gnu_find as find
           . s.ssmuse.dot CMDN/vgrid/${BH_VGRID_REVISION}"""

    elif compiler == "pgi9xx":
        ssmuse_st = """
           . /ssm/net/hpcs/shortcuts/ssmuse_ssm_v10.sh
           . /ssm/net/hpcs/shortcuts/get_ordenv.sh 20130617
           . ssmuse-sh -d hpcs/13b/03/base
           . s.ssmuse.dot pgi9xx devtools
           . s.ssmuse.dot CMDN/vgrid/${BH_VGRID_REVISION}"""

    elif compiler == "intel":
        ssmuse_st = """
           . ssmuse-sh -d /ssm/net/hpcs/201311/00-test/base -d /ssm/net/hpcs/201311/00-test/intel13sp1
           . ssmuse-sh -p /home/ordenv/ssm-domains-cmdn/vgrid/vgriddescriptors_${BH_VGRID_REVISION}"""

    #### NOTE:  COPYING THE MAKEFILE IS A TEMPORARY MEASURE
    b.shell("""
           (%s
            mkdir -p ${BH_CONTROL_DIR}
            BH_CONTROL_FILE=${BH_CONTROL_DIR}/control
            echo "Package: ezinterpv" > ${BH_CONTROL_FILE}
            echo "Version: ${LIBEZINTERPV_VERSION}" >> ${BH_CONTROL_FILE}
            echo "Platform: ${ORDENV_PLAT}" >> ${BH_CONTROL_FILE}
            echo "Maintainer: armajbl" >> ${BH_CONTROL_FILE}
            echo "BuildInfo: Compiled from SVN revision ${BH_SVN_REVISION}, and linked with vgrid_descriptor revision ${BH_VGRID_REVISION}" >> ${BH_CONTROL_FILE}
            echo "Description:  vertical interpolation package" >> ${BH_CONTROL_FILE}
            cp ${BH_CONTROL_FILE} ${BH_CONTROL_FILE}.template

            BH_POST_FILE=${BH_CONTROL_DIR}/post-install
            echo "#!/bin/bash\n" > ${BH_POST_FILE}
            echo "calledScript=\$0" >> ${BH_POST_FILE}
            echo "../ssm_RPN_post-install.sh \$calledScript \$@ EC_LD_LIBRARY_PATH EC_INCLUDE_PATH" >> ${BH_POST_FILE}

            cd ${BH_BUILD_DIR}
            make genlib
           )""" % ssmuse_st)

def _install(b):
    global compiler
    
    if compiler == "xlf13":
        ssmuse_st = """
            . s.ssmuse.dot Xlf13.107"""

    elif compiler == "pgi9xx":
        ssmuse_st = """
            . s.ssmuse.dot pgi9xx"""

    elif compiler == "intel":
        ssmuse_st = """
            . ssmuse-sh -d /ssm/net/hpcs/201311/00-test/base -d /ssm/net/hpcs/201311/00-test/intel13sp1"""

    b.shell("""
        (%s
         mkdir -p ${BH_INSTALL_DIR}/lib/${EC_ARCH}
         mkdir -p ${BH_INSTALL_DIR}/include/${EC_ARCH}

         (cd ${BH_BUILD_DIR}; cp *.mod VertInterp_f90.h ViConstants_f90.h ${BH_INSTALL_DIR}/include/${EC_ARCH})

         cp ${BH_BUILD_DIR}/libezinterpv.a ${BH_INSTALL_DIR}/lib/${EC_ARCH}
         (cd ${BH_INSTALL_DIR}/lib/${EC_ARCH}; mv libezinterpv.a libezinterpv_${LIBEZINTERPV_VERSION}.a)
         (cd ${BH_INSTALL_DIR}/lib/${EC_ARCH}; ln -s libezinterpv_${LIBEZINTERPV_VERSION}.a libezinterpv.a)
        )""" % ssmuse_st)

if __name__ == "__main__":
    # parse command line
    # N.B.:  This requires -c to be the FIRST argument
    if ((len(sys.argv) > 1) and (sys.argv[1] == "-c")):
        compiler_in = sys.argv[2]
        sys.argv[1:] = sys.argv[3:]
    else:
        compiler_in = 'default'

    dr, b = bhlib.init(sys.argv, bhlib.PackageBuilder)
    b.actions.set("init", _init)
    b.actions.set("pull", [_pull, actions.pull.unpack_tgz])
    b.actions.set("clean", _clean)
    b.actions.set("make", _make)
    b.actions.set("install", _install)
    b.actions.set("package", actions.package.to_ssm)
 
    b.supported_platforms = [
        "linux26-i386",
        "ubuntu-10.04-amd64-64",
        "ubuntu-12.10-amd64-64",
        "ubuntu-12.04-amd64-64",
        "ubuntu-10.04-i386",
        "ubuntu-10.04-i386-32",
        "aix-5.3-ppc-32",
        "aix-5.3-ppc-64",
        "aix-7.1-ppc7-32",
        "aix-7.1-ppc7-64",
    ]
    dr.run(b)

#ubuntu12:  arxt02
#./bh-ezinterpv.py -w /tmp/bh-ezinterpv -p ubuntu-12.04-amd64-64 --local

#AIX
#./bh-ezinterpv.py -w /tmp/bh-ezinterpv -p aix-7.1-ppc7-64 --local

#ubuntu10:  pollux
#./bh-ezinterpv.py -w /tmp/bh-ezinterpv -p ubuntu-10.04-amd64-64 --local

#./bh-ezinterpv.py -w /tmp/bh-ezinterpv -s pull -p ubuntu-10.04-amd64-64
#./bh-ezinterpv.py -w /tmp/bh-ezinterpv -s pull -p ubuntu-10.04-x86-64

#ubuntu10 with compiler intel13sp1:  pollux
#./bh-ezinterpv.py -c IntelSp1 -w /tmp/bh-ezinterpv -p ubuntu-10.04-amd64-64 --local


#. /ssm/net/hpcs/shortcuts/ssmuse_ssm_v10.sh
#. ssmuse-sh -p hpcs/tools/master/bh_0.10_all
#. ssmuse-sh -d /ssm/net/hpcs/13b/03/base

#dump -Ttv libgraphbeta_014.a | grep ar
