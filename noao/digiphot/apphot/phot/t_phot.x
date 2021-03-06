include <fset.h>
include <gset.h>
include <lexnum.h>
include <imhdr.h>
include "../lib/apphot.h"
include "../lib/fitsky.h"

# T_PHOT -- Procedure to measure magnitudes inside a set of apertures for a list
# of stars in a list of images.

procedure t_phot ()

pointer	image			# pointer name of the image
pointer	output			# pointer output file name
pointer	coords			# pointer to name of coords file
pointer	skyfile			# pointer to name of file with sky values
pointer	plotfile		# file of plot metacode
pointer	graphics		# graphics display device
pointer	display			# display device
int	interactive		# mode of use
int	cache			# cache the input image pixels in memory
int	verify			# verify critical parameters in batch mode
int	update			# update the critical parameters
int	verbose			# type messages on the terminal

pointer	sp, cname, outfname, str, ap, im, gd, mgd, id
int	limlist, lclist, lolist, lslist, sid, lid, sd, out, cl, root, stat, pfd
int	imlist, clist, olist, slist, memstat, old_size, wcs, req_size
int	buf_size

pointer	immap(), gopen()
int	imtlen(), imtgetim(), clplen(), clgfil(), btoi(), apstati(), strncmp()
int	fnldir(), strlen(), apphot(), imtopenp(), clpopnu(), open(), clgwrd()
int	ap_memstat(), sizeof()
bool	clgetb(), streq()
errchk	gopen

begin
	# Allocate temporary space.
	call smark (sp)
	call salloc (image, SZ_FNAME, TY_CHAR)
	call salloc (output, SZ_FNAME, TY_CHAR)
	call salloc (coords, SZ_FNAME, TY_CHAR)
	call salloc (skyfile, SZ_FNAME, TY_CHAR)
	call salloc (plotfile, SZ_FNAME, TY_CHAR)
	call salloc (graphics, SZ_FNAME, TY_CHAR)
	call salloc (display, SZ_FNAME, TY_CHAR)
	call salloc (outfname, SZ_FNAME, TY_CHAR)
	call salloc (cname, SZ_FNAME, TY_CHAR)
	call salloc (str, SZ_LINE, TY_CHAR)

	# Set the standard output to flush on newline.
	call fseti (STDOUT, F_FLUSHNL, YES)

	# Get the task parameters.
	imlist = imtopenp ("image")
	limlist = imtlen (imlist)
	clist = clpopnu ("coords")
	lclist = clplen (clist)
	olist = clpopnu ("output")
	lolist = clplen (olist)

	# Check that image and coordinate list lengths match.
	if (limlist < 1 || (lclist > 1 && lclist != limlist)) {
	    call imtclose (imlist)
	    call clpcls (clist)
	    call clpcls (olist)
	    call error (0, "Imcompatible image and coordinate list lengths")
	}

	# Check that image and output list lengths match.
	if (lolist > 1 && lolist != limlist) {
	    call imtclose (imlist)
	    call clpcls (clist)
	    call clpcls (olist)
	    call error (0, "Imcompatible image and output list lengths")
	}

	call clgstr ("icommands.p_filename", Memc[cname], SZ_FNAME)
	if (Memc[cname] != EOS)
	    interactive = NO
	#else if (lclist == 0)
	    #interactive = YES
	else
	    interactive = btoi (clgetb ("interactive"))
	cache = btoi (clgetb ("cache"))
	verbose = btoi (clgetb ("verbose"))
	verify = btoi (clgetb ("verify"))
	update = btoi (clgetb ("update"))

	# Get the graphics and display devices.
	call clgstr ("graphics", Memc[graphics], SZ_FNAME)
	call clgstr ("display", Memc[display], SZ_FNAME)

	# Open the graphics and display devices.
	if (interactive == YES) {
	    if (Memc[graphics] == EOS)
		gd = NULL
	    else {
		iferr {
		    gd = gopen (Memc[graphics], APPEND+AW_DEFER, STDGRAPH)
		} then {
		    call eprintf (
		        "Warning: Error opening graphics device.\n")
		    gd = NULL
		}
	    }
	    if (Memc[display] == EOS)
		id = NULL
	    else if (streq (Memc[graphics], Memc[display]))
		id = gd
	    else {
		iferr {
		    id = gopen (Memc[display], APPEND, STDIMAGE)
		} then {
		    call eprintf (
		"Warning: Graphics overlay not available for display device.\n")
		    id = NULL
		}
	    }
	} else {
	    gd = NULL
	    id = NULL
	}

	# Open the plot metacode file.
	call clgstr ("plotfile", Memc[plotfile], SZ_FNAME)
	if (Memc[plotfile] == EOS)
	    pfd = NULL
	else
	    pfd = open (Memc[plotfile], APPEND, BINARY_FILE)
	if (pfd != NULL)
	    mgd = gopen (Memc[graphics], NEW_FILE, pfd)
	else
	    mgd = NULL

	# Intialize the phot structure.
	call ap_gppars (ap)

	# Confirm the algorithm parameters.
	if (verify == YES && interactive == NO) {
	    call ap_pconfirm (ap, NULL, 1)
	    if (update == YES)
		call ap_ppars (ap)
	}

        # Get the wcs information.
        wcs = clgwrd ("wcsin", Memc[str], SZ_LINE, WCSINSTR)
        if (wcs <= 0) {
            call eprintf (
                "Warning: Setting the input coordinate system to logical\n")
            wcs = WCS_LOGICAL
        }
        call apseti (ap, WCSIN, wcs)
        wcs = clgwrd ("wcsout", Memc[str], SZ_LINE, WCSOUTSTR)
        if (wcs <= 0) {
            call eprintf (
                "Warning: Setting the output coordinate system to logical\n")
            wcs = WCS_LOGICAL
        }
        call apseti (ap, WCSOUT, wcs)

	# Get the file name for the sky values.
	if (apstati (ap, SKYFUNCTION) == AP_SKYFILE) {
	    slist = clpopnu ("skyfile")
	    lslist = clplen (slist)
	    if (limlist < 1 || (lslist > 1 && lslist != limlist)) {
	        call imtclose (imlist)
	        call clpcls (clist)
	        call clpcls (olist)
		call clpcls (slist)
	        call error (0, "Imcompatible image and sky file list lengths")
	    }
	} else
	    sd = NULL

	# Begin looping over the image list.
	sid = 1
	while (imtgetim (imlist, Memc[image], SZ_FNAME) != EOF) {

	    # Open the image and store image parameters.
	    im = immap (Memc[image], READ_ONLY, 0)
	    call apimkeys (ap, im, Memc[image])

	    # Set the image display viewport.
	    if ((id != NULL) && (id != gd))
		call ap_gswv (id, Memc[image], im, 4)

	    # Cache the input image pixels.
            req_size = MEMFUDGE * IM_LEN(im,1) * IM_LEN(im,2) *
                sizeof (IM_PIXTYPE(im))
            memstat = ap_memstat (cache, req_size, old_size)
            if (memstat == YES)
                call ap_pcache (im, INDEFI, buf_size)

	    # Open the coordinate file, where coords is assumed to be a simple
	    # text file in which the x and y positions are in columns 1 and 2
	    # respectively and all remaining fields are ignored.

	    if (lclist <= 0) {
		cl = NULL
		call strcpy ("", Memc[outfname], SZ_FNAME)
	    } else {
		stat = clgfil (clist, Memc[coords], SZ_FNAME)
		root = fnldir (Memc[coords], Memc[outfname], SZ_FNAME)
		if (strncmp ("default", Memc[coords+root], 7) == 0 || root ==
		    strlen (Memc[coords])) {
		    call ap_inname (Memc[image], Memc[outfname], "coo",
		        Memc[outfname], SZ_FNAME)
		    lclist = limlist
	            cl = open (Memc[outfname], READ_ONLY, TEXT_FILE)
		} else if (stat != EOF) {
		    call strcpy (Memc[coords], Memc[outfname], SZ_FNAME)
	            cl = open (Memc[outfname], READ_ONLY, TEXT_FILE)
		} else {
		    call apstats (ap, CLNAME, Memc[outfname], SZ_FNAME)
		    call seek (cl, BOF)
		}
	    }
	    call apsets (ap, CLNAME, Memc[outfname])
	    call apfroot (Memc[outfname], Memc[str], SZ_LINE)
	    call apsets (ap, CLROOT, Memc[str])

	    # Open the skys file.
	    if (lslist <= 0) {
		sd = NULL
		call strcpy ("", Memc[skyfile], SZ_FNAME)
	    } else if (clgfil (slist, Memc[skyfile], SZ_FNAME) != EOF)
		sd = open (Memc[skyfile], READ_ONLY, TEXT_FILE)
	    else
		call seek (sd, BOF)
	    #call apsets (ap, SKYNAME, Memc[skyfile])

	    # Open the output text file, if output is "default", dir$default or
	    # a directory specification then the extension "mag" is added to the
	    # image name and a suitable version number is appended to the output
	    # name. If output is the null string then no output file is created.

	    if (lolist == 0) {
		out = NULL
		call strcpy ("", Memc[outfname], SZ_FNAME)
	    } else {
	        stat = clgfil (olist, Memc[output], SZ_FNAME)
		root = fnldir (Memc[output], Memc[outfname], SZ_FNAME)
		if (strncmp ("default", Memc[output+root], 7) == 0 || root ==
		    strlen (Memc[output])) {
		    call apoutname (Memc[image], Memc[outfname], "mag",
		        Memc[outfname], SZ_FNAME)
		    out = open (Memc[outfname], NEW_FILE, TEXT_FILE)
		    lolist = limlist
		} else if (stat != EOF) {
		    call strcpy (Memc[output], Memc[outfname], SZ_FNAME)
		    out = open (Memc[outfname], NEW_FILE, TEXT_FILE)
		} else
		    call apstats (ap, OUTNAME, Memc[outfname], SZ_FNAME)
	    }
	    call apsets (ap, OUTNAME, Memc[outfname])

	    # Do aperture photometry.
	    if (interactive == NO) {
	        if (Memc[cname] != EOS)
		    stat = apphot (ap, im, cl, sd, NULL, mgd, NULL, out, sid,
		        NO, cache)
	        else if (cl != NULL) {
		    lid = 1
	            call apbphot (ap, im, cl, sd, out, sid, lid, gd, mgd, id,
		        verbose)
		    stat = NO
		} else
		    stat = NO
	    } else
		stat = apphot (ap, im, cl, sd, gd, mgd, id, out, sid, YES,
		    cache)

	    # Cleanup.
	    call imunmap (im)
	    if (cl != NULL) {
		if (clplen(clist) > 1)
		    call close (cl)
	    }
	    if (sd != NULL) {
		if (lslist > 1)
		    call close (sd)
	    }
	    if (out != NULL && lolist != 1) {
		call close (out)
		if (sid <= 1) {
		    call apstats (ap, OUTNAME, Memc[outfname], SZ_FNAME)
		    call delete (Memc[outfname])
		}
		sid = 1
	    }

	    # Uncache memory.
	    call fixmem (old_size)

	    if (stat == YES)
		break
	}


	# Close the coordinate, sky and output files.
	if (cl != NULL && lclist == 1)
	    call close (cl)
	if (sd != NULL && lslist == 1)
	    call close (sd)
	if (out != NULL && lolist == 1) {
	    call close (out)
	    if (sid <= 1) {
		call apstats (ap, OUTNAME, Memc[outfname], SZ_FNAME)
		call delete (Memc[outfname])
	    }
	}

	# Close up the plot files.
	if (id == gd && id != NULL)
	    call gclose (id)
	else {
	    if (gd != NULL)
	        call gclose (gd)
	    if (id != NULL)
	        call gclose (id)
	}
	if (mgd != NULL)
	    call gclose (mgd)
	if (pfd != NULL)
	    call close (pfd)

	# Free the apphot data structures.
	call appfree (ap)

	# Close the coord, sky and image lists.
	call imtclose (imlist)
	call clpcls (clist)
	if (sd != NULL)
	    call clpcls (slist)
	call clpcls (olist)

	# Free working space.
	call sfree (sp)
end
