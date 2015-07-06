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
    if (-f "deps/$dep/LICENSE") {
        $license_file = "deps/$dep/LICENSE";
    } elsif (-f "deps/$dep/LICENSE.md") {
        $license_file = "deps/$dep/LICENSE.md";
    } elsif (-f "deps/$dep/LICENSE.txt") {
        $license_file = "deps/$dep/LICENSE.txt";
    }

    my $license = "unknown";

    if (defined $license_file) {
        print("figure out license: $license_file\n") if $DEBUG;
        $license = detect_license($license_file);
    }

    my $github_repo;
    my $repo_url = "unknown";
    my $license_link = "unknown";

    if (-f "deps/$dep/.git/config") {
        print("file: ","deps/$dep/.git/config","\n") if $DEBUG;
        my @urls = `grep url deps/$dep/.git/config`;

        for my $u (@urls) {
            chomp $u;
            print Dumper $1 if ($u =~ /url\s+=\s+(.*)/ && $DEBUG);
            if (defined  $license_file) {
                if ($u =~ /(git|https?):\/\/github.com\/(.*)\.git/) {
                    $github_repo = $2 
                } elsif ($u =~ /(git|https?):\/\/github.com\/(.*)/) {
                    $github_repo = $2 
                }
                $license_link = sprintf("https://github.com/%s/blob/master/%s", $github_repo, basename($license_file));
                if (defined $github_repo) {
                    $repo_url = sprintf('https://github.com/%s', $github_repo);
                }
            }
        }
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

    return $license;
}

