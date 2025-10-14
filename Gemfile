# frozen_string_literal: true

source "https://rubygems.org"

ruby RUBY_VERSION

gem "decidim", "0.30.0"
# gem "decidim-ai", "0.30.0"
# gem "decidim-conferences", "0.30.0"
# gem "decidim-design", "0.30.0"
# gem "decidim-initiatives", "0.30.0"
# gem "decidim-templates", "0.30.0"

gem "bootsnap", "~> 1.3"

gem "puma", ">= 6.3.1"
gem "dotenv-rails", "~> 2.8"
group :development, :test do
  gem "byebug", "~> 11.0", platform: :mri

  gem "brakeman", "~> 7.0"
  gem "decidim-dev", "0.30.0"
  gem "net-imap", "~> 0.5.0"
  gem "net-pop", "~> 0.1.1"
end

group :development do
  gem "letter_opener_web", "~> 2.0"
  gem "listen", "~> 3.1"
  gem "web-console", "~> 4.2"
end

group :production do
  gem 'delayed_job_active_record'
  gem "daemons"
end
