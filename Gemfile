source "https://rubygems.org"

gemspec

gem "rake"
gem "minitest"

ar_version = ENV["AR_VERSION"] || "7.1.0"
gem "activerecord", "~> #{ar_version}"

case ENV["ADAPTER"]
when "postgresql"
  gem "pg"
when "mysql"
  gem "mysql2"
else
  gem "sqlite3"
end
