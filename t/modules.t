use Test::More tests => 7;

require_ok(Mail::Sender);
require_ok(Config::IniFiles);
require_ok(Archive::Zip);
require_ok(Email::MIME);
require_ok(File::Path);
require_ok(Net::POP3);
require_ok(Log::Log4perl);

done_testing();
