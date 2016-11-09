Before building:
- select the revision of the compiler; example:
    . ssmuse-sh -x /fs/ssm/hpco/tmp/eccc/201402/03/base  -d /fs/ssm/hpco/exp/intel-2016.1.156
    . ssmuse-sh -p /fs/ssm/hpco/exp/jdm536/code-tools/code-tools_2.0_all
    . ssmuse-sh -d /fs/ssm/main/opt/intelcomp/intelcomp-2016.1.156 -d /fs/ssm/main/opt/openmpi/openmpi-1.6.5/intelcomp-2016.1.156
    export FCOMP=s.f90
    export CCOMP=icc

- select the revision of vgrid; example:
    . ssmuse-sh -d /fs/ssm/eccc/cmd/cmdn/vgrid/5.6.2/intel-2016.1.156

- make librmn available:
    . ssmuse-sh -d /fs/ssm/eccc/mrd/rpn/libs/16.0-alpha

- make the ezinterpv library available, if you are testing the library:
    . ssmuse-sh -d /fs/ssm/eccc/mrd/rpn/ezinterpv/16.0-alpha

ALTOGETHER on Einstein (ubuntu-14 on EC network):
    . s.ssmuse.dot /ssm/net/hpcs/201402/02/base /ssm/net/hpcs/exp/intel2016/01
    . s.ssmuse.dot SI/ezinterpv_16.0-beta-2
    . ssmuse-sh -d /ssm/net/rpn/libs/16.0-beta-2
    make testlib
