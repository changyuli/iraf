# Copyright(c) 1986 Association of Universities for Research in Astronomy Inc.

# ALLN -- Compute the natural logarithm of a vector (generic).  If the natural
# logarithm is undefined (x <= 0) a user supplied function is called to get
# the pixel value to be returned.

procedure allni (a, b, npix, errfcn)

int	a[ARB], b[ARB]
int	npix, i
extern	errfcn()
int	errfcn()
errchk	errfcn

begin
	do i = 1, npix {
		if (a[i] <= 0)
		    b[i] = errfcn (a[i])
		else {
			b[i] = log (real (a[i]))
		}
	}
end
