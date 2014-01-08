#! /usr/bin/env python
# -*- coding: utf-8 -*-
#
# bh-ezinterpv_1.5b-pgi9xx-xlf13.py
 
from os import environ
import sys
from bh import bhlib, actions
import os

 
def _init(b):
    environ["BH_PROJECT_NAME"]  = "ezinterpv"
    environ["BH_PACKAGE_NAMES"] = "ezinterpv"

    if b.platform.startswith("ubuntu-10") or b.platform.startswith("ubuntu-12"):
        environ["BH_PACKAGE_VERSION"] = "1.5b-pgi9xx"
    elif b.platform.startswith("aix"):
        environ["BH_PACKAGE_VERSION"] = "1.5b-xlf13"

    environ["LIBEZINTERPV_VERSION"]="1.5b"
    environ["SVNDIR"] = "%(BH_HERE_DIR)s/ezinterpv-svn" % environ
    environ["OTHER_UTILS"] = "%(BH_HERE_DIR)s/other_utils_%(BASE_ARCH)s" % environ
    environ["BH_PULL_SOURCE"] = "%(SVNDIR)s.tgz" % environ
    environ["BH_CONTROL_FILE"] = "./control/ezinterpv/.ssm.d/control"
    environ["BH_SVN_REVISION"]   = "830"
    environ["BH_VGRID_REVISION"] = "3.2.0"

    # platform-specific
    if b.platform.dist == "aix":
        environ["OBJECT_MODE"] = b.platform.obj_mode

def _pull(b):
    # Automatically obtain the selected revision, unless unable
    if not os.system("which svn"):
        b.shell("""mkdir -p $SVNDIR""") 
        b.shell("""rm -f ezinterpv-svn.tgz; cd ${SVNDIR}; svn co svn://mrbsvn/pub/trunk/ez_interpv@${BH_SVN_REVISION} .""")
        b.shell("""cd ${SVNDIR}; tar czvf ${BH_PULL_SOURCE} .""")

def _clean(b):
    b.shell("""
            cd ${BH_BUILD_DIR}
            make clean
            """)

def _make(b):
    if b.platform.dist == "aix":
        ssmuse_st = """\
           . /ssm/net/hpcs/shortcuts/get_ordenv.sh 20130617; \
           . ssmuse-sh -d hpcs/13b/03/base; \
           . s.ssmuse.dot Xlf13.107 devtools; \
           s.use gmake as make; \
           s.use gnu_find as find"""

    elif b.platform.startswith("linux") or b.platform.startswith("ubuntu"):
        ssmuse_st = """\
           . /ssm/net/hpcs/shortcuts/ssmuse_ssm_v10.sh; \
           . /ssm/net/hpcs/shortcuts/get_ordenv.sh 20130617; \
           . ssmuse-sh -d hpcs/13b/03/base; \
           . s.ssmuse.dot pgi9xx devtools"""

    #### NOTE:  COPYING THE MAKEFILE IS A TEMPORARY MEASURE
    b.shell("""
           (%s
            . s.ssmuse.dot CMDN/vgrid/${BH_VGRID_REVISION}
            echo "Package: ezinterpv" > ${BH_CONTROL_FILE}
            echo "Version: ${LIBEZINTERPV_VERSION}" >> ${BH_CONTROL_FILE}
            echo "Platform: ${ORDENV_PLAT}" >> ${BH_CONTROL_FILE}
            echo "Maintainer: armajbl" >> ${BH_CONTROL_FILE}
            echo "BuildInfo: Compiled from SVN revision ${BH_SVN_REVISION}, and linked with vgrid_descriptor revision ${BH_VGRID_REVISION}" >> ${BH_CONTROL_FILE}
            echo "Description:  vertical interpolation package" >> ${BH_CONTROL_FILE}
            cp ${BH_CONTROL_FILE} ${BH_CONTROL_FILE}.template

            cd ${BH_BUILD_DIR}
            make genlib
           )""" % ssmuse_st)

def _install(b):
    if b.platform.dist == "aix":
        ssmuse_st = """
            . s.ssmuse.dot Xlf13.107"""

    elif b.platform.startswith("linux") or b.platform.startswith("ubuntu"):
        ssmuse_st = """
            . s.ssmuse.dot pgi9xx"""

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
#./bh-ezinterpv_1.5b-pgi9xx-xlf13.py -w /tmp/bh-ezinterpv -p ubuntu-12.04-amd64-64 --local

#AIX
#./bh-ezinterpv_1.5b-pgi9xx-xlf13.py -w /tmp/bh-ezinterpv -p aix-7.1-ppc7-64 --local

#ubuntu10:  pollux
#./bh-ezinterpv_1.5b-pgi9xx-xlf13.py -w /tmp/bh-ezinterpv -p ubuntu-10.04-amd64-64 --local

#./bh-ezinterpv_1.5b-pgi9xx-xlf13.py -w /tmp/bh-ezinterpv -s pull -p ubuntu-10.04-amd64-64
#./bh-ezinterpv_1.5b-pgi9xx-xlf13.py -w /tmp/bh-ezinterpv -s pull -p ubuntu-10.04-x86-64


#. /ssm/net/hpcs/shortcuts/ssmuse_ssm_v10.sh
#. ssmuse-sh -p hpcs/tools/master/bh_0.10_all
#. ssmuse-sh -d /ssm/net/hpcs/13b/03/base

#dump -Ttv libgraphbeta_014.a | grep ar
