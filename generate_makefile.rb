
EXTENSIONS = {}
def add_extensions(exts, tool)
  exts.each do |extension|
    EXTENSIONS[extension] = tool
  end
end


require_relative 'extensions.rb'


f = File.new("Makefile", "w")

f << <<-EOF
#Dependencies:
# perl, whatever version your system has is fine
# ag, https://github.com/ggreer/the_silver_searcher
# ctags, http://ctags.sourceforge.net/, 'sudo apt-get install etags' should work
# rtags, https://github.com/bloopletech/rtags

EOF

EXTENSIONS.each_pair do |extension, tool|
  f << "vpath #{extension} $(srcdir)\n"
end

f << <<-EOF2

all : files.list files.tags files.mak tags.tags

files.tags : files.list
\tperl -pe 's/^(.*)$$/\\1\\tpath\\t\\1\\t1/g' < $< > $@

files.list :
\tcd $(srcdir) && ag --search-files --nocolor --ignore '*.tags' -L '.{1000,}' | xclude_long_files > $(abspath $@)

files.mak : files.list
\tperl -pe 's/^(.*\\/)?(.*)$$/tags.tags : \\1 \\1\\2.tags\\n/g' < $< > $@
\tperl -pe 's/^(.*\\/)?(.*)$$/\\1/g' < $< | sed '/^$$/d' | sort -u | perl -pe 's/^(.*)$$/\\1 : \\n\\tmkdir -p \\$$@\\n/g' >> $@

.DEFAULT : 
	touch $<

EOF2

EXTENSIONS.each_pair do |extension, tool|
  f << <<-EOE2
#{extension}.tags : #{extension}
\t#{tool} $< | perl -pe 's/^([^ ]+) +(\\d+) +([^ ]+?) +(.+?)$$/\\1\\t\\4\\t\\3\\t\\2/g' > $@

EOE2
end

f << <<-EOF3
tags.tags : files.tags
	cat $(filter %.tags,$^) | sed '/^$$/d' > tags.tags

include files.mak
EOF3

f.close

