# Copyright(c) 1986 Association of Universities for Research in Astronomy Inc.

include	<mach.h>

# ALUI -- Vector lookup and interpolate (linear).  B[i] = A(X[i]).
# No bounds checking is performed, but the case A(X[i])=NPIX (no fractional
# part) is recognized and will not cause a reference off the right end of the
# array.  This is done in a way which will also cause execution to be faster
# when the sample points are integral, i.e., fall exactly on data points in
# the input array.

procedure aluii (a, b, x, npix)

int	a[ARB], b[ARB]
real	x[ARB], fraction, tol
int	npix, i, left_pixel

begin
	tol = EPSILONR * 5.0

	do i = 1, npix {
	    left_pixel = int (x[i])
	    fraction = x[i] - real(left_pixel)
	    if (fraction < tol)
		b[i] = a[left_pixel]
	    else
		b[i] = a[left_pixel] * (1.0 - fraction) +
		       a[left_pixel+1] * fraction
	}
end
