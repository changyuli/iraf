# Copyright(c) 1986 Association of Universities for Research in Astronomy Inc.

include	<pkg/rg.h>

# RG_UNPACK -- Unpack a packed array.
#
# There is no checking on the size of the arrays.  The points in the
# unpacked array which are not covered by the packed array are left unchanged.
# The packed and unpacked arrays should not be the same.

procedure rg_unpackr (rg, packed, unpacked)

pointer	rg					# Ranges
real	packed[ARB]				# Packed array
real	unpacked[ARB]				# Unpacked array

int	i, j, x1, x2, nx

begin
	if (rg == NULL)
	    call error (0, "Range descriptor undefined")

	j = 1
	do i = 1, RG_NRGS(rg) {
	    if (RG_X1(rg, i) < RG_X2(rg, i)) {
		x1 = RG_X1(rg, i)
		x2 = RG_X2(rg, i)
	    } else {
		x1 = RG_X2(rg, i)
		x2 = RG_X1(rg, i)
	    }

	    nx = x2 - x1 + 1
	    call amovr (packed[j], unpacked[x1], nx)
	    j = j + nx
	}
end
