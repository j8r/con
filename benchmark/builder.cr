require "./helper"
require "json"
require "../src/any"

Benchmark.ips do |x|
  x.report("CON::Builder minified") do
    DATA.to_con
  end

  x.report("CON::Builder pretty") do
    DATA.to_pretty_con
  end

  x.report("JSON::Builder minified") do
    DATA.to_json
  end

  x.report("JSON::Builder pretty") do
    DATA.to_pretty_json
  end
end
