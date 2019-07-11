.SUFFIXES:

.SUFFIXES : .o .F90 .inc .c .a

SHELL = /bin/sh

COMPILE = compile

FFLAGS =

CFLAGS =

SUPP_OPT = -openmp

OPTIMIZ = 2
#OPTIMIZ =  1
#OPTIMIZ =  0
#OPTIMIZ =  0 -debug

MYLIB = libezinterpv90.a

TEMPLIB = ./$(EC_ARCH)/lib_local.a

include $(RPN_TEMPLATE_LIBS)/include/makefile_suffix_rules.inc

UPDATEX =

TARRLS = beta

.PRECIOUS:

OBJECTS= \
	VertInterpConstants_90.o VerticalGrid_90.o VerticalInterpolation_90.o 

obj:	$(OBJECTS)

VertInterpConstants_90.o: VertInterpConstants_90.F90

VerticalGrid_90.o: VertInterpConstants_90.o VerticalGrid_90.F90 VerticalGrid_Body_90.inc

VerticalInterpolation_90.o: VertInterpConstants_90.o VerticalInterpolation_90.F90 \
	VerticalInterpolation_Body_90.inc VerticalGrid_90.o


genlib: $(OBJECTS)
#Creer ou mettre a jour la programmatheque 
	ar rcv $(MYLIB) $(OBJECTS)

tarball:  *.F90 *.inc *.h  Makefile
	tar cfzv /data/armnraid1/www/ssm/sources/ez_interpv_$(TARRLS)_all.tgz *.F90 *.inc *.h Makefile

gen_ec_arch_dir:
#Creer le repertoire $EC_ARCH 
	mkdir -p ./$(EC_ARCH)

locallib: gen_ec_arch_dir \
        $(TEMPLIB)(VertInterpConstants_90.o)   $(TEMPLIB)(VerticalGrid_90.o) \
        $(TEMPLIB)(VerticalInterpolation_90.o)

updlib: 
#mettre a jour la programmatheque 
	r.ar -arch $(EC_ARCH) rcv $(MYLIB) *.o
	if [ "$(UPDATEX)" = "1" ] ; \
	then \
	r.ar -arch $(EC_ARCH) rcv $(LIB_X) *.o ; \
	fi

clean:
#Faire le grand menage. On enleve tous les fichiers sources\ninutiles et les .o 
	-if [ "*.ftn" != "`echo *.ftn`" ] ; \
	then \
	for i in *.ftn ; \
	do \
	fn=`r.basename $$i '.ftn'`; \
	rm -f $$fn.f; \
	done \
	fi
	rm -f *.o *.f90 *.mod *.stb  VInterp_*.Abs

help:
	@echo "Before building, select the revision of the compiler and vgrid; e.g.:"
	@echo "    . ssmuse-sh -d hpcs/201402/01/base"
	@echo "    . ssmuse-sh -d hpcs/201402/01/intel13sp1u2"
	@echo "    . s.ssmuse.dot /ssm/net/cmdn/vgrid/5.0.3/${COMP_ARCH}"
	@echo "  or"
	@echo "    . ssmuse-sh -d hpcs/201402/00/base"
	@echo "    . ssmuse-sh -d hpcs/ext/xlf_13.1.0.10"
	@echo "    . s.ssmuse.dot /ssm/net/cmdn/vgrid/5.0.3/${COMP_ARCH}"
	@echo " "
