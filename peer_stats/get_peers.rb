#!/usr/bin/ruby1.9.1

require 'rubygems'
require 'nokogiri'
require 'open-uri'


connected = 0
seeding_for = 0
backed_off = 0

types = ["Connected", "Disconnected", "Disconnecting", "Backed off", "Never connected", "Seeding for"]
values = Hash.new(0)

open("http://127.0.0.1:8888/diagnostic/") do |f|
	f.each_line do |line|
		types.each do |type|
			values[type] = line.scan(/#{type}: (\d+)/).last.first.to_i	if line =~ /#{type}: /	
		end
	end
end

#puts values.inspect


data = File.open("connection_history.txt", "a")
	data.write Time.now.to_i
	types.each do |type|
		data.write "\t" + values[type].to_s
	end
	data.write("\n")
data.close
