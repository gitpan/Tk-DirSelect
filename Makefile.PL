use ExtUtils::MakeMaker;
WriteMakefile(
              NAME => "Tk::DirSelect",
	      PM => { 'DirSelect.pm' => '$(INST_LIBDIR)/DirSelect.pm' },
              VERSION_FROM => 'DirSelect.pm',
              'dist' => {COMPRESS=>'gzip -9f', SUFFIX => 'gz'},
             );
