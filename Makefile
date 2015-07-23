.SUFFIXES:

.SUFFIXES : .o .ftn90 .cdk .cdk90 .c .a

SHELL = /bin/sh

COMPILE = compile

!!!FFLAGS =
FFLAGS="'-C '"

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

# It is assumed that the environment makes available makefile_suffix_rules.inc; e.g.
#     . ssmuse-sh -p /ssm/net/rpn/libs/4.1b/environment-includes_4.3_all

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


OBJECTS= \
	VertInterpConstants.o VerticalGrid.o VerticalInterpolation.o 

obj:	$(OBJECTS)

VertInterpConstants.o: VertInterpConstants.cdk90

VerticalGrid.o: VerticalGrid.ftn90 VerticalGrid_Body.cdk90 VertInterpConstants.o

VerticalInterpolation.o: VerticalInterpolation.ftn90 VerticalInterpolation_Body.ftn90 \
	VertInterpConstants.o VerticalGrid.o


genlib: $(OBJECTS)
#Creer ou mettre a jour la programmatheque 
	ar rcv $(MYLIB) $(OBJECTS)

tarball:  *.ftn90 *.cdk90 *.h  Makefile
	tar cfzv /data/armnraid1/www/ssm/sources/ez_interpv_$(TARRLS)_all.tgz *.ftn90 *.cdk90 *.h Makefile

gen_ec_arch_dir:
#Creer le repertoire $EC_ARCH 
	mkdir -p ./$(EC_ARCH)

locallib: gen_ec_arch_dir \
        $(TEMPLIB)(VertInterpConstants.o)   $(TEMPLIB)(VerticalGrid.o) \
        $(TEMPLIB)(VerticalInterpolation.o)

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
