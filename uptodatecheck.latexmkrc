$pdflatex = $latex = 'internal die_pdflatex %S';
sub die_pdflatex {
    # Stop now, otherwise latexmk will update its knowledge of the
    # source files and not realize files are out-of-date on the next run.
    die "I won't do anything, but just note that '$_[0]' is out of date\n";
}
