ENV["BUNDLE_GEMFILE"] ||= File.expand_path("../Gemfile", __dir__)

require "bundler/setup" # Set up gems listed in the Gemfile.

if %w[development test].include?(ENV.fetch("RAILS_ENV", "development"))
  begin
    require "dotenv/load"
  rescue LoadError
    # dotenv is optional; real environment variables still work without it.
  end
end

require "bootsnap/setup" # Speed up boot time by caching expensive operations.
