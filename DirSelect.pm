# DirSelect: A Tk directory selection widget.
#
# This widget allows navigating MS Windows local and mapped network
# drives and directories and selecting a directory.
#

#
# On non-MS systems, this is simply a dialog box with a Dirtree in it.
#
# supercedes all versions of Win32Dirselect 
# Usage: my $dir = $mainwindow->DirSelect->Show;
# Options: -dir=>"directory", -w=>"width"
# 
# Email comments, questions or bug reports to Kristi Thompson, kristi@indexing.ca

package DirSelect;
use vars qw($VERSION);
$VERSION = '1.03';    

@EXPORT_OK = qw(glob_to_re);
use strict;
use English;
require Tk::Derived;
use vars qw(@EXPORT_OK);
use base qw(Tk::Toplevel);
use Tk::widgets qw(Frame Button Radiobutton Label DirTree);
use Cwd;

Construct Tk::Widget 'DirSelect';

sub Populate {
    my($cw, $args) = @ARG;
    $cw->SUPER::Populate($args);
	 my $width = delete $args->{-width};
	 my $directory = delete $args->{-dir};
    my $top = $cw->Frame(
	-relief  => 'groove',
	-bd      => 2,
    )->pack(
	-fill    => 'x',
	-padx    => 2,
	-pady    => 3,
    );
    my $mid = $cw->Frame->pack(
	-fill    => 'both',
	-expand  => 1,
    );
    my $bottom = $cw->Frame->pack(
	-fill    => 'x',
	-ipady   => 6,
    );

    $bottom->Button(
	-width   => 7,
	-text    => 'OK',
	-command => sub {$cw->{dir} = $mid->packSlaves->selectionGet()},
    )->pack(
	-side    => 'left',
	-expand  => 1,
    );
    $bottom->Button(
	-width   => 7,
	-text    => 'Cancel',
	-command => sub {$cw->{dir} = undef},
    )->pack(
	-side    => 'left',
	-expand  => 1,
    );

    if ($OSNAME !~ /mswin/i) {
    	$top->packForget;
    	my $d = $directory;
   	$d = '/' if (!$d);
		_dirtree($mid, $d, $width);
    } else {	
	require Win32API::File;					
	my @drives = Win32API::File::getLogicalDrives();	
	my $startdir, my $startdrive;
	if ($directory) {
		$startdrive = _drive($directory);
		$startdir = $directory;}
	else {$startdrive= _drive(cwd); $startdir = _drive(cwd);}
	
	my $selcolor   = $top->cget(-background);

	foreach my $d (@drives) {
	    my $drive = _drive($d);
	    my $b = $top->Radiobutton(
		-selectcolor => $selcolor,
		-indicatoron => 0,
		-text        => $drive,
		-width       => 3,
		-command     => [\&_browse, $mid, $d, $width],
		-value       => $d,
	    )->pack(
		-side => 'left',
		-padx => 4,
		-pady => 6,
	    );
	   if (lc $startdrive eq lc $drive){
	    	$b->invoke;
	    	_browse($mid, $startdir, $width);
	 	}
	}
  }
}

sub _browse {
    my($f, $d, $w) = @ARG;

    foreach ($f->packSlaves) {$_->packForget;}

    my %drives = (
	0 => 'Unknown',		1 => 'No root drive',	2 => 'Removable disk drive',
	3 => 'Fixed disk drive',4 => 'Network drive',	5 => 'CD-Rom drive',
	6 => 'RAM Disk'
    );

    my $drive = _drive($d);
    if (chdir($drive)) {
	my $volumelabel;
	Win32API::File::GetVolumeInformation($drive, $volumelabel, [], [], [], [], [], []);
	my $drivetype = Win32API::File::GetDriveType($drive);
	_drivelabel($f, "$volumelabel ($drive) $drives{$drivetype}");
	_dirtree($f, $d, $w);
    } else {
	_drivelabel($f, "$drive is not available.");
    }
}

sub _dirtree {
    my($f, $d, $w) = @ARG;
    chdir $d;    
    my $dt = $f->Scrolled('DirTree',
		-scrollbars => 'osoe',
		-directory  => $d,
		-selectmode =>'browse',
		-ignoreinvoke =>0,		
		-background => 'white',
		-selectbackground => "gray61",
		-selectforeground => "white",		
		-width 		=> $w
		)->pack(
			-fill   => 'both',
			-expand => 1,
			-pady   => 4,
    		);
    $dt->configure(-command    => sub { $dt->opencmd($_[0]) });
    $dt->configure(-browsecmd  => sub { $dt->anchorClear });
}

sub Show {
    my($cw, $grab) = @ARG;
    my $old_focus = $cw->focusSave;
    my $old_grab  = $cw->grabSave;
    $cw->Popup();
    Tk::catch {
	if (defined($grab) and length($grab) and $grab =~ /global/i) {
	    $cw->grabGlobal;
	} else {
	    $cw->grab;
	}
    };
    $cw->focus;
    $cw->_wait;
    &$old_focus;
    &$old_grab;
    return($cw->{dir});
}

sub _drivelabel {
    my($f, $msg) = @ARG;
    $f->Label(
	-text   => " $msg",
	-relief => 'sunken',
	-bd     => 1,
	-anchor => 'w',
    )->pack(
	-padx   => 2,
	-fill   => 'x',
	-ipady  => 2,
    );
}

sub _drive {
    shift =~ /^(.*:)/;
    return($1);
}



sub _wait {
    my($cw) = @ARG;
    $cw->waitVariable(\$cw->{dir});
    $cw->grabRelease;
    $cw->withdraw;
    $cw->Callback(-command => $cw->{dir});
}

1;
