xsltproc = find_program('xsltproc', required: false)

if xsltproc.found()
    stylesheet = 'http://docbook.sourceforge.net/release/xsl/current/manpages/docbook.xsl'

    xlstproc_flags = [
        '--nonet',
        '--stringparam', 'man.output.quietly', '1',
        '--stringparam', 'funcsynopsis.style', 'ansi',
        '--stringparam', 'man.authors.section.enabled', '1',
        '--stringparam', 'man.copyright.section.enabled', '1',
    ]

    xsltproc_args = [
        xsltproc,
        xlstproc_flags,
        '-o', '@OUTPUT@',
        stylesheet,
        '@INPUT@',
    ]

    man_input_files = [
        'rygel.xml',
        'rygel.conf.xml'
    ]

    man_output_files = [
        'rygel.1',
        'rygel.conf.5'
    ]

    r = run_command(
        [
            xsltproc,
            xlstproc_flags,
            '--noout',
            stylesheet,
            'rygel.xml'
        ],
        check: true
    )

    if (r.returncode() == 0)
        message('docbook stylesheets found')
        custom_target(
            'man 1 pages',
            input: 'rygel.xml',
            output: 'rygel.1',
            command: xsltproc_args,
            install: true,
            install_dir: join_paths(get_option('mandir'), 'man1')
        )

        custom_target(
            'man 5 pages',
            input: 'rygel.conf.xml',
            output: 'rygel.conf.5',
            command: xsltproc_args,
            install: true,
            install_dir: join_paths(get_option('mandir'), 'man5')
        )
    else
        error('Cannot bulid man pages, failed to run xsltproc')
    endif
endif
