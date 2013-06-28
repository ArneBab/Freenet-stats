require 'date'

data = File.open("announcements.txt")
plot_data = File.open("plot_data.txt", "a")

#write header
#plot_data.write("Time\t\"added\"\t\"not wanted\"\t\"Announcements\"\n")

current = nil
avg = Hash.new(0)
count = 0

data.each_line do |line|
	
	timestamp, added, not_wanted = line.split("\t")
	timestamp = DateTime.strptime(timestamp,'%s')
	timestamp = DateTime.new(timestamp.year, timestamp.month, timestamp.day, timestamp.hour, 0, 0)

	if current == nil || current == timestamp
		avg[:added] += added.to_i
		avg[:not_wanted] += not_wanted.to_i
		count += 1
	else
		plot_data.write("#{timestamp.to_time.to_i}\t#{avg[:added].to_f/count}\t#{avg[:not_wanted].to_f/count}\t#{count}\n")

		#reset		
		count = 0
		avg = Hash.new(0)
		
		#add the current one
		avg[:added] += added.to_i
		avg[:not_wanted] += not_wanted.to_i
		count += 1
	end

	current = timestamp
end

plot_data.close
data.close
File.truncate("announcements.txt", 0)
