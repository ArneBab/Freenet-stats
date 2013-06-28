require 'open-uri'
require 'date'
require 'lzma'

#process files in some datarange

DAY = 24*60*60
BASE = "http://amphibian.dyndns.org/freenet/tests"
types = ['boot-pull', 'bootstrap', 'long-term-manysingleblocks', 'long-term-mhk', 'long-term-push-pull', 'push-pull', 'seednodes']

now = Time.now - (24*60*60) # go back a day, because we want to be sure that all tests have been run for that day
last = nil

#get the latest timestamp from the data file and start from that
begin
	last = Time.parse(`tail -n 1 data.txt`.split("\t")[0]) + (24*60*60)
rescue #file does notn exist, so start fetching from 4 years onwards
	last = Time.now - (4 * 365 * 24*60*60)
end


data = File.open("data.txt", "a")


current = last
while current < now
	total = 0
	count = 0

	types.each do |type|
		uri = "#{BASE}/#{type}/" + current.strftime("%Y/%m/%d")

		begin
			open(uri).each_line do |line|
				result = line.scan(/log(\.failed)?\.lzma">(.*\.log(\.failed)?\.lzma)<\/a>/)
				if (result.first && result.first.size == 3)
					filename = uri + "/" + result.first[1]
			
					puts filename

					#open file
					time = nil 
					LZMA.decompress(open(filename, "rb").read).split("\n").each do |line|
						reg_exp = /(\d+) : seeds: (\d+), connected: (\d+) opennet: peers: (\d+), connected: (\d+)/
						if (line =~  reg_exp)
							time, seeds, seeds_connected, opennet_peers, opennet_peers_connected = line.scan(reg_exp)[0]
						end
					end

					total += time.to_i
					count += 1		
				end
			end

		rescue => e # usually a 404 is triggered here if the test wasn't run on that day
		 puts e.message
		 #do nothing
		end
	end
	
	if (total > 1)
		output_line = current.strftime("%Y-%m-%d") + "\t" + (total.to_f / count).to_s + "\n"
		data.write(output_line)
	end
	
	current += DAY
end

data.close

#get the last 30 days worth of data
`tail -n 30 data.txt > 30_days.txt`
