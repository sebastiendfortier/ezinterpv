.SUFFIXES:

.SUFFIXES : .o .ftn90 .ftn .cdk .cdk90 .o

SHELL = /bin/sh

COMPILE = compile

FFLAGS =

CFLAGS =

#OPTIMIZ = -O 2
#OPTIMIZ = -O 1
OPTIMIZ = -O 0
#OPTIMIZ = -O 0 -debug

LIBRMN = rmn_015
TEMPLIB = ../$(EC_ARCH)/lib/libezinterpv.a

default: test

# Explicit path, /users/dor/arma/jbl/home1/SVN_checkouts/ez_interpv/TestFiles, is
# given here so as to over-ride the (old) include files that are still hanging
# around in armnlib:
.ftn90.o:
	s.compile -includes /users/dor/arma/jbl/home1/SVN_checkouts/ez_interpv/TestFiles /users/dor/arma/jbl/home1/SVN_checkouts/ez_interpv/TestFiles ../$(EC_ARCH)/include -abi $(ABI) $(OPTIMIZ) -opt "=$(FFLAGS)" \
	-src $<

.cdk90.o:
	s.compile -abi $(ABI) $(OPTIMIZ) -opt "=$(FFLAGS)" \
	-src $<

.ftn.o:
	s.compile -abi $(ABI) $(OPTIMIZ) -opt "=$(FFLAGS)" -src $<

.c.o:
	s.compile -abi $(ABI) $(OPTIMIZ) -opt "=$(CFLAGS)" -src $<

#.f.o:
#	s.compile -abi $(ABI) $(OPTIMIZ) -opt "=$(FFLAGS)" -src $<

TEST_OBJECTS=\
	VertInterpConstants.o  VerticalGrid.o  VerticalInterpolation.o ViIfc.o TestVI.o

INTERPV_OBJECTS=\
	Interp1D_Constants.o Extrap1D_LapseRate.o Extrap1D_Fixed.o Extrap1D_Surface.o \
	Extrap1D_SurfaceWind.o Interp1D_CubicLagrange.o Interp1D_CubicWithDerivs.o \
	Interp1D_FindPos.o Interp1D_Linear.o Interp1D_NearestNeighbour.o Extrap1D_Abort.o

SPEED_OBJECTS=\
	VertInterpConstants.o  VerticalGrid.o  VerticalInterpolation.o SpeedConvertP.o

copyHlocal:
	cp ../*.h .

removeH:
	rm `cd ..; ls *.h`

copyMODlocal:
	cp ../*.mod .

removeMOD:
	rm `cd ..; ls *.mod`

testWithInterpv: copyHlocal copyMODlocal TestVI.o removeMOD removeH
	cp ../*.o .
	cp ../../interpv/*.o .
	s.compile -o TestVInterp_$(BASE_ARCH).Abs -obj $(INTERPV_OBJECTS) $(TEST_OBJECTS) \
	-abi$(ABI) -libappl descrip -librmn $(LIBRMN)

test:	copyHlocal copyMODlocal TestVI.o removeMOD removeH
	cp ../*.o .
	s.compile -o TestVInterp_$(BASE_ARCH).Abs -obj $(TEST_OBJECTS) \
	-abi$(ABI) -libappl descrip -librmn $(LIBRMN)

testlib: TestVI.o
	(. s.ssmuse.dot /ssm/net/rpn/libs/15.0; s.compile -includes ../$(EC_ARCH)/include -libpath . ../$(EC_ARCH)/lib -libappl ezinterpv descrip -o TestVInterp_$(BASE_ARCH).Abs -obj TestVI.o \
	-abi$(ABI) -librmn $(LIBRMN))

copielocale:
	cp ../*.o . 
	cp ../*.mod .

SpeedConvert: copielocale SpeedConvertP.o
	s.compile -o SpeedConvertP_$(BASE_ARCH).Abs -obj $(SPEED_OBJECTS) \
	-abi$(ABI) -librmn $(LIBRMN)

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
	rm -f *.o *.f90 *.mod *.stb  *.Abs
	rm *.h
