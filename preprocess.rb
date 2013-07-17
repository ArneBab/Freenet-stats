CHUNKS = 32

# available deltas in the daily sample
def createAvailable(split) 
    start = CHUNKS*2+3
    available = []
    
    while(start < split.length)
        available.push split[start].chomp.to_i
        start += CHUNKS+1
    end
    return available
end


def getFetchRatio(available, delta, split) #fetch ratio for a specific delta, for a specific sample
        available.each_index do |index|
            if (available[index].eql?(delta))
                    success = 0
                    ((CHUNKS*2+3+(index*33+1))..(CHUNKS*2+3+(index*33)+CHUNKS)).each do |pos|
                        if (split[pos].to_i > 0) 
                            success += 1
                        end    
                    end
                    success_value = success.to_f/CHUNKS
                    return success_value
            end
        end
        return nil
end

def getAverageFetchTime(available, delta, split) #fetch times for a specific delta, for a specific sample
        success = 0

        available.each_index do |index|
            if (available[index].eql?(delta))
                    ((CHUNKS*2+3+(index*33+1))..(CHUNKS*2+3+(index*33)+CHUNKS)).each do |pos|
                        if (split[pos].to_i > 0) 
                            success += split[pos].to_i
                        end    
                    end
                    success_value = success.to_f/CHUNKS
                    return success_value
            end
        end
        return nil
end


def getAverageInsertTime(split) #insert time for a certain date
        success = 0
        (3..(CHUNKS*2+3)).step(2) do |pos|
            if (split[pos].to_i > 0) 
                success += split[pos].to_i
            end    
        end
        success_value = success.to_f/CHUNKS
        return success_value
end

#request statistics and fetch ratios
fetch = File.open("fetch.csv", "w")

fetch.puts "version\tdate\tdelta\tratio\ttime"
data = File.open("data.txt", "r")
data.each_line do |line|
	split = line.split("!")
	version = split[1]
	date = split[0]

	available = createAvailable(split)
	
	1.upto(8).each do |delta|
		ratio = getFetchRatio(available, delta, split)
		time = getAverageFetchTime(available, delta, split)
		if (ratio != nil)
			fetch.puts "#{version}\t#{date}\t#{delta}\t#{ratio}\t#{time}"
		end
	end
end
fetch.close
data.close


#insert times
data = File.open("data.txt", "r")
insert = File.open("insert.csv", "w")
insert.puts "version\tdate\ttime"
data.each_line do |line|
	split = line.split("!")
	version = split[1]
	date = split[0]
	
	time = getAverageInsertTime(split)
	insert.puts "#{version}\t#{date}\t#{time}"	if (time > 0.0)
end
insert.close
data.close

