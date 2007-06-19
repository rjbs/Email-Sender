use Test::More;
plan skip_all => "not now, dear";

eval "use Test::Pod::Coverage 1.06";
plan skip_all => "Test::Pod::Coverage 1.06 required for testing POD coverage"
	if $@;
all_pod_coverage_ok();
