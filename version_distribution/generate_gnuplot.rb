require 'set'

#open the file
data = File.open("version_history.txt", "r")

#select the data from the past week
past_time = Time.now - (60*60*24*3)

#generate gnuplot for that data (you'd have to make a legenda of the different versions)
peers = Hash.new
versions = Set.new
data.each_line do |line|
	split = line.chomp.split("\t")
	time = split.shift.to_i
	if (time > past_time.to_i)

		peerData = Hash.new

		split.each do |versionCount|
			version, count = versionCount.split(":")
			versions.add version
			peerData[version] = count.to_i
		end
		peers[time] = peerData
	end
end

#sort the versions
versions = versions.to_a.sort


output = File.open("3_days.txt", "w")

output.write("time\t" + versions.to_a.join("\t") + "\n")

peers.each_key do |key|
	output.write key.to_s
	versions.each do |v|
		if peers[key].has_key? v
			output.write("\t" + peers[key][v].to_s)
		else
			output.write("\t0")
		end
	end
	output.write("\n")
end
output.close
