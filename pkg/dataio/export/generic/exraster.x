include <imhdr.h>
include <mach.h>
include <evvexpr.h>
include "../export.h"

define	DEBUG	false


# EX_NO_INTERLEAVE - Write out the image with no interleaving.

procedure ex_no_interleave (ex)

pointer	ex				#i task struct pointer

pointer	op, out
int	i, j, k, line, percent, orow
int	fd, outtype

pointer	ex_evaluate(), ex_chtype()

begin
	if (DEBUG) { call eprintf ("ex_no_interleave:\n") 
	    call eprintf ("NEXPR = %d  OCOLS = %d OROWS = %d\n")
		call pargi(EX_NEXPR(ex));call pargi(EX_OCOLS(ex))
		call pargi(EX_OROWS(ex))
	}

	# Loop over the number of image expressions.
	fd = EX_FD(ex)
	outtype = EX_OUTTYPE(ex)
	percent = 0
	orow = 0
	do i = 1, EX_NEXPR(ex) {

	    # Process each line in the image.
	    do j = 1, O_HEIGHT(ex,i) {

		# See if we're flipping the image.
		if (bitset (EX_OUTFLAGS(ex), OF_FLIPY))
		    #line = EX_NLINES(ex) - j + 1
		    line = O_HEIGHT(ex,i) - j + 1
		else
		    line = j

		# Get pixels from image(s).
		call ex_getpix (ex, line)

		# Evaluate expression.
		op = ex_evaluate (ex, O_EXPR(ex,i))

		# Convert to the output pixel type.
		out = ex_chtype (ex, op, outtype)

		# Write evaluated pixels.
		if (EX_FORMAT(ex) != FMT_LIST)
		    call ex_wpixels (fd, outtype, out, O_LEN(op))
		else {
		    call ex_listpix (fd, outtype, out, O_LEN(op), j, i, 
			EX_NEXPR(ex), NO)
		}

		# Clean up the pointers.
		if (outtype == TY_UBYTE || outtype == TY_CHAR)
		    call mfree (out, TY_CHAR)
		else
		    call mfree (out, outtype)
	 	call evvfree (op)
		do k = 1, EX_NIMOPS(ex) {
		    op = IMOP(ex,k)
#		    if (IO_ISIM(op) == NO)
			call mfree (IO_DATA(op), IM_PIXTYPE(IO_IMPTR(op)))
		}

                # Print percent done if being verbose
	 	orow = orow + 1
                #if (EX_VERBOSE(ex) == YES)
		    call ex_pstat (ex, orow, percent)
	    }
	}

	if (DEBUG) { call zze_prstruct ("Finished processing", ex) }
end


# EX_LN_INTERLEAVE - Write out the image with line interleaving.

procedure ex_ln_interleave (ex)

pointer	ex				#i task struct pointer

pointer	op, out
int	i, j, line, percent, orow
int	fd, outtype

pointer	ex_evaluate(), ex_chtype()

begin
	if (DEBUG) { call eprintf ("ex_ln_interleave:\n")
	    call eprintf ("NEXPR = %d  OCOLS = %d OROWS = %d\n")
		call pargi(EX_NEXPR(ex));call pargi(EX_OCOLS(ex))
		call pargi(EX_OROWS(ex))
	}

	# Process each line in the image.
	fd = EX_FD(ex)
	outtype = EX_OUTTYPE(ex)
	percent = 0
	orow = 0
	do i = 1, EX_NLINES(ex) {

	    # See if we're flipping the image.
	    if (bitset (EX_OUTFLAGS(ex), OF_FLIPY))
		line = EX_NLINES(ex) - i + 1
	    else
		line = i

	    # Get pixels from image(s).
	    call ex_getpix (ex, line)

	    # Loop over the number of image expressions.
	    do j = 1, EX_NEXPR(ex) {

		# Evaluate expression.
		op = ex_evaluate (ex, O_EXPR(ex,j))

		# Convert to the output pixel type.
		out = ex_chtype (ex, op, outtype)

                # Write evaluated pixels.
		if (EX_FORMAT(ex) != FMT_LIST)
		    call ex_wpixels (fd, outtype, out, O_LEN(op))
		else {
		    call ex_listpix (fd, outtype, out, O_LEN(op), i, j,
			EX_NEXPR(ex), NO)
		}

		# Clean up the pointers.
		if (outtype == TY_UBYTE || outtype == TY_CHAR)
		    call mfree (out, TY_CHAR)
		else
		    call mfree (out, outtype)
                call evvfree (op)

                # Print percent done if being verbose
	        orow = orow + 1
                #if (EX_VERBOSE(ex) == YES)
		    call ex_pstat (ex, orow, percent)
	    }

	    do j = 1, EX_NIMOPS(ex) {
		op = IMOP(ex,j)
#		if (IO_ISIM(op) == NO)
		    call mfree (IO_DATA(op), IM_PIXTYPE(IO_IMPTR(op)))
	    }
	}

	if (DEBUG) { call zze_prstruct ("Finished processing", ex) }
end


# EX_PX_INTERLEAVE - Write out the image with pixel interleaving.

procedure ex_px_interleave (ex)

pointer	ex				#i task struct pointer

pointer	sp, pp, op
pointer	o, outptr
int	i, j, line, npix, outtype
long	totpix
int	fd, percent, orow

pointer	ex_evaluate(), ex_chtype()

begin
	if (DEBUG) { call eprintf ("ex_px_interleave:\n")
	    call eprintf ("NEXPR = %d  OCOLS = %d OROWS = %d\n")
		call pargi(EX_NEXPR(ex));call pargi(EX_OCOLS(ex))
		call pargi(EX_OROWS(ex))
	}

	call smark (sp)
	call salloc (pp, EX_NEXPR(ex), TY_POINTER)

	# Process each line in the image.
	fd = EX_FD(ex)
	outptr = NULL
	outtype = EX_OUTTYPE(ex)
	percent = 0
	orow = 0
	do i = 1, EX_NLINES(ex) {

	    # See if we're flipping the image.
	    if (bitset (EX_OUTFLAGS(ex), OF_FLIPY))
	        line = EX_NLINES(ex) - i + 1
	    else
	        line = i

	    # Get pixels from image(s).
	    call ex_getpix (ex, line)

	    # Loop over the number of image expressions.
	    totpix = 0
	    do j = 1, EX_NEXPR(ex) {

		# Evaluate expression.
		op = ex_evaluate (ex, O_EXPR(ex,j))

		# Convert to the output pixel type.
		o = ex_chtype (ex, op, outtype)
		Memi[pp+j-1] = o

		npix = O_LEN(op)
		#npix = EX_OCOLS(op)
	 	call evvfree (op)
	    }

	    # Merge pixels into a single vector.
	    call ex_merge_pixels (Memi[pp], EX_NEXPR(ex), npix, outtype, 
		outptr, totpix)
		
	    # Write vector of merged pixels.
	    if (outtype == TY_UBYTE)
		call achtsb (Memc[outptr], Memc[outptr], totpix)
	    if (EX_FORMAT(ex) != FMT_LIST)
		call ex_wpixels (fd, outtype, outptr, totpix)
	    else {
		call ex_listpix (fd, outtype, outptr, totpix, 
		    i, EX_NEXPR(ex), EX_NEXPR(ex), YES)
	    }

	    if (outtype != TY_CHAR && outtype != TY_UBYTE)
	        call mfree (outptr, outtype)
	    else
	        call mfree (outptr, TY_CHAR)
	    do j = 1, EX_NIMOPS(ex) {
		op = IMOP(ex,j)
#		if (IO_ISIM(op) == NO)
		    call mfree (IO_DATA(op), IM_PIXTYPE(IO_IMPTR(op)))
	    }
	    do j = 1, EX_NEXPR(ex) {
	        if (outtype != TY_CHAR && outtype != TY_UBYTE)
		    call mfree (Memi[pp+j-1], outtype)
		else
		    call mfree (Memi[pp+j-1], TY_CHAR)
	    }

            # Print percent done if being verbose
	    orow = orow + 1
            #if (EX_VERBOSE(ex) == YES)
		call ex_pstat (ex, orow, percent)
	}

	call sfree (sp)

	if (DEBUG) { call zze_prstruct ("Finished processing", ex) }
end


# EX_GETPIX - Get the pixels from the image and load each operand.

procedure ex_getpix (ex, line)

pointer	ex				#i task struct pointer
int	line				#i current line number

pointer	im, op, data
int	nptrs, i, band

pointer	imgl3s(), imgl3i(), imgl3l()
pointer	imgl3r(), imgl3d()

begin
	# Loop over each of the image operands.
	nptrs = EX_NIMOPS(ex)
	do i = 1, nptrs {
	    op = IMOP(ex,i)
	    im = IO_IMPTR(op)
	    band = max (1, IO_BAND(op))

	    if (line > IM_LEN(im,2)) {
	        call calloc (IO_DATA(op), IM_LEN(im,1), IM_PIXTYPE(im))
	        IO_ISIM(op) = NO
	        IO_NPIX(op) = IM_LEN(im,1)
		next
	    } else if (IO_DATA(op) == NULL)
	        call malloc (IO_DATA(op), IM_LEN(im,1), IM_PIXTYPE(im))

	    switch (IM_PIXTYPE(im)) {
            case TY_USHORT:
		data = imgl3s (im, line, band)
		call amovs (Mems[data], Mems[IO_DATA(op)], IM_LEN(im,1))
	        IO_TYPE(op) = TY_SHORT
		IO_NBYTES(op) = SZ_SHORT * SZB_CHAR
	        IO_ISIM(op) = YES

            case TY_SHORT:
		data = imgl3s (im, line, band)
		call amovs (Mems[data], Mems[IO_DATA(op)], IM_LEN(im,1))
	        IO_TYPE(op) = TY_SHORT
		    IO_NBYTES(op) = SZ_SHORT * SZB_CHAR
	        IO_ISIM(op) = YES

            case TY_INT:
		data = imgl3i (im, line, band)
		call amovi (Memi[data], Memi[IO_DATA(op)], IM_LEN(im,1))
	        IO_TYPE(op) = TY_INT
		    IO_NBYTES(op) = SZ_INT32 * SZB_CHAR
	        IO_ISIM(op) = YES

            case TY_LONG:
		data = imgl3l (im, line, band)
		call amovl (Meml[data], Meml[IO_DATA(op)], IM_LEN(im,1))
	        IO_TYPE(op) = TY_LONG
		    IO_NBYTES(op) = SZ_LONG * SZB_CHAR
	        IO_ISIM(op) = YES

            case TY_REAL:
		data = imgl3r (im, line, band)
		call amovr (Memr[data], Memr[IO_DATA(op)], IM_LEN(im,1))
	        IO_TYPE(op) = TY_REAL
		    IO_NBYTES(op) = SZ_REAL * SZB_CHAR
	        IO_ISIM(op) = YES

            case TY_DOUBLE:
		data = imgl3d (im, line, band)
		call amovd (Memd[data], Memd[IO_DATA(op)], IM_LEN(im,1))
	        IO_TYPE(op) = TY_DOUBLE
		    IO_NBYTES(op) = SZ_DOUBLE * SZB_CHAR
	        IO_ISIM(op) = YES

	    }
	    IO_NPIX(op) = IM_LEN(im,1)
	}
end


# EX_WPIXELS - Write the pixels to the current file.

procedure ex_wpixels (fd, otype, pix, npix)

int	fd				#i output file descriptor
int	otype				#i output data type
pointer	pix				#i pointer to pixel data
int	npix				#i number of pixels to write

begin
	# Write binary output.
        switch (otype) {
        case TY_UBYTE:
            call write (fd, Mems[pix], npix / SZB_CHAR)
        case TY_USHORT:
            call write (fd, Mems[pix], npix * SZ_SHORT/SZ_CHAR)

        case TY_SHORT:
            call write (fd, Mems[pix], npix * SZ_SHORT/SZ_CHAR)

        case TY_INT:
	    if (SZ_INT != SZ_INT32)
		call ipak32 (Memi[pix], Memi[pix], npix)
            call write (fd, Memi[pix], npix * SZ_INT32/SZ_CHAR)

        case TY_LONG:
            call write (fd, Meml[pix], npix * SZ_LONG/SZ_CHAR)

        case TY_REAL:
            call write (fd, Memr[pix], npix * SZ_REAL/SZ_CHAR)

        case TY_DOUBLE:
            call write (fd, Memd[pix], npix * SZ_DOUBLE/SZ_CHAR)

	}
end


# EX_LISTPIX - Write the pixels to the current file as ASCII text.

procedure ex_listpix (fd, type, data, npix, line, band, nbands, merged)

int	fd				#i output file descriptor
int	type				#i output data type
pointer	data				#i pointer to pixel data
int	npix				#i number of pixels to write
int	line				#i current output line number
int	band				#i current output band number
int	nbands				#i no. of output bands
int	merged				#i are pixels interleaved?

int	i, j, k
int	val, pix, shifti(), andi()

begin
	if (merged == YES && nbands > 1) {
	    do i = 1, npix {
		k = 0
	        do j = 1, nbands {
		    call fprintf (fd, "%4d %4d %4d  ")
		        call pargi (i)
		        call pargi (line)
		        call pargi (j)

		    switch (type) {
                    case TY_UBYTE:
                        val = Memc[data+k]
                        if (mod(i,2) == 1) {
                            pix = shifti (val, -8)
                        } else {
                            pix = andi (val, 000FFX)
                            k = k + 1
                        }
                        if (pix < 0)  pix = pix + 256
                        call fprintf (fd, "%d\n")
                            call pargi (pix)
		    case TY_CHAR, TY_SHORT, TY_USHORT:
		        call fprintf (fd, "%d\n")
		            call pargs (Mems[data+((j-1)*npix+i)-1])
        	    case TY_INT:
		        call fprintf (fd, "%d\n")
		            call pargi (Memi[data+((j-1)*npix+i)-1])
        	    case TY_LONG:
		        call fprintf (fd, "%d\n")
		            call pargl (Meml[data+((j-1)*npix+i)-1])
        	    case TY_REAL:
		        call fprintf (fd, "%g\n")
		            call pargr (Memr[data+((j-1)*npix+i)-1])
        	    case TY_DOUBLE:
		        call fprintf (fd, "%g\n")
		            call pargd (Memd[data+((j-1)*npix+i)-1])
	            }
		}
	    }
	} else {
	    j = 0
	    do i = 1, npix {
		if (nbands > 1) {
		    call fprintf (fd, "%4d %4d %4d  ")
		        call pargi (i)
		        call pargi (line)
		        call pargi (band)
		} else {
		    call fprintf (fd, "%4d %4d  ")
		        call pargi (i)
		        call pargi (line)
		}

		switch (type) {
		case TY_UBYTE:
		    val = Memc[data+j]
		    if (mod(i,2) == 1) {
			pix = shifti (val, -8)
		    } else {
			pix = andi (val, 000FFX)
			j = j + 1
		    }
		    if (pix < 0)  pix = pix + 256
		    call fprintf (fd, "%d\n")
		        call pargi (pix)
		case TY_CHAR, TY_SHORT, TY_USHORT:
		    call fprintf (fd, "%d\n")
		        call pargs (Mems[data+i-1])
        	case TY_INT:
		    call fprintf (fd, "%d\n")
		        call pargi (Memi[data+i-1])
        	case TY_LONG:
		    call fprintf (fd, "%d\n")
		        call pargl (Meml[data+i-1])
        	case TY_REAL:
		    call fprintf (fd, "%g\n")
		        call pargr (Memr[data+i-1])
        	case TY_DOUBLE:
		    call fprintf (fd, "%g\n")
		        call pargd (Memd[data+i-1])
		}
	    }
	}
end


# EX_MERGE_PIXELS - Merge a group of pixels arrays into one array by combining
# the elements.  Returns an allocated pointer which must be later freed and 
# the total number of pixels.

procedure ex_merge_pixels (ptrs, nptrs, npix, dtype, pix, totpix)

pointer ptrs[ARB]                       #i array of pixel ptrs
int     nptrs                           #i number of ptrs
int     npix                            #i no. of pixels in each array
int     dtype                           #i type of pointer to alloc
pointer pix                             #o output pixel array ptr
int     totpix                          #o total no. of output pixels

int     i, j, ip

begin
        # Calculate the number of output pixels and allocate the pointer.
        totpix = nptrs * npix
	if (dtype != TY_CHAR && dtype != TY_UBYTE)
            call realloc (pix, totpix, dtype)
	else {
            call realloc (pix, totpix, TY_CHAR)
	    do i = 1, nptrs
		call achtbs (Mems[ptrs[i]], Mems[ptrs[i]], npix)
	}

        # Fill the output array
        ip = 0
        for (i = 1; i<=npix; i=i+1) {
            do j = 1, nptrs {
                switch (dtype) {
                case TY_UBYTE:
                    Mems[pix+ip] = Mems[ptrs[j]+i-1]
                case TY_USHORT:
                    Mems[pix+ip] = Mems[ptrs[j]+i-1]

                case TY_SHORT:
                    Mems[pix+ip] = Mems[ptrs[j]+i-1]

                case TY_INT:
                    Memi[pix+ip] = Memi[ptrs[j]+i-1]

                case TY_LONG:
                    Meml[pix+ip] = Meml[ptrs[j]+i-1]

                case TY_REAL:
                    Memr[pix+ip] = Memr[ptrs[j]+i-1]

                case TY_DOUBLE:
                    Memd[pix+ip] = Memd[ptrs[j]+i-1]

                }
        
                ip = ip + 1
            }
        }
end


# EX_CHTYPE - Change the expression operand vector to the output datatype.
# We allocate and return a pointer to the correct type to the converted
# pixels, this pointer must be freed later on.  Any IEEE or byte-swapping
# requests are also handled here.

pointer procedure ex_chtype (ex, op, type)

pointer	ex				#i task struct pointer
pointer	op				#i evvexpr operand pointer
int	type				#i new type of pointer

pointer	out, coerce()
int	swap, flags

begin
	# Allocate the pointer and coerce it so the routine works.
	if (type == TY_UBYTE || type == TY_CHAR)
            call calloc (out, O_LEN(op), TY_CHAR)
	else {
            call calloc (out, O_LEN(op), type)
            out = coerce (out, type, TY_CHAR)
	}

 	# If this is a color index image subtract one from the pixel value
 	# to get the index.
 	if (bitset (flags, OF_CMAP))
	    call ex_pix_to_index (O_VALP(op), O_TYPE(op), O_LEN(op))

	# Change the pixel type.
	flags = EX_OUTFLAGS(ex)
	swap = EX_BSWAP(ex)
        switch (O_TYPE(op)) {
        case TY_CHAR:
            call achtc (Memc[O_VALP(op)], Memc[out], O_LEN(op), type)

        case TY_SHORT:
            call achts (Mems[O_VALP(op)], Memc[out], O_LEN(op), type)

	    # Do any requested byte swapping.
	    if (bitset (swap, S_I2) || bitset (swap, S_ALL))
		call bswap4 (Mems[out], 1, Mems[out], 1, O_LEN(op))

        case TY_INT:
            call achti (Memi[O_VALP(op)], Memc[out], O_LEN(op), type)

	    # Do any requested byte swapping.
	    if (bitset (swap, S_I4) || bitset (swap, S_ALL))
		call bswap4 (Memi[out], 1, Memi[out], 1, O_LEN(op))

        case TY_LONG:
            call achtl (Meml[O_VALP(op)], Memc[out], O_LEN(op), type)

	    # Do any requested byte swapping.
	    if (bitset (swap, S_I4) || bitset (swap, S_ALL))
		call bswap4 (Meml[out], 1, Meml[out], 1, O_LEN(op))

        case TY_REAL:
            call achtr (Memr[O_VALP(op)], Memc[out], O_LEN(op), type)

	    # See if we need to convert to IEEE
	    if (bitset (flags, OF_IEEE) && IEEE_USED == NO)
		call ieevpakr (Memr[out], Memr[out], O_LEN(op))

        case TY_DOUBLE:
            call achtd (Memd[O_VALP(op)], Memc[out], O_LEN(op), type)

	    # See if we need to convert to IEEE
	    if (bitset (flags, OF_IEEE) && IEEE_USED == NO)
		call ieevpakd (Memd[P2D(out)], Memd[P2D(out)], O_LEN(op))

	default:
	    call error (0, "Invalid output type requested.")
        }

	if (type != TY_UBYTE && type != TY_CHAR)
            out = coerce (out, TY_CHAR, type)
	return (out)
end


# EX_PIX_TO_INDEX - Convert pixel values to color index values.  We assume
# the colormap has at most 256 entries.

procedure ex_pix_to_index (ptr, type, len)

pointer	ptr				#i data ptr
int	type				#i data type of array
int	len				#i length of array


short	sindx, smin, smax

int	iindx, imin, imax

long	lindx, lmin, lmax

real	rindx, rmin, rmax

double	dindx, dmin, dmax


begin

	sindx = short (1)
	smin = short (0)
	smax = short (255)

	iindx = int (1)
	imin = int (0)
	imax = int (255)

	lindx = long (1)
	lmin = long (0)
	lmax = long (255)

	rindx = real (1)
	rmin = real (0)
	rmax = real (255)

	dindx = double (1)
	dmin = double (0)
	dmax = double (255)


	switch (type) {

	case TY_SHORT:
            call asubks (Mems[ptr], sindx, Mems[ptr], len)
            call amaxks (Mems[ptr], smin, Mems[ptr], len)
            call aminks (Mems[ptr], smax, Mems[ptr], len)

	case TY_INT:
            call asubki (Memi[ptr], iindx, Memi[ptr], len)
            call amaxki (Memi[ptr], imin, Memi[ptr], len)
            call aminki (Memi[ptr], imax, Memi[ptr], len)

	case TY_LONG:
            call asubkl (Meml[ptr], lindx, Meml[ptr], len)
            call amaxkl (Meml[ptr], lmin, Meml[ptr], len)
            call aminkl (Meml[ptr], lmax, Meml[ptr], len)

	case TY_REAL:
            call asubkr (Memr[ptr], rindx, Memr[ptr], len)
            call amaxkr (Memr[ptr], rmin, Memr[ptr], len)
            call aminkr (Memr[ptr], rmax, Memr[ptr], len)

	case TY_DOUBLE:
            call asubkd (Memd[ptr], dindx, Memd[ptr], len)
            call amaxkd (Memd[ptr], dmin, Memd[ptr], len)
            call aminkd (Memd[ptr], dmax, Memd[ptr], len)

	}
end


# EX_PSTAT - Print information about the progress we're making.

procedure ex_pstat (ex, row, percent)

pointer	ex				#i task struct pointer
int	row				#u current row
int	percent				#u percent completed

begin
        # Print percent done if being verbose
        if (row * 100 / EX_OROWS(ex) >= percent + 10) {
            percent = percent + 10
            call eprintf ("    Status: %2d%% complete\r")
                call pargi (percent)
            call flush (STDERR)
        }
end
