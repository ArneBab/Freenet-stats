#!/usr/bin/ruby1.9.1

require 'rubygems'
require 'nokogiri'
require 'open-uri'

page = Nokogiri::HTML(open("http://127.0.0.1:8888/strangers/?fproxyAdvancedMode=1"))

peers = Hash.new(0)
page.css("td.peer-version").each do |peer|
	peers[peer.text.strip!] += 1
end

data = File.open("version_history.txt", "a")

current_time = Time.now
line = current_time.to_i.to_s
peers.each_key {|key| line += "\t#{key}:#{peers[key]}" }

data.write(line + "\n")

data.close
