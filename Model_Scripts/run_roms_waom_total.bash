#!/bin/bash
#
# svn $Id$
#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
# Copyright (c) 2002-2013 The ROMS/TOMS Group                           :::
#   Licensed under a MIT/X style license                                :::
#   See License_ROMS.txt                                                :::
#::::::::::::::::::::::::::::::::::::::::::::::::::::: Hernan G. Arango :::
#                                                                       :::
# ROMS/TOMS Compiling Script                                            :::
#                                                                       :::
# Script to compile an user application where the application-specific  :::
# files are kept separate from the ROMS source code.                    :::
#                                                                       :::
# Q: How/why does this script work?                                     :::
#                                                                       :::
# A: The ROMS makefile configures user-defined options with a set of    :::
#    flags such as ROMS_APPLICATION. Browse the makefile to see these.  :::
#    If an option in the makefile uses the syntax ?= in setting the     :::
#    default, this means that make will check whether an environment    :::
#    variable by that name is set in the shell that calls make. If so   :::
#    the environment variable value overrides the default (and the      :::
#    user need not maintain separate makefiles, or frequently edit      :::
#    the makefile, to run separate applications).                       :::
#                                                                       :::
# Usage:                                                                :::
#                                                                       :::
#    ./build.bash [options]                                             :::
#                                                                       :::
# Options:                                                              :::
#                                                                       :::
#    -j [N]      Compile in parallel using N CPUs                       :::
#                  omit argument for all available CPUs                 :::
#    -noclean    Do not clean already compiled objects                  :::
#                                                                       :::
# Notice that sometimes the parallel compilation fail to find MPI       :::
# include file "mpif.h".                                                :::
#                                                                       :::
#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

module purge
module unload intel-fc intel-cc
module load intel-oneapi-compilers-classic/2021.6.0 intel-oneapi-mpi/2021.6.0 intel-oneapi-mkl/2022.1.0
#module load cmake
#module load netcdf-c/4.8.1
#module load netcdf-fortran/4.5.4
#module load intel-oneapi-compilers-classic/2021.6.0 intel-oneapi-mpi/2021.6.0
#module load hdf5/1.10.5
module load cmake
module load netcdf-fortran/4.5.4
module load netcdf-c/4.8.1

parallel=1
clean=1

while [ $# -gt 0 ]
do
  case "$1" in
    -j )
      shift
      parallel=1
      test=`echo $1 | grep '^[0-9]\+$'`
      if [ "$test" != "" ]; then
        NCPUS="-j $1"
        shift
      else
        NCPUS="-j"
      fi
      ;;

    -noclean )
      shift
      clean=0
      ;;

    * )
      echo ""
      echo "$0 : Unknown option [ $1 ]"
      echo ""
      echo "Available Options:"
      echo ""
      echo "-j [N]      Compile in parallel using N CPUs"
      echo "              omit argument for all avaliable CPUs"
      echo "-noclean    Do not clean already compiled objects"
      echo ""
      exit 1
      ;;
  esac
done

# Set the CPP option defining the particular application. This will
# determine the name of the ".h" header file with the application
# CPP definitions.
#export   ROMS_APPLICATION=WAOM
export   ROMS_APPLICATION=WAOM_TOTAL

# The path to the user's local current ROMS source code.
export   MY_ROMS_DIR=/scratch/project_2000789/muramarg/ROMSIceShelfFISOC
export   COMPILERS=${MY_ROMS_DIR}/Compilers

# extra for FISOC:
#export MAKE_SHAREDLIB=Yes
#export LIBDIR=/projappl/project_2000339/installs/ROMS_FX4
#export MY_CPP_FLAGS=" -DFISOC "
export FFLAGS="$FFLAGS -g -check all -fpe0 -O0 -warn -traceback -debug extended  -check bounds"


# Set tunable CPP options.
#
#export      MY_CPP_FLAGS="-DAVERAGES"
#export      MY_CPP_FLAGS="${MY_CPP_FLAGS} -DDEBUGGING"

export           USE_MPI=on            # distributed-memory parallelism
export        USE_MPIF90=on            # compile with mpif90 script
export         which_MPI=openmpi       # compile with OpenMPI library
export              FORT=ifort
export         USE_DEBUG=on            # use Fortran debugging flags
export         USE_LARGE=on            # activate 64-bit compilation
export       USE_NETCDF4=on            # compile with NetCDF-4 library
export   USE_PARALLEL_IO=on            # Parallel I/O with Netcdf-4/HDF5
export       USE_MY_LIBS=on            # use my library paths below

export     MY_HEADER_DIR=${MY_ROMS_DIR}/ROMS/Include
export MY_ANALYTICAL_DIR=${MY_ROMS_DIR}
export            BINDIR=/scratch/project_2000789/muramarg/ROMSIceShelfFISOC/ROMS
# Put the f90 files in a project specific Build directory to avoid conflict
# with other projects.
export       SCRATCH_DIR=${MY_ROMS_DIR}/Build

export       NETCDF_INCDIR="${NETCDF_FORTRAN_INSTALL_ROOT}/include"
#export       NETCDF_LIBDIR="/appl/spack/install-tree/intel-19.0.4/netcdf-fortran-4.4.4-nbpz5p/lib"
export       NC_CONFIG=${NETCDF_C_INSTALL_ROOT}/nc-config

# Go to the users source directory to compile. The options set above will
# pick up the application-specific code from the appropriate place.
cd ${MY_ROMS_DIR}


# Remove build directory.
if [ $clean -eq 1 ]; then
  make clean
fi

# Compile (the binary will go to BINDIR set above).
if [ $parallel -eq 1 ]; then
  make $NCPUS
else
  make
fi

#cp $(LIBDIR)/liboceanM.so $(LIBDIR)/liboceanM_FX4.so

