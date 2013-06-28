#group multiple freenet versions together based on the mandatory version

#map a specific Freenet buildNumber to a mandatory build. This will group together multiple Freenet builds into those with similar network behaviour
versions = Hash.new

last_group = 0

FREENET_PATH = "/home/tmarkus/checkouts/fred/src/freenet/node"
`cd #{FREENET_PATH} && git whatchanged -p Version.java | grep -E "\\+.*(buildNumber|newLastGoodBuild)" | tac`.each_line do |line|
	if line.include?("newLastGoodBuild")
		if (line =~ /\d+/)
			last_group = /\d+/.match(line)[0].to_i
			versions[last_group] = last_group
		end
	elsif line.include?("buildNumber")
		if (line =~ /\d+/)
			version = /\d+/.match(line)[0].to_i
			versions[version] = last_group
		end
	end
end

puts "mandatory\tversion"
versions.each_key do |version|
	puts "#{versions[version]}\t#{version}"
end
