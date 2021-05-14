#!/usr/bin/env ruby

require 'json'
require_relative 'fetch'

# Load data
data = JSON.parse(File.read('results_2021-05-14.json'))

data.each do |e|
  if e['security.txt'] == true
    domain = e['domain']
    print "#{domain},"
    res = fetch("https://#{domain}/.well-known/security.txt")
    res = fetch("https://#{domain}/security.txt") unless security_txt?(res)
    puts res.body.match(/Contact:(.+)/).captures[0] if e['contact']
  end
end
