
# DP_IIMNAME -- Procedure to construct an daophot input image name.
# If input is null or a directory a name is constructed from the root
# of the image name and the extension. The disk is searched to avoid
# name collisions.

procedure dp_iimname (image, input, ext, name, maxch)

char	image[ARB]		# image name
char	input[ARB]		# input directory or name
char	ext[ARB]		# extension
char	name[ARB]		# input name
int	maxch			# maximum size of name

int	ndir, nimdir, clindex, clsize
pointer	sp, root, str
int	fnldir(), strlen()

begin
	call smark (sp)
	call salloc (root, SZ_FNAME, TY_CHAR)
	call salloc (str, SZ_FNAME, TY_CHAR)

	ndir = fnldir (input, name, maxch)
	if (strlen (input) == ndir) {
            call imparse (image, Memc[root], SZ_FNAME, Memc[str], SZ_FNAME,
                Memc[str], SZ_FNAME, clindex, clsize)
            nimdir = fnldir (Memc[root], Memc[str], SZ_FNAME)
            if (clindex >= 0) {
                call sprintf (name[ndir+1], maxch, "%s%d.%s.*")
                    call pargstr (Memc[root+nimdir])
                    call pargi (clindex)
                    call pargstr (ext)
            } else {
                call sprintf (name[ndir+1], maxch, "%s.%s.*")
                    call pargstr (Memc[root+nimdir])
                    call pargstr (ext)
            }

	    call dp_iimversion (name, name, maxch)
	} else
	    call strcpy (input, name, maxch)

	call sfree (sp)
end


# DP_IMROOT -- Fetch the root image name minus the directory specification
# and the section notation.

procedure dp_imroot (image, root, maxch)

char    image[ARB]              # image specification
char    root[ARB]               # output root name
int     maxch                   # maximum number of characters

pointer sp, imroot, kernel, section, str
int     clindex, clsize, nchars
int     fnldir()

begin
        call smark (sp)
        call salloc (imroot, SZ_PATHNAME, TY_CHAR)
        call salloc (kernel, SZ_FNAME, TY_CHAR)
        call salloc (section, SZ_FNAME, TY_CHAR)
        call salloc (str, SZ_PATHNAME, TY_CHAR)

        call imparse (image, Memc[imroot], SZ_PATHNAME, Memc[kernel], SZ_FNAME,
            Memc[section], SZ_FNAME, clindex, clsize)
        nchars = fnldir (Memc[imroot], Memc[str], SZ_PATHNAME)
        if (clindex >= 0) {
            call sprintf (root, maxch, "%s[%d]%s%s")
                call pargstr (Memc[imroot+nchars])
                call pargi (clindex)
                call pargstr (Memc[kernel])
                call pargstr (Memc[section])
        } else {
            call sprintf (root, maxch, "%s%s%s")
                call pargstr (Memc[imroot+nchars])
                call pargstr (Memc[kernel])
                call pargstr (Memc[section])
        }

        call sfree (sp)
end


# DP_OIMVERSION -- Routine to compute the next available version number of
# a given file name template and output the new files name.

procedure dp_oimversion (template, filename, maxch)

char	template[ARB]			# name template
char	filename[ARB]			# output name
int	maxch				# maximum number of characters

char	period
int	newversion, version, len
pointer	sp, list, name
int	imtopen(), imtgetim(), strldx(), ctoi()

begin
	# Allocate temporary space
	call smark (sp)
	call salloc (name, maxch, TY_CHAR)
	period = '.'
	list = imtopen (template)

	# Loop over the names in the list searchng for the highest version.
	newversion = 0
	while (imtgetim (list, Memc[name], maxch) != EOF) {
	    len = strldx (period, Memc[name])
	    Memc[name+len-1] = EOS
	    len = strldx (period, Memc[name])
	    len = len + 1
	    if (ctoi (Memc[name], len, version) <= 0)
		next
	    newversion = max (newversion, version)
	}

	# Make new output file name.
	len = strldx (period, template)
	call strcpy (template, filename, len)
	call sprintf (filename[len+1], maxch, "%d")
	    call pargi (newversion + 1)

	call imtclose (list)
	call sfree (sp)
end


# DP_IIMVERSION -- Routine to compute the next available version number of
# a given file name template and output the new files name.

procedure dp_iimversion (template, filename, maxch)

char	template[ARB]			# name template
char	filename[ARB]			# output name
int	maxch				# maximum number of characters

char	period
int	newversion, version, len
pointer	sp, list, name
int	imtopen(), imtgetim() strldx(), ctoi()

begin
	# Allocate temporary space
	call smark (sp)
	call salloc (name, maxch, TY_CHAR)
	period = '.'
	list = imtopen (template)

	# Loop over the names in the list searchng for the highest version.
	newversion = 0
	while (imtgetim (list, Memc[name], maxch) != EOF) {
	    len = strldx (period, Memc[name])
	    Memc[name+len-1] = EOS
	    len = strldx (period, Memc[name])
	    len = len + 1
	    if (ctoi (Memc[name], len, version) <= 0)
		next
	    newversion = max (newversion, version)
	}

	# Make new output file name.
	len = strldx (period, template)
	call strcpy (template, filename, len)
	call sprintf (filename[len+1], maxch, "%d")
	    call pargi (newversion)

	call imtclose (list)
	call sfree (sp)
end


# DP_OIMNAME -- Procedure to construct an daophot output image name.
# If output is null or a directory a name is constructed from the root
# of the image name and the extension. The disk is searched to avoid
# name collisions.

procedure dp_oimname (image, output, ext, name, maxch)

char	image[ARB]		# image name
char	output[ARB]		# output directory or name
char	ext[ARB]		# extension
char	name[ARB]		# output name
int	maxch			# maximum size of name

int	ndir, nimdir, clindex, clsize
pointer	sp, root, str
int	fnldir(), strlen()

begin
	call smark (sp)
	call salloc (root, SZ_FNAME, TY_CHAR)
	call salloc (str, SZ_FNAME, TY_CHAR)

	ndir = fnldir (output, name, maxch)
	if (strlen (output) == ndir) {
            call imparse (image, Memc[root], SZ_FNAME, Memc[str], SZ_FNAME,
                Memc[str], SZ_FNAME, clindex, clsize)
            nimdir = fnldir (Memc[root], Memc[str], SZ_FNAME)
            if (clindex >= 0) {
                call sprintf (name[ndir+1], maxch, "%s%d.%s.*")
                    call pargstr (Memc[root+nimdir])
                    call pargi (clindex)
                    call pargstr (ext)
            } else {
                call sprintf (name[ndir+1], maxch, "%s.%s.*")
                    call pargstr (Memc[root+nimdir])
                    call pargstr (ext)
            }
	    call dp_oimversion (name, name, maxch)
	} else
	    call strcpy (output, name, maxch)

	call sfree (sp)
end


# DP_INNAME -- Procedure to construct an daophot input file name.
# If input is null or a directory a name is constructed from the root
# of the image name and the extension. The disk is searched to avoid
# name collisions.

procedure dp_inname (image, input, ext, name, maxch)

char	image[ARB]		# image name
char	input[ARB]		# input directory or name
char	ext[ARB]		# extension
char	name[ARB]		# input name
int	maxch			# maximum size of name

int	ndir, nimdir, clindex, clsize
pointer	sp, root, str
int	fnldir(), strlen()

begin
	call smark (sp)
	call salloc (root, SZ_FNAME, TY_CHAR)
	call salloc (str, SZ_FNAME, TY_CHAR)

	ndir = fnldir (input, name, maxch)
	if (strlen (input) == ndir) {
           call imparse (image, Memc[root], SZ_FNAME, Memc[str], SZ_FNAME,
                Memc[str], SZ_FNAME, clindex, clsize)
            nimdir = fnldir (Memc[root], Memc[str], SZ_FNAME)
            if (clindex >= 0) {
                call sprintf (name[ndir+1], maxch, "%s%d.%s.*")
                    call pargstr (Memc[root+nimdir])
                    call pargi (clindex)
                    call pargstr (ext)
            } else {
                call sprintf (name[ndir+1], maxch, "%s.%s.*")
                    call pargstr (Memc[root+nimdir])
                    call pargstr (ext)
            }
	    call dp_iversion (name, name, maxch)
	} else
	    call strcpy (input, name, maxch)

	call sfree (sp)
end


# DP_OUTNAME -- Procedure to construct an daophot output file name.
# If output is null or a directory a name is constructed from the root
# of the image name and the extension. The disk is searched to avoid
# name collisions.

procedure dp_outname (image, output, ext, name, maxch)

char	image[ARB]		# image name
char	output[ARB]		# output directory or name
char	ext[ARB]		# extension
char	name[ARB]		# output name
int	maxch			# maximum size of name

int	ndir, nimdir, clindex, clsize
pointer	sp, root, str
int	fnldir(), strlen()

begin
	call smark (sp)
	call salloc (root, SZ_FNAME, TY_CHAR)
	call salloc (str, SZ_FNAME, TY_CHAR)

	ndir = fnldir (output, name, maxch)
	if (strlen (output) == ndir) {
           call imparse (image, Memc[root], SZ_FNAME, Memc[str], SZ_FNAME,
                Memc[str], SZ_FNAME, clindex, clsize)
            nimdir = fnldir (Memc[root], Memc[str], SZ_FNAME)
            if (clindex >= 0) {
                call sprintf (name[ndir+1], maxch, "%s%d.%s.*")
                    call pargstr (Memc[root+nimdir])
                    call pargi (clindex)
                    call pargstr (ext)
            } else {
                call sprintf (name[ndir+1], maxch, "%s.%s.*")
                    call pargstr (Memc[root+nimdir])
                    call pargstr (ext)
            }
	    call dp_oversion (name, name, maxch)
	} else
	    call strcpy (output, name, maxch)

	call sfree (sp)
end


# DP_OVERSION -- Routine to compute the next available version number of a given
# file name template and output the new files name.

procedure dp_oversion (template, filename, maxch)

char	template[ARB]			# name template
char	filename[ARB]			# output name
int	maxch				# maximum number of characters

char	period
int	newversion, version, len
pointer	sp, list, name
int	fntgfnb() strldx(), ctoi(), fntopnb()

begin
	# Allocate temporary space
	call smark (sp)
	call salloc (name, maxch, TY_CHAR)
	period = '.'
	list = fntopnb (template, NO)

	# Loop over the names in the list searchng for the highest version.
	newversion = 0
	while (fntgfnb (list, Memc[name], maxch) != EOF) {
	    len = strldx (period, Memc[name])
	    len = len + 1
	    if (ctoi (Memc[name], len, version) <= 0)
		next
	    newversion = max (newversion, version)
	}

	# Make new output file name.
	len = strldx (period, template)
	call strcpy (template, filename, len)
	call sprintf (filename[len+1], maxch, "%d")
	    call pargi (newversion + 1)

	call fntclsb (list)
	call sfree (sp)
end


# DP_IVERSION -- Routine to compute the last version number of a given
# file name template and output the new files name.

procedure dp_iversion (template, filename, maxch)

char	template[ARB]			# name template
char	filename[ARB]			# output name
int	maxch				# maximum number of characters

char	period
int	newversion, version, len
pointer	sp, list, name
int	fntgfnb() strldx(), ctoi(), fntopnb()

begin
	# Allocate temporary space
	call smark (sp)
	call salloc (name, maxch, TY_CHAR)
	period = '.'
	list = fntopnb (template, NO)

	# Loop over the names in the list searchng for the highest version.
	newversion = 0
	while (fntgfnb (list, Memc[name], maxch) != EOF) {
	    len = strldx (period, Memc[name])
	    len = len + 1
	    if (ctoi (Memc[name], len, version) <= 0)
		next
	    newversion = max (newversion, version)
	}

	# Make new output file name.
	len = strldx (period, template)
	call strcpy (template, filename, len)
	call sprintf (filename[len+1], maxch, "%d")
	    call pargi (newversion)

	call fntclsb (list)
	call sfree (sp)
end


# DP_FROOT -- Fetch the file name minus the directory specification,

procedure dp_froot (filename, root, maxch)

char    filename[ARB]           # input file name
char    root[ARB]               # output root file name
int     maxch                   # maximum number of characters

pointer sp, str
int     nchars
int     fnldir()

begin
        call smark (sp)
        call salloc (str, SZ_PATHNAME, TY_CHAR)

        nchars = fnldir (filename, Memc[str], SZ_PATHNAME)
        call strcpy (filename[nchars+1], root, maxch)

        call sfree (sp)
end
