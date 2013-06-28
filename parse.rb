require 'rubygems'
require 'statsample'
require 'set'

lines = File.new("data.csv", "r:UTF-8").readlines()
date_line = Hash.new
version_line = Hash.new

total = 0;
versions = Hash.new
ALPHA = 0.05
CHUNKS = 32
MINIMUM_SAMPLE_SIZE = 10

class Float
  def round_to(x)
    (self * 10**x).round.to_f / 10**x
  end

  def ceil_to(x)
    (self * 10**x).ceil.to_f / 10**x
  end

  def floor_to(x)
    (self * 10**x).floor.to_f / 10**x
  end
end

def tableRow(version1, version2, delta, alpha, dist1, dist2, text)
    return "<tr><td>#{text}</td><td>#{version2}</td><td>#{version1}</td><td>#{delta}</td><td>#{(1-alpha).round_to(5)}</td><td>#{dist1.mean.round_to(5)}</td><td>#{dist2.mean.round_to(5)}</td><td>#{dist1.size}</td><td>#{dist2.size}</td>"
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

def getAverageTime(available, delta, split) #fetch times for a specific delta, for a specific sample
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


def getAverageInsertTime(split) #insert time for a specific delta, for a specific sample
        success = 0
        (3..(CHUNKS*2+3)).step(2) do |pos|
            if (split[pos].to_i > 0) 
                success += split[pos].to_i
            end    
        end
        success_value = success.to_f/CHUNKS
        return success_value
end



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

#calculate certainty (statistical power), warning normal distribution assumption!
def certainty(raw_results)

    sample = raw_results.size

    if (sample > 2)
        raw_mean = (raw_results.inject {|sum,n| sum + n }).to_f / sample
        diff_squares = raw_results.collect {|n| (n - raw_mean) ** 2 }
        sigma = Math.sqrt( diff_squares.inject {|sum,n| sum + n } / (sample - 1) )
        certainty = 1 - (( sigma / Math.sqrt(sample) ) / raw_mean)
        
        return certainty 
    else
        return 0
    end
end


lines.each do |line|
    split = line.split("!")	
    
    #puts "Date: #{split[0]} with version: #{split[1]}"
    
    date = split[0]
    version = split[1].to_i
    parsed_date = Date.parse(date)
    date_line[parsed_date] = [] if (!date_line.has_key?(parsed_date)) 
    date_line[parsed_date].push(split)

    version_line[version] = [] if (!version_line.has_key?(version)) 
    version_line[version].push(split)
   
    
    if (split.length < CHUNKS)
        #puts "Incomplete data for date: #{date}"
    end
    
    #display delta's available in the row:
    available = createAvailable(split)
    
    #puts available.sort.inspect + " - #{date} - number of fields: " + split.length.to_s
    
    if (!versions.has_key?(version))
        versions[version] = Hash.new
    end

    (1..9).each do |delta|       
        if (!versions[version].has_key?(delta))
            versions[version][delta] = []
        end
     
        ratio = getFetchRatio(available, delta, split)
        versions[version][delta].push(ratio) if (ratio != nil)
    end
end


sorted_keys = versions.keys.sort

puts "<html>"
puts "<title>Freenet stats by digger3</title>"
puts "<body>"


puts "<p>"
puts "The following graph plots the reported freenet versions by opennet peers on my seednode. They give an indication of how fast a freenet version spreads through the network"
puts "</p>"
puts "<img style=\"width: 100%;\" src=\"version_distribution/versions.png\" alt=\"Reported freenet versions by opennet nodes on a seednode.\"/>"

puts "<p>"
puts "The following graph plots the number of connected nodes and their status (connected, disconnected, etc) with a time resolution of 10 minutes"
puts "</p>"
puts "<img style=\"width: 100%;\" src=\"peer_stats/connections.png\" alt=\"Connection states of connected Freenet peers on my seednode.\"/>"


puts "<p>"
puts "The following graph plots the number of nodes that have added a seed client (a node connected to a seednode with the aim of gaining new peers through announcement). Some nodes in the network will respond that they are willing to connect to the seed client (added), others explicitly reject the request (not wanted)"
puts "<img style=\"width: 100%;\" src=\"announcements/announcements.png\" alt=\"Announcement requests success/failure on my seednode.\"/>"
puts "</p>"

puts "<p>"
puts "The following graph plots how long it takes for a node to acquire at least 6 opennet peers through bootstrapping using seednodes. This graph only includes the bootstrapping times for the last 30 days."
puts "<img style=\"width: 100%;\" src=\"bootstrapping/bootstrapping_30_days.png\" alt=\"Bootstrapping performance during the last 30 days.\"/>"
puts "</p>"


puts "<p>"
puts "The following graph plots how long it takes for a node to acquire at least 6 opennet peers through bootstrapping using seednodes. This graph plots all available data."
puts "<img style=\"width: 100%;\" src=\"bootstrapping/bootstrapping.png\" alt=\"Bootstrapping performance.\"/>"
puts "</p>"


puts "<p>"
puts "The next graphs will plot the average fetch / insert performance or time for either a time period or a specific Freenet version. The sample size is disregarded which means that the average could be based on only a single observation! Please keep this in mind!"
puts "</p>"

puts "<img style=\"width: 100%;\" src=\"fetch_graph.png\" alt=\"Fetch ratios per version\"/>"
puts "<img style=\"width: 100%;\" src=\"insert_graph.png\" alt=\"Insert graph per version\"/>"
puts "<img style=\"width: 100%;\" src=\"fetch_time_versions.png\" alt=\"Fetch duration over versions\"/>"
puts "<img style=\"width: 100%;\" src=\"insert_version_graph_time.png\" alt=\"Insert duration over versions\"/>"
puts "<img style=\"width: 100%;\" src=\"fetch_dates_graph.png\" alt=\"Fetch ratios over time\"/>"
puts "<img style=\"width: 100%;\" src=\"fetch_time_dates.png\" alt=\"Fetch duration over time\"/>"
puts "<img style=\"width: 100%;\" src=\"insert_graph_time.png\" alt=\"Insert duration over time\"/>"

puts "<img style=\"width: 100%;\" src=\"sample_sizes_graph_1.png\" alt=\"Sample sizes over time\"/>"
puts "<img style=\"width: 100%;\" src=\"sample_sizes_graph_2.png\" alt=\"Sample sizes over time\"/>"
puts "<img style=\"width: 100%;\" src=\"sample_sizes_graph_3.png\" alt=\"Sample sizes over time\"/>"
puts "<img style=\"width: 100%;\" src=\"sample_sizes_graph_4.png\" alt=\"Sample sizes over time\"/>"
puts "<img style=\"width: 100%;\" src=\"sample_sizes_graph_5.png\" alt=\"Sample sizes over time\"/>"
puts "<img style=\"width: 100%;\" src=\"sample_sizes_graph_6.png\" alt=\"Sample sizes over time\"/>"
puts "<img style=\"width: 100%;\" src=\"sample_sizes_graph_7.png\" alt=\"Sample sizes over time\"/>"
puts "<img style=\"width: 100%;\" src=\"sample_sizes_graph_8.png\" alt=\"Sample sizes over time\"/>"



puts "<p>"
puts "The first table describes fetching results for 32 single blocks. A mean ratio of 0.5 means that 16 blocks were retrieved and 16 were not. We perform such a 32-single block fetching test every day. Each day we try to retrieve the 32 blocks inserted 2<sup>delta</sup>-1 days ago for delta = 1,2, ... 8. We repeat this process every day for as long as there isn't a new freenet version. All the fetch results which have been obtained with a specific version of freenet will be part of the same sample."
puts "</p>"

puts "<p>"
puts "After acquiring a number of samples we actually want to asses whether the fetch results obtained with freenet version A are similar or different compared to the next freenet version B. You can imagine that there is a chance that the results of a single test are actually lucky or unlucky. Properly analyzing the results from a number of different tests allows to us calculate how certain we are that a specific version is an improvement of another version. More specifically we calculate the significance of the sample (chance that the samples obtained from a specific version constitute a normal distribution). When the sample significance meets a minimal probability a T-test is performed to calculate whether we can decide if the samples obtained for version 1 are significantly different from the samples obtained with version 2. The results for these tests are displayed in the first table. Sample sizes smaller than #{MINIMUM_SAMPLE_SIZE} are disregarded." 
puts "</p>"


puts "<p>"
puts "The second table display the insert results for different versions. If the insertion performed by a specific version is better than this should mean that the results which have been inserted better will be easier to fetch later on. We thus look at future fetch results and assume (for these results) that the improved fetch requests are caused by the inserting version."
puts "</p>"


puts "<p>"
puts "Naturally these results are pretty distorted, because the network size isn't taken into account. Another issue is that we cannot clearly distinguish between fetch related improvements and insertion related improvements. They are co-dependent in freenet. Yet another issue is that results are limited due to the version churn of freenet and a long-standing bug in the simulation code which has been fixed recently. I hope to achieve new results soon."
puts "</p>"


puts "<table border=\"1\">"

puts "<tr><th>Fetch performance</th><th>Version 2</th><th>Version 1</th><th>Delta</th><th>p</th><th>Mean version 1</th><th>Mean version 2</th> <th>Sample size version 1</th> <th>Sample size version 2</th></tr>"



#check fetches
sorted_keys.each_index do |i|
    if (i > 0)
        version1 = sorted_keys[i-1];
        version2 = sorted_keys[i];

        versions[version1].keys.sort.each do |delta|            
            if (versions[version2].has_key?(delta) && versions[version1][delta].size > 0 && versions[version2][delta].size > 0)
                
                dist1 = versions[version1][delta].to_scale
                dist2 = versions[version2][delta].to_scale

                if (dist1.size > MINIMUM_SAMPLE_SIZE && dist2.size > MINIMUM_SAMPLE_SIZE && (dist1.mean > 0 && dist2.mean > 0))

                    result = Statsample::Test::T::TwoSamplesIndependent.new(dist1,dist2).probability_equal_variance
                    if (result < ALPHA) # && certainty(dist1) > 1-ALPHA && certainty(dist2) > 1-ALPHA) 
                        if (dist1.mean > dist2.mean)
                            puts tableRow(version1, version2, delta, result, dist1, dist2, "WORSE")
                        else
                            puts tableRow(version1, version2, delta, result, dist1, dist2, "BETTER")
                        end
                    end
                end        
            end
        end
    end
end

puts "</table>"

puts "<br /><br />"
puts "<table border=\"1\">"
puts "<tr><th>Insert performance</th><th>Version 2</th><th>Version 1</th><th>Delta</th><th>p</th><th>Mean version 1</th><th>Mean version 2</th> <th>Sample size version 1</th> <th>Sample size version 2</th></tr>"




#check insert fetch results
sorted_keys.each_index do |i|
    if (i > 0)
        version1 = sorted_keys[i-1];
        version2 = sorted_keys[i];

        dates_version1 = Set.new
        dates_version2 = Set.new
        
        #determine date ranges for the two versions
        lines.each do |line|
            split = line.split("!")
            date = Date.parse(split[0])
            version = split[1].to_i

            dates_version1.add(date) if (version == version1)
            dates_version2.add(date) if (version == version2)
        end
        
        (1..8).each do |delta|
            ratios_version1 = []
            ratios_version2 = []
            
            #for each date that a version was running determine the fetch ratio at that date+delta_days -> store
            dates_version1.each do |date|
                #determine future date for current delta
                insert_date = date
                retrieve_date = insert_date + ((2**delta)-1)

                if (date_line.has_key?(retrieve_date))
                    date_line[retrieve_date].each do |line|
	                    ratio = getFetchRatio(createAvailable(line), delta, line)
	                    ratios_version1.push(ratio) if (ratio != nil)
                	end
                end
            end

            #for each date that a version was running determine the fetch ratio at that date+delta_days -> store
            dates_version2.each do |date|
                #determine future date for current delta
                insert_date = date
                retrieve_date = insert_date + ((2**delta)-1)

                if (date_line.has_key?(retrieve_date))
                    date_line[retrieve_date].each do |line|
	                    ratio = getFetchRatio(createAvailable(line), delta, line)
	                    ratios_version2.push(ratio) if (ratio != nil)
					end
                end
            end

            dist1 = ratios_version1.to_scale
            dist2 = ratios_version2.to_scale

            #open a file to append write the means
	    	file   = File.open("means_insert_#{delta}.txt", "a")
            file.write("#{version2} #{dist2.mean}\n")
            file.close

            if (dist1.size > MINIMUM_SAMPLE_SIZE && dist2.size > MINIMUM_SAMPLE_SIZE && (dist1.mean > 0 || dist2.mean > 0))
                
                begin
                result = Statsample::Test::T::TwoSamplesIndependent.new(dist1,dist2).probability_equal_variance
                
                if (result < ALPHA) # && certainty(dist1) > 1-ALPHA && certainty(dist2) > 1-ALPHA) 
                    if (dist1.mean > dist2.mean)
                            puts tableRow(version1, version2, delta, result, dist1, dist2, "WORSE")
                    else
                            puts tableRow(version1, version2, delta, result, dist1, dist2, "BETTER")
                    end
                end
            
                rescue
                
                    #an error occured :(                
                end
            end        
        end
    end
end

#include graphs in page
puts "</table>"



puts "<br / ><br />"
puts "<table border=\"1\">"

puts "<tr><th>Fetch performance</th><th>Next timeframe</th><th>Previous timeframe</th><th>Delta</th><th>p</th><th>Mean previous timeframe</th><th>Mean next timeframe</th> <th>Sample size previous timeframe</th> <th>Sample size next timeframe</th></tr>"



time_delta = 30 #number of days in the interval
start_date = date_line.keys.sort.first
end_date = date_line.keys.sort.last

#create fetch samples for each delta for all the weeks in our date_lines
offset = 0
next_offset = 0;
while(start_date + offset <= end_date)
	
	next_offset += time_delta
	
	(1..8).each do |delta|
		
		ratios1 = []
		ratios2 = []
	
		#create dist1
        date_line.keys.each do |date|
             if (date >= start_date+offset && date < start_date+next_offset)
                date_line[date].each do |line|
                  ratio = getFetchRatio(createAvailable(line), delta, line)
                  ratios1.push(ratio) if (ratio != nil)
			 	end
             end
        end
		
		#create dist2
        date_line.keys.each do |date|
             if (date >= start_date+next_offset && date < start_date+next_offset+time_delta)
                date_line[date].each do |line|
                  ratio = getFetchRatio(createAvailable(line), delta, line)
                  ratios2.push(ratio) if (ratio != nil)
			 	end
             end
        end

	
        dist1 = ratios1.to_scale
        dist2 = ratios2.to_scale

        if (dist1.size > MINIMUM_SAMPLE_SIZE && dist2.size > MINIMUM_SAMPLE_SIZE && (dist1.mean > 0 || dist2.mean > 0))
            
            begin
            result = Statsample::Test::T::TwoSamplesIndependent.new(dist1,dist2).probability_equal_variance
            
            if (result < ALPHA) # && certainty(dist1) > 1.0-ALPHA && certainty(dist2) > 1.0-ALPHA) 
                if (dist1.mean > dist2.mean)
                        puts tableRow("#{start_date+offset} - #{start_date+next_offset}", "#{start_date+next_offset} - #{start_date+next_offset+time_delta}", delta, result, dist1, dist2, "WORSE")
                else
                        puts tableRow("#{start_date+offset} - #{start_date+next_offset}", "#{start_date+next_offset} - #{start_date+next_offset+time_delta}", delta, result, dist1, dist2, "BETTER")
                end
            end
        
            rescue
            
                #an error occured :(                
            end
        end        

	
	
	end
	
	offset = next_offset
end

puts "</table>"


#output the fetch means for all versions to a file
sorted_keys.each_index do |i|
	version = sorted_keys[i]
	versions[version].keys.sort.each do |delta|
		if (versions[version][delta].size > 0)
			dist = versions[version][delta].to_scale
			file   = File.open("means_fetch_#{delta}.txt", "a")
			file.write("#{version} #{dist.mean}\n")
			file.close

			file   = File.open("means_fetch_#{delta}_size.txt", "a")
			file.write("#{version} #{dist.size}\n")
			file.close
		end
	end
end

#output the average fetch ratio for each date
(1..8).each do |delta|

	date_line.keys.sort.each do |date|
		ratios = []
		date_line[date].each do |line|
			ratio = getFetchRatio(createAvailable(line), delta, line)
			ratios.push(ratio) if (ratio != nil)
		end
		
		#output the average ratio to a file
		mean = ratios.inject{ |sum, el| sum + el }.to_f / ratios.size
		
		if (mean > 0)
	        #open a file to append write the means
	    	file   = File.open("means_date_fetch_#{delta}.txt", "a")
	        file.write("#{date} #{mean}\n")
	        file.close
		end
	end
end

#output the average fetch time for each date
(1..8).each do |delta|

	date_line.keys.sort.each do |date|
		times = []
		date_line[date].each do |line|
			time = getAverageTime(createAvailable(line), delta, line)
			times.push(time) if (time != nil)
		end
		
		#output the average ratio to a file
		mean = times.inject{ |sum, el| sum + el }.to_f / times.size
		
		if (mean > 0)
	        #open a file to append write the means
	    	file   = File.open("means_date_fetch_time_#{delta}.txt", "a")
	        file.write("#{date} #{mean.to_i}\n")
	        file.close
		end
	end
end


#output the average fetch time for each version
(1..8).each do |delta|

	version_line.keys.sort.each do |version|
		times = []
		version_line[version].each do |line|
			time = getAverageTime(createAvailable(line), delta, line)
			times.push(time) if (time != nil)
		end
		
		#output the average ratio to a file
		mean = times.inject{ |sum, el| sum + el }.to_f / times.size
		
		if (mean > 0)
	        #open a file to append write the means
	    	file   = File.open("means_version_fetch_time_#{delta}.txt", "a")
	        file.write("#{version} #{mean.to_i}\n")
	        file.close
		end
	end
end


#output the average insert time for each date
date_line.keys.sort.each do |date|
	ratios = []
	date_line[date].each do |line|
		ratio = getAverageInsertTime(line)
		ratios.push(ratio) if (ratio != nil)
	end
	
	#output the average ratio to a file
	mean = ratios.inject{ |sum, el| sum + el }.to_f / ratios.size
	
	if (mean > 1)
        #open a file to append write the means
    	file   = File.open("means_date_insert_time.txt", "a")
        file.write("#{date} #{mean.to_i}\n")
        file.close
	end
end


#output the average insert time for each version
version_line.keys.sort.each do |version|
	ratios = []
	version_line[version].each do |line|
		ratio = getAverageInsertTime(line)
		ratios.push(ratio) if (ratio != nil)
	end
	
	#output the average ratio to a file
	mean = ratios.inject{ |sum, el| sum + el }.to_f / ratios.size
	
	if (mean > 1)
        #open a file to append write the means
    	file   = File.open("means_version_insert_time.txt", "a")
        file.write("#{version} #{mean.to_i}\n")
        file.close
	end
end


puts '<a href="means_date_fetch_1.txt">means_date_fetch_1.txt</a>'

puts "All the data used for the creation of this freesite is embedded into it. Use the KeyExplorer-plugin or whatever to retrieve it.<br />"
puts "Author: digger3 - USK@zALLY9pbzMNicVn280HYqS2UkK0ZfX5LiTcln-cLrMU,GoLpCcShPzp3lbQSVClSzY7CH9c9HTw0qRLifBYqywY,AQACAAE/WebOfTrust/1895 . I tend to hang around on Sone and freenode IRC"
puts "</body></html>"
