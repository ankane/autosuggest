source "https://rubygems.org"

gemspec

gem "rake"
gem "minitest"
gem "activerecord"

case ENV["ADAPTER"]
when "postgresql"
  gem "pg"
when "mysql"
  gem "mysql2"
else
  gem "sqlite3"
end
