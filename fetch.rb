#!/usr/bin/env ruby

require 'net/http'
require 'json'

DEBUG = false

# Handle redirections
def fetch(uri_str, limit = 5)
  begin
    http = Net::HTTP.new(URI(uri_str).host, URI(uri_str).port)
    # Limit timeout to 10s
    http.open_timeout = 10
    http.read_timeout = 10
    if URI(uri_str).scheme == 'https'
      http.use_ssl = true
      http.min_version = nil # any SSL version
    end
    response = http.request_get(URI(uri_str))
  rescue Timeout::Error
    response = Net::HTTPResponse.new(1.1, 504, 'Timeout')
    puts 'Timeout' if DEBUG
  rescue ArgumentError
    response = Net::HTTPResponse.new(1.1, 400, 'Bad request')
    puts 'Bad request' if DEBUG
  rescue Errno::ECONNRESET
    response = Net::HTTPResponse.new(1.1, 500, 'Connection reset by peer')
    puts 'Connection reset by peer' if DEBUG
  rescue SocketError
    response = Net::HTTPResponse.new(1.1, 404, 'No address associated with hostname')
    puts 'No address associated with hostname' if DEBUG
  rescue Errno::ECONNREFUSED
    response = Net::HTTPResponse.new(1.1, 403, 'Connection refused')
    puts 'Connection refused' if DEBUG
  rescue Zlib::DataError
    response = Net::HTTPResponse.new(1.1, 500, 'Zlib::DataError')
    puts 'Zlib::DataError' if DEBUG
  rescue OpenSSL::SSL::SSLError
    response = Net::HTTPResponse.new(1.1, 400, 'SSL error')
    puts 'SSL error' if DEBUG
  rescue Errno::EHOSTUNREACH
    response = Net::HTTPResponse.new(1.1, 400, 'No HTTPS or nor route to host')
    puts 'No HTTPS or no route to host' if DEBUG
  rescue EOFError
    response = Net::HTTPResponse.new(1.1, 400, 'Unexpected error')
    puts 'Unexpected error' if DEBUG
  end

  # Limit redirection
  response = Net::HTTPResponse.new(1.1, 418, 'Timeout') if limit == 0

  case response
  when Net::HTTPRedirection then
    location = response['location']
    warn "redirected to #{location}" if DEBUG
    fetch(location, limit - 1)
  else
    response
  end
end

# Check if the fetched response contains a security.txt
def security_txt?(res)
  is_ok = true
  is_ok = false unless res.code == '200'
  unless res.get_fields('content-type').nil?
    is_ok = false unless /text\/plain/.match?(res.get_fields('content-type')[0])
  end
  return is_ok
end

# Parse the security.txt file
def parse(text)
  {
    "security.txt": true,
    "acknowledgments": /Acknowledgments:/.match?(text),
    "canonical": /Canonical:/.match?(text),
    "contact": /Contact:/.match?(text),
    "encryption": /Encryption:/.match?(text),
    "expires": /Expires:/.match?(text),
    "hiring": /Hiring:/.match?(text),
    "policy": /Policy:/.match?(text),
    "preferred-languages": /Preferred-Languages:/.match?(text),
    "signed": /-----BEGIN PGP SIGNATURE-----/.match?(text)
  }

end

results = []

File.readlines('top-1m.csv').each do |line|
  puts line

  #next if line.split(',')[0].to_i < 163

  domain = line.split(',')[1].chomp
  res = fetch("https://#{domain}/.well-known/security.txt")
  res = fetch("https://#{domain}/security.txt") unless security_txt?(res)
  if security_txt?(res)
    results.push(parse(res.body).merge({"domain" => domain}))
  else
    results.push({"security.txt": false, "domain" => domain})
  end

  # Test stop at 1000
  break if line.split(',')[0] == '1000'
end

File.write("results_#{Time.now.strftime("%Y-%m-%d")}.json",JSON.fast_generate(results))
