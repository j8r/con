require "./helper"
require "json"
require "../src/any"

CON_MIN    = DATA.to_con
CON_PRETTY = DATA.to_pretty_con

JSON_MIN    = DATA.to_json
JSON_PRETTY = DATA.to_pretty_json

Benchmark.ips do |x|
  x.report("CON.parse minified") do
    CON.parse CON_MIN
  end

  x.report("CON.parse pretty") do
    CON.parse CON_PRETTY
  end

  x.report("JSON.parse minified") do
    JSON.parse JSON_MIN
  end

  x.report("JSON.parse pretty") do
    JSON.parse JSON_PRETTY
  end
end
