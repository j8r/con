require "./helper"
require "json"
require "../src/any"

Benchmark.ips do |x|
  x.report("#to_con") do
    DATA.to_con
  end

  x.report("#to_pretty_con") do
    DATA.to_pretty_con
  end

  x.report("#to_json") do
    DATA.to_json
  end

  x.report("#to_pretty_json") do
    DATA.to_pretty_json
  end
end
