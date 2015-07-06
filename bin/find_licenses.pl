#!/usr/bin/perl -w

use File::Basename;
use Data::Dumper;

my $DEBUG = 0;

my $repo_name = basename(`pwd`);

chomp($repo_name);

print "me: ",$repo_name,"\n" if $DEBUG;

my $directory = 'deps';

opendir (DIR, $directory) or die $!;
while (my $dep = readdir(DIR)) {
    next if ($dep =~ /^\./);
    print("------------------------\n") if $DEBUG;
    print "dep: $dep\n" if $DEBUG;

    my $license_file;
    if (-f "$directory/$dep/LICENSE") {
        $license_file = "$directory/$dep/LICENSE";
    } elsif (-f "$directory/$dep/LICENSE.md") {
        $license_file = "$directory/$dep/LICENSE.md";
    } elsif (-f "$directory/$dep/LICENSE.txt") {
        $license_file = "$directory/$dep/LICENSE.txt";
    } elsif (-f "$directory/$dep/COPYING") {
        $license_file = "$directory/$dep/COPYING";
    } elsif (-f "$directory/$dep/COPYING.md") {
        $license_file = "$directory/$dep/COPYING.md";
    } elsif (-f "$directory/$dep/COPYING.txt") {
        $license_file = "$directory/$dep/COPYING.txt";
    }

    my $license = "unknown";

    if (defined $license_file) {
        print("figure out license: $license_file\n") if $DEBUG;
        $license = detect_license($license_file);
    }

    my $github_repo;
    my $repo_url = "unknown";
    my $license_link = "unknown";

    my $git_config;

    if (-f "$directory/$dep/.git/config") {
        print("file: ","$directory/$dep/.git/config","\n") if $DEBUG;
        $git_config = "$directory/$dep/.git/config";
    } elsif (-f "$directory/$dep/.git") {
        my $dot_git = `cat $directory/$dep/.git`;
        if ($dot_git =~ /gitdir: (.*)/) {
            $git_config = "$directory/$dep/".$1."/config";
        }
    }
    if ($git_config) {
        my @urls = `grep url $git_config`;

        print "urls".Dumper \@urls if $DEBUG;

        for my $u (@urls) {
            chomp $u;
            print Dumper $1 if ($u =~ /url\s+=\s+(.*)/ && $DEBUG);
#url = git@github.com:campanja/stripe-erlang.git
            if ($u =~ /(git|https?):\/\/github.com\/(.*)\.git/) {
                $github_repo = $2 
            } elsif ($u =~ /(git|https?):\/\/github.com\/(.*)/) {
                $github_repo = $2 
            } elsif ($u =~ /git\@github.com:(.*)\.git/) {
                $github_repo = $1 
            } elsif ($u =~ /git\@github.com:(.*)/) {
                $github_repo = $1 
            }

            if (defined  $license_file) {
                $license_link = sprintf("https://github.com/%s/blob/master/%s", $github_repo, basename($license_file));
            }

            if (defined $github_repo) {
                $repo_url = sprintf('https://github.com/%s', $github_repo);
            }
        }
        #die if $dep eq 'stripe';
    }

    my $info = {
        'app_name'     => $repo_name,
        'dep'          => $dep,
        'repo_url'     => $repo_url,
        'license'      => $license,
        'license_link' => $license_link
        };
    print Dumper $info if $DEBUG;
    # Campanja Repo      Dependency        Automated License detected       License url          Repo URL
    printf("%s\t%s\t%s\t%s\t%s\n", $info->{'app_name'}, $info->{'dep'}
            , $info->{'license'}, $info->{'license_link'}, $info->{'repo_url'});
}
closedir(DIR);

sub detect_license {
    my $file = shift;

    my $license = "unknown";

    my $content = `cat $file`;

    $license = 'MOZILLA PUBLIC LICENSE ('.$1.')' if ($content =~ /MOZILLA PUBLIC LICENSE\s+Version ([0-9\.]+)/i);
    $license = 'MIT license' if ($content =~ /MIT license/i);
    $license = 'Apache License ('.$1.')' if ($content =~ /Apache License\s+Version ([0-9\.]+)/i);
    $license = 'Apache License ('.$1.')' if ($content =~ /Apache License, Version ([0-9\.]+)/i);
    $license = 'LGPL ('.$1.')' if ($content =~ /under the terms of the GNU Lesser General Public License as published by the Free Software Foundation; either version ([0-9\.]+) of the License/);
    $license = 'BSD-style' if ($content =~ /\Q"AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL Joseph Abrahamson BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE./);
    $license = '2-clause BSD' if ($content =~ /\Q"AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL Joseph Abrahamson BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE./
                    && $content =~ /\QRedistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:/
                    && $content =~ /\QRedistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer./
                    && $content =~ /\QRedistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and\/or other materials provided with the distribution./);
    $license = 'CDDL ('.$1.')' if ($content =~ /COMMON DEVELOPMENT AND DISTRIBUTION LICENSE \(CDDL\) Version ([0-9\.]+)/);

    return $license;
}

