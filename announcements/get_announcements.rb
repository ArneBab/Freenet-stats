#this script requires log level MINOR on the freenet class: freenet.node.NodeDispatcher
require 'date'

#determine the most recent timestamp, any new entries to be added should be newer than this
#open db, get last line, get timestamp value
timestamp = `tail -n 1 announcements.txt`.split("\t")[0].to_i

#puts "last timestamp = #{timestamp}"

#open the log file for reading
f = File.open("/home/tmarkus/freenet/freenet/logs/freenet-latest.log", "r")
data = File.open("announcements.txt", "a")

f.each_line do |line|
	if line =~ /Announcement from freenet.node.SeedClientPeerNode.* completed.* added/
		current_timestamp, added, not_wanted = line.scan( /^(.*) \(freenet\.node.*(\d+) added, (\d+) not wanted/ )[0]
	
		current_timestamp 	= DateTime.parse(current_timestamp).to_time.to_i
		added 				= added.to_i
		not_wanted 			= not_wanted.to_i
	
		if current_timestamp > timestamp
			data.write("#{current_timestamp}\t#{added}\t#{not_wanted}\n")
		end
	end
end

data.close
f.close
