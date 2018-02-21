/*
** svn $Id$
*******************************************************************************
<<<<<<< HEAD
** Copyright (c) 2002-2016 The ROMS/TOMS Group                               **
=======
** Copyright (c) 2002-2013 The ROMS/TOMS Group                               **
>>>>>>> master
**   Licensed under a MIT/X style license                                    **
**   See License_ROMS.txt                                                    **
*******************************************************************************
**
** Options for Coupled Boundary Layers and Air-Sea Transfer Application.
**
** Application flag:   CBLAST
** Input script:       ocean_cblast.in
*/

/* Basic physics options */

#define UV_ADV
#define UV_COR
#undef  UV_VIS2
#undef  MIX_S_UV
#define SOLVE3D
#define SALINITY
#define NONLIN_EOS

/* Basic numerics options */

#define UV_SADVECTION
#define TS_U3HADVECTION
#define TS_SVADVECTION
#define DJ_GRADPS
<<<<<<< HEAD
#define SPLINES_VDIFF
#define SPLINES_VVISC
=======
#define SPLINES
>>>>>>> master
#define CURVGRID
#define MASKING

/* Outputs */

#define AVERAGES
#define DIAGNOSTICS_UV
#define DIAGNOSTICS_TS
#define STATIONS
#undef  FLOATS

/* Surface and bottom boundary conditions */

#define BULK_FLUXES
#define SOLAR_SOURCE
#define LONGWAVE_OUT /* input is lwrad downward - model computes upward */
#define ANA_RAIN
#define UV_QDRAG
#define ANA_SSFLUX
#define ANA_BSFLUX
#define ANA_BTFLUX

/* Vertical subgridscale turbulence closure */

#undef  LMD_MIXING
#define MY25_MIXING
#ifdef MY25_MIXING
# define N2S2_HORAVG
# define KANTHA_CLAYSON
<<<<<<< HEAD
# define RI_SPLINES
=======
>>>>>>> master
#endif
#ifdef  LMD_MIXING
# define LMD_RIMIX
# define LMD_CONVEC
# define LMD_SKPP
# define LMD_BKPP
<<<<<<< HEAD
# define RI_SPLINES
=======
>>>>>>> master
# define ANA_CLOUD
#endif

/* Open boundary conditions */

#define RADIATION_2D
#define RAMP_TIDES
#define SSH_TIDES
# define ADD_FSOBC
#define UV_TIDES
# define ADD_M2OBC