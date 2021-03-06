# Copyright(c) 1986 Association of Universities for Research in Astronomy Inc.

include <math/gsurfit.h>
include "dgsurfitdef.h"

# GSCOPY -- Procedure to copy the fit from one surface into another.

procedure dgscopy (sf1, sf2)

pointer	sf1		# pointer to original surface
pointer	sf2		# pointer to the new surface

begin
	if (sf1 == NULL) {
	    sf2 = NULL
	    return
	}

	# allocate space for new surface descriptor
	call calloc (sf2, LEN_GSSTRUCT, TY_STRUCT)

	# copy surface independent parameters 
	GS_TYPE(sf2) = GS_TYPE(sf1)

	switch (GS_TYPE(sf1)) {
	case GS_LEGENDRE, GS_CHEBYSHEV, GS_POLYNOMIAL:
	    GS_NXCOEFF(sf2) = GS_NXCOEFF(sf1)
	    GS_XORDER(sf2) = GS_XORDER(sf1)
	    GS_XMIN(sf2) = GS_XMIN(sf1)
	    GS_XMAX(sf2) = GS_XMAX(sf1)
	    GS_XRANGE(sf2) = GS_XRANGE(sf1)
	    GS_XMAXMIN(sf2) = GS_XMAXMIN(sf1)
	    GS_NYCOEFF(sf2) = GS_NYCOEFF(sf1)
	    GS_YORDER(sf2) = GS_YORDER(sf1)
	    GS_YMIN(sf2) = GS_YMIN(sf1)
	    GS_YMAX(sf2) = GS_YMAX(sf1)
	    GS_YRANGE(sf2) = GS_YRANGE(sf1)
	    GS_YMAXMIN(sf2) = GS_YMAXMIN(sf1) 
	    GS_XTERMS(sf2) = GS_XTERMS(sf1)
	    GS_NCOEFF(sf2) = GS_NCOEFF(sf1)
	default:
	    call error (0, "GSCOPY: Unknown surface type.")
	}

	# set space pointers to NULL
	GS_XBASIS(sf2) = NULL
	GS_YBASIS(sf2) = NULL
	GS_MATRIX(sf2) = NULL
	GS_CHOFAC(sf2) = NULL
	GS_VECTOR(sf2) = NULL
	GS_COEFF(sf2) = NULL
	GS_WZ(sf2) = NULL

	# restore coefficient array
	call calloc (GS_COEFF(sf2), GS_NCOEFF(sf2), TY_DOUBLE)
	call amovd (COEFF(GS_COEFF(sf1)), COEFF(GS_COEFF(sf2)), GS_NCOEFF(sf2))
end
