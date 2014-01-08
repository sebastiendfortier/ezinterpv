.SUFFIXES:

.SUFFIXES : .o .ftn90 .cdk .cdk90 .c .a

SHELL = /bin/sh

COMPILE = compile

FFLAGS =

CFLAGS =

SUPP_OPT = -openmp

OPTIMIZ = 2
#OPTIMIZ =  1
#OPTIMIZ =  0
#OPTIMIZ =  0 -debug

MYLIB = libezinterpv.a

TEMPLIB = ./$(EC_ARCH)/lib_local.a

UPDATEX =

TARRLS = beta

.PRECIOUS:

include $(ARMNLIB)/include/makefile_suffix_rules.inc

# Over-ride the default compile rules so as to pick up the *.h in the current directory
.cdk90.o:
	s.compile -includes . -O $(OPTIMIZ) -optf "=$(FFLAGS)" $(SUPP_OPT) $(FTN90_SUPP_OPT) -src $<

.cdk90.a        : 
	s.compile -includes . -O $(OPTIMIZ) -optf "=$(FFLAGS)" $(SUPP_OPT) $(FTN90_SUPP_OPT) -src $<
	ar rv $@ $*.o

.ftn90.o:
	s.compile -includes . -O $(OPTIMIZ) -defines "=$(DEFINE)" -optf "=$(FFLAGS)" $(SUPP_OPT) $(FTN90_SUPP_OPT) -src $<

.ftn90.a        : 
	s.compile -includes . -O $(OPTIMIZ) -defines "=$(DEFINE)" -optf "=$(FFLAGS)" $(SUPP_OPT) $(FTN90_SUPP_OPT) -src $<
	ar rv $@ $*.o



VertInterpConstants.o: VertInterpConstants.cdk90 ViConstants_f90.h

ViIfc.o: ViIfc.ftn90 ViIfc_Body.ftn90 VertInterpConstants.o VerticalGrid.o VerticalInterpolation.o

VerticalGrid.o: VerticalGrid.cdk90 VerticalGrid_Body.cdk90 VertInterpConstants.o

VerticalInterpolation.o: VerticalInterpolation.ftn90 VerticalInterpolation_Body.ftn90 \
	VertInterpConstants.o VerticalGrid.o

OBJECTS= \
	VertInterpConstants.o VerticalGrid.o VerticalInterpolation.o ViIfc.o

genlib: $(OBJECTS)
#Creer ou mettre a jour la programmatheque 
	r.ar -arch $(EC_ARCH) rcv $(MYLIB) $(OBJECTS)

tarball:  *.ftn90 *.cdk90 *.h  Makefile
	tar cfzv /data/armnraid1/www/ssm/sources/ez_interpv_$(TARRLS)_all.tgz *.ftn90 *.cdk90 *.h Makefile 

obj:	$(OBJECTS)

gen_ec_arch_dir:
#Creer le repertoire $EC_ARCH 
	mkdir -p ./$(EC_ARCH)

locallib: gen_ec_arch_dir \
        $(TEMPLIB)(VertInterpConstants.o)   $(TEMPLIB)(VerticalGrid.o) \
        $(TEMPLIB)(VerticalInterpolation.o)  $(TEMPLIB)(ViIfc.o)

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
	@echo "    . ssmuse-sh -d hpcs/13b/03/base
	@echo "    . s.ssmuse.dot pgi9xx rmnlib-dev"
	@echo "    . s.ssmuse.dot CMDN/vgrid/3.2.0"
	@echo "  or"
	@echo "    . ssmuse-sh -d hpcs/13b/03/base
	@echo "    . s.ssmuse.dot Xlf13.107 rmnlib-dev"
	@echo "    . s.ssmuse.dot CMDN/vgrid/3.2.0"
	@echo " "
