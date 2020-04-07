#!/usr/bin/env ruby

require 'json'
require 'rmagick'

# Load data
data = JSON.parse(File.read('results.json'))

# Init stats hashes
top_1000 = {
  "security.txt" => 0,
  "acknowledgments" => 0,
  "canonical" => 0,
  "contact" => 0,
  "encryption" => 0,
  "expires" => 0,
  "hiring" => 0,
  "policy" => 0,
  "preferred-languages" => 0,
  "signed" => 0
}
top_10 = top_1000.dup
top_100 = top_1000.dup

# Stats
top_1000.each_key do |k|
  top_1000[k] = data.take(1000).select{ |x| x[k] == true }.count
  top_100[k] = data.take(100).select{ |x| x[k] == true }.count
  top_10[k] = data.take(10).select{ |x| x[k] == true }.count
end
puts 'Top 10 domains supporting security.txt'
i = 0
File.readlines('top-1m.csv').each do |line|
  index = line.split(',')[0].to_i
  domain = line.split(',')[1].chomp

  #puts line.chomp + ",#{data[index - 1]['security.txt']}"
  if data[index-1]['security.txt']
    puts line
    i += 1
  end

  break if i == 10
end

# Display
puts "\nTop 10"
pp top_10
puts "\nTop 100"
pp top_100
puts "\nTop 1000"
pp top_1000

# Binary/pixel map
width = 40
height = 25
img = Magick::Image.new(width, height)
i = 0
(0...width).each do |x|
  (0...height).each do |y|
    # orange (0)
    img.pixel_color(x, y, "rgb(255,66,14)")
    # blue (1)
    img.pixel_color(x, y, "rgb(0,69,134)") if data[i]["security.txt"]
    i+=1
  end
end
img.write('pixel.png')
