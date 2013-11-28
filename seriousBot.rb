#!/usr/local/bin/ruby

# For this to work you need at least Ruby 1.9.x, turntabler, sqlite 3.x, nokogiri, digest

require 'turntabler'
require 'monitor'
require 'eventmachine'

#require 'rubygems'
require 'nokogiri'    
require 'open-uri'

require 'digest/md5'

require 'ansi/code'
require 'pp'

#Constants
EMAIL 		= ''       			   # 'xxxxx@xxxxx.com'
PASSWORD 	= ''  				   # 'xxxxx'
ROOM 		= ''       # Pur your roomid here
USER_ID 	= ''	   # Userid for bot
AUTH 		= ''       # Auth id for bot
MAGIC_8_BALL	= [ 	
			"It is certain", 
			"It is decidedly so", 
			"Without a doubt", 
			'Yes - definitely', 
			"You may rely on it", 
			"As I see it, yes", 
			"Most likely", 
			"Outlook good", 
			"Yes", 
			"Signs point to yes", 
			"Reply hazy, try again", 
			"Ask again later", 
			"Better not tell you now", 
			"Cannot predict now", 
			"Concentrate and ask again", 
			"Don't count on it", 
			"My reply is no", 
			"My sources say no", 
			"Outlook not so good", 
			"Very doubtful" 
		]

#Global Variables

awayMode 	= false

snags 		= 0
queueMode 	= 0 # 0 = None, 1 = Normal Queue, 2 = Slide Queue
autoBop 	= 1

autoDj		= 3	# If there is less then x djs then hopup
autoDjEnabled	= true
voteText	= 'Smoke!'
versionMajor	= 0
versionMinor	= "8"
version		= "seriousBot.rb :smiling_imp: v#{versionMajor}.#{versionMinor} Beta by Fuzzy"
welcomeMessage	= "Welcome to Express Yourself. Please read the room rules before you play :)" 
themeMode	= 0
theme		= ''

tableDjs	= [] # People djing
tableQueue  	= [] # table queue
tableAway	= [] # Reloaders
level_3_acl 	= [ 	'4ea8d05fa3f751271d024366'    	] #Owners
level_2_acl 	= [ 	'50030d32eb35c12c660001e4', 
			'50b9c49faaa5cd76060cdb84', 
			'4e70c50c4fe7d045c60fc704', 
			'4ffbb868eb35c125c00002d5',
			'4e6fda31a3f75112c7085798',
			'4e256e75a3f751093501b688',
			'4fbe5393aaa5cd2626000003',
			'50f4ccb6aaa5cd62981fa36a',
			'4e2494324fe7d0451d02624f',
		] + level_3_acl #mods
level_1_acl 	= [
		] + level_2_acl #Cool People
blacklist 	= ['4ea9d7504fe7d07b3503fa3c', '5126a0b6aaa5cd286637e263', '4e2494324fe7d0451d02624f', '50e4ff16aaa5cd3386993f2a']
#		60 seconds in a minute
#		1800 seconds in 30 minutes
#		3600 seconds in an hour
#		86400 seconds in a day
adsList 	= [ 
            		{ 'delay' => 1800, 'text' => version },
                        { 'delay' => 1200, 'text' => "Check out http://tinyurl.com/seriousBotCommandList for a list of commands." },
                        { 'delay' => 10800, 'text' => "Welcome Home!" }

		]
extraCommands	= [
			{ 'trigger' => '/v', 'say' => version },
			{ 'trigger' => '/Cmds', 'say' => "Check out http://tinyurl.com/seriousBotCommandList for a list of commands." },
			{ 'trigger' => '/Commands', 'say' => 'Please type /Cmds for a list of commands.' },
			{ 'trigger' => '/fail',   'vote' => 'down', 'say' => 'This song is a failure' }
		]


# File lists
#blacklist = Marshal.load File.read('blacklist') if File.exists?('blacklist') 
#db = SQLite3::Database.open "stats.db"

# Main start


Turntabler.interactive

client = nil

Turntabler.run do 
	client = Turntabler::Client.new(EMAIL, PASSWORD, :room => ROOM, :user_id => USER_ID, :auth => AUTH, :reconnect => true, :reconnect_wait => 60)
	client.room.say version
	spawnDate = `date`.chomp

# Ad Spooler
	adsList.each do |ad|
#			client.room.say "#{ad['delay']} #{ad['text']}"	
		EventMachine::PeriodicTimer.new(5) do
			Turntabler.run { 
				# puts "tableDjs:"
				tableDjs.each do |dj|
					puts dj.name
					end 
				}
			end
		EventMachine::PeriodicTimer.new(ad['delay']) do
			Turntabler.run { client.room.say ad['text'] }
			end
		end		
# Blacklist Spooler
	EventMachine::PeriodicTimer.new(10) do
		client.room.listeners.each do |user|
       			if blacklist.include?(user.id)
                       		user.boot('You are on the blacklist.')
                       	elsif user.name =~ /ttstat/
                       		user.boot("Go home ttstats, you're drunk.")
                       	else
                       		#db.execute("INSERT OR IGNORE INTO Users(userid, name, lastSeen, songsPlayed, songsAwesomed, songsLamed, songsSnagged, songsShared) VALUES ('#{user.id}', '#{user.name.gsub(/'/,"")}','',0,0,0,0,0)")
                       		#db.execute("UPDATE Users SET lastSeen = '" + `date`.chomp + "', name = '#{user.name.gsub(/'/,"")}' WHERE userid='#{user.id}'")
                       		end
                	end
		end

# On join make sure we get everyone that was already here in to the database
	listeners = client.room.listeners                        # => #<Set: {#<Turntabler::User:0x95631b0 @id="309ba75b6385b83e110923bd" ..., ...}>
	listeners.each do |user|
       		#db.execute("INSERT OR IGNORE INTO Users(userid, name, lastSeen, songsPlayed, songsAwesomed, songsLamed, songsSnagged, songsShared) VALUES ('#{user.id}', '#{user.name.gsub(/'/,"")}','',0,0,0,0,0)")
		#db.execute("UPDATE Users SET lastSeen = '" + `date`.chomp + "', name = '#{user.name.gsub(/'/,"")}' WHERE userid='#{user.id}'")
		end

	client.room.say("I'm materializing!")

	client.room.become_dj	if client.room.djs.length < autoDj	
# Events
	client.on :user_entered do |user|
		if blacklist.include?(user.id) 
			user.boot('You are on the blacklist.')
		elsif user.name =~ /ttstat/
			user.boot("Go home ttstats, you're drunk.")
		else 
		#	user.say("#{welcomeMessage}")
		        #db.execute("INSERT OR IGNORE INTO Users(userid, name, lastSeen, songsPlayed, songsAwesomed, songsLamed, songsSnagged, songsShared) VALUES ('#{user.id}', '#{user.name.gsub(/'/,"")}','',0,0,0,0,0)")
			#db.execute("UPDATE Users SET lastSeen = '" + `date`.chomp + "', name = '#{user.name.gsub(/'/,"")}' WHERE userid='#{user.id}'")
			end
		end

	client.on :user_left do |user|
		puts "#{user.name} left the room"
		tableQueue.delete user.name  if tableQueue.include? user.name
		end

	client.on :song_snagged do |snag|
		snags = snags + 1
                digest = Digest::MD5.hexdigest(snag.song.title + snag.song.artist)
                #db.execute("UPDATE Songs SET timesSnagged = timesSnagged + 1 WHERE songid='#{digest}'")
		#db.execute("UPDATE Users SET songsSnagged = songsSnagged + 1 WHERE userid='#{snag.user.id}'")
		#db.execute("UPDATE Users SET songsShared = songsShared + 1 WHERE userid='#{client.room.current_dj.id}'")
		end
			
	client.on :song_started do |song|
		#client.room.say("Current dj: #{client.room.current_dj.name}. My name is #{client.user.name}")
		if autoBop == 1 && client.room.current_dj != client.user
     			EventMachine::Timer.new(20+rand(40)) do
       				Turntabler.run { 
                                       	client.room.current_song.vote if client.room.current_dj != client.user 
                                       	client.room.say(voteText);
					}		
       				end
			end
		end

	client.on :song_ended do |song|
		puts "Song Ended"
		#db.execute("UPDATE Users SET songsPlayed = songsPlayed + 1 WHERE userid='#{song.played_by.id}'")
		puts "Song played by dj updated"
		song.votes.each do |vote|
				# client.room.say "#{vote.user.name} voted '#{vote.direction}'" 
				# pp vote
			#db.execute("UPDATE Users SET songsAwesomed = songsAwesomed + 1 WHERE userid='#{vote.user.id}'") if vote.direction == :up
                	#db.execute("UPDATE Users SET songsLamed = songsLamed + 1 WHERE userid='#{vote.user.id}'") if vote.direction == :down
				# client.room.say("up") if vote.direction == :up
				# client.room.say("down") if vote.direction == :down
			end
		digest = Digest::MD5.hexdigest(song.title + song.artist)
			#client.room.say("Digest: #{digest}")	
		stm = db.prepare "SELECT * FROM Songs WHERE songid='#{digest}' LIMIT 1"
		rs = stm.execute
		myrow = rs.next
		if myrow != nil
			songid = myrow.shift
			myrow.shift
			myrow.shift
    			timesPlayed = myrow.shift + 1
    			timesAwesomed = myrow.shift + song.up_votes_count
    			timesLamed = myrow.shift + song.down_votes_count
    			timesSnagged = myrow.shift + snags
			#db.execute "UPDATE Songs SET timesPlayed = #{timesPlayed}, timesAwesomed = #{timesAwesomed}, timesLamed = #{timesLamed}, timesSnagged = #{timesSnagged} WHERE songid='#{songid}'"
		else
			songid = digest
			title = song.title
			artist = song.artist
			timesPlayed = 1
			timesAwesomed = song.up_votes_count
			timesLamed = song.down_votes_count
			timesSnagged = snags
				#     db.execute "INSERT INTO Friends(Name) VALUES ('Robert')"
			#db.execute "INSERT INTO Songs(songid, title, artist, timesPlayed, timesAwesomed, timesLamed, timesSnagged) VALUES ('#{songid}', '#{title.gsub(/'/,"")}', '#{artist.gsub(/'/,"")}', #{timesPlayed}, #{timesAwesomed}, #{timesLamed}, #{timesSnagged})"
			end
		snags=0
		end
		
	client.on :user_spoke do |message|
#	Extra Commands
		extraCommands.each do |command|
			if message.content =~ /#{command['trigger']}/
				client.room.say(command['say']) if !(defined?(command['say'])).nil?
				client.room.current_song.vote if !(defined?(command['vote'])).nil? && command['vote'] == 'up'
				client.room.current_song.vote(:down) if !(defined?(command['vote'])).nil? && command['vote'] == 'down'
				end
			end			
#	User functionsa
		if message.content =~ /^\/adj$/
			if autoDjEnabled
				autoDjEnabled = false
				client.room.say("AutoDj Disabled")
			else
				autoDjEnabled = true
				client.room.say("AutoDj Enabled")
        			client.room.become_dj   if client.room.djs.length < autoDj && autoDjEnabled
				end
                       	end
		if message.content =~ /^\/ls .+$/
                               #zipCode = message.content.scan(/\d{5}/).shift
			username = message.content.sub(/^\/ls /,'')
                        #stm = db.prepare "SELECT lastSeen FROM Users WHERE name='#{username}' LIMIT 1"
                        #rs = stm.execute
                        #myrow = rs.next
                        if myrow === nil
				client.room.say("Sorry, but we can't find that user in our records")
			else
				client.room.say("#{username} was last seen: #{myrow.join}")
				end
			end

		if message.content =~ /^\/stats .+$/
                                #zipCode = message.content.scan(/\d{5}/).shift
			username = message.content.sub(/^\/stats /,'')
                        #stm = db.prepare "SELECT * FROM Users WHERE name='#{username}' LIMIT 1"
				#client.room.say("You are looking for '#{username}'")
                        #rs = stm.execute
                        #myrow = rs.next
                        if myrow === nil
                        	client.room.say("Sorry, but we can't find that user in our records")
                        else
                        	client.room.say("#{username} has played #{myrow[3]} songs, has awesomed  #{myrow[4]} songs, has lamed #{myrow[5]} songs, has snagged #{myrow[6]} songs, and has been snagged from #{myrow[7]} times")
                                end
                        end

                        if message.content =~ /^\/topArtists/
                        #stm = db.prepare "SELECT artist, sum(timesPlayed) AS totalTimesPlayed FROM Songs GROUP BY artist ORDER BY totalTimesPlayed DESC LIMIT 5"
                        #rs = stm.execute
                        client.room.say("Top 5 Most Played Artists:")
                        while (row = rs.next) do
                                #puts row.join "\s"
                                client.room.say("\"#{row[0]}\" with #{row[1]}")
                                end
                                end			

                        if message.content =~ /^\/mostPlayed/
                        #stm = db.prepare "SELECT * FROM Songs ORDER BY timesPlayed DESC LIMIT 5"
                        #rs = stm.execute
			client.room.say("Top 5 Most Played Songs:")
 			while (row = rs.next) do
        			#puts row.join "\s"
    				client.room.say("\"#{row[1]}\" By #{row[2]} With #{row[3]}")
				end
                                end

                        if message.content =~ /^\/mostAwesomed/
                        #stm = db.prepare "SELECT * FROM Songs ORDER BY timesAwesomed DESC LIMIT 5"
                        #rs = stm.execute
                        client.room.say("Top 5 Most Awesomed Songs:")
                        while (row = rs.next) do
                                #puts row.join "\s"
                                client.room.say("\"#{row[1]}\" By #{row[2]} With #{row[4]}")
                                end
                                end

                        if message.content =~ /^\/mostLamed/
                        #stm = db.prepare "SELECT * FROM Songs ORDER BY timesLamed DESC LIMIT 5"
                        #rs = stm.execute
                        client.room.say("Top 5 Most Lamed Songs:")
                        while (row = rs.next) do
                                #puts row.join "\s"
                                client.room.say("\"#{row[1]}\" By #{row[2]} With #{row[5]}")
                                end 
                                end

                        if message.content =~ /^\/mostSnagged/
                        #stm = db.prepare "SELECT * FROM Songs ORDER BY timesSnagged DESC LIMIT 5"
                        #rs = stm.execute
                        client.room.say("Top 5 Most Snagged Songs:")
                        while (row = rs.next) do
                                #puts row.join "\s"
                                client.room.say("\"#{row[1]}\" By #{row[2]} With #{row[6]}")
                                end
                                end
			
			if message.content =~ /^\/Aries$/
				client.room.say "Aries: " + Nokogiri::HTML(open("http://my.horoscope.com/astrology/free-daily-horoscope-aries.html")).css("div.fontdef1").shift.text
				end			

			if message.content =~ /^\/Taurus$/
				client.room.say "Taurus: " + Nokogiri::HTML(open("http://my.horoscope.com/astrology/free-daily-horoscope-taurus.html")).css("div.fontdef1").shift.text
				end	

			if message.content =~ /^\/Gemini$/
				client.room.say "Gemini: " + Nokogiri::HTML(open("http://my.horoscope.com/astrology/free-daily-horoscope-gemini.html")).css("div.fontdef1").shift.text
				end	
			
			if message.content =~ /^\/Cancer$/
				client.room.say "Cancer: " + Nokogiri::HTML(open("http://my.horoscope.com/astrology/free-daily-horoscope-cancer.html")).css("div.fontdef1").shift.text
				end	

			if message.content =~ /^\/Leo$/
				client.room.say "Leo: " + Nokogiri::HTML(open("http://my.horoscope.com/astrology/free-daily-horoscope-leo.html")).css("div.fontdef1").shift.text
				end	

			if message.content =~ /^\/Virgo$/
				client.room.say "Virgo: " + Nokogiri::HTML(open("http://my.horoscope.com/astrology/free-daily-horoscope-virgo.html")).css("div.fontdef1").shift.text
				end				
			
			if message.content =~ /^\/Libra$/
				client.room.say "Libra: " + Nokogiri::HTML(open("http://my.horoscope.com/astrology/free-daily-horoscope-libra.html")).css("div.fontdef1").shift.text
				end	
			
			if message.content =~ /^\/Scorpio$/
				client.room.say "Scorpio: " + Nokogiri::HTML(open("http://my.horoscope.com/astrology/free-daily-horoscope-scorpio.html")).css("div.fontdef1").shift.text
				end	
			
			if message.content =~ /^\/Sagittarius$/
				client.room.say "Sagittarius: " + Nokogiri::HTML(open("http://my.horoscope.com/astrology/free-daily-horoscope-sagittarius.html")).css("div.fontdef1").shift.text
				end	

			if message.content =~ /^\/Capricorn$/
				client.room.say "Capricorn: " + Nokogiri::HTML(open("http://my.horoscope.com/astrology/free-daily-horoscope-capricorn.html")).css("div.fontdef1").shift.text
				end	

			if message.content =~ /^\/Aquarius$/
				client.room.say "Aquarius: " + Nokogiri::HTML(open("http://my.horoscope.com/astrology/free-daily-horoscope-aquarius.html")).css("div.fontdef1").shift.text
				end	

			if message.content =~ /^\/Pisces$/
				client.room.say "Pisces: " + Nokogiri::HTML(open("http://my.horoscope.com/astrology/free-daily-horoscope-pisces.html")).css("div.fontdef1").shift.text
				end	

			if message.content =~ /^\/uptime$/
				client.room.say "seriousBot was started at #{spawnDate}"
				end
			if message.content =~ /^\/8ball/
				client.room.say("The Magic 8-Ball Says \"" + MAGIC_8_BALL[rand(0..19)] + '"' )
				end

                        if message.content =~ /^\/roll d20/
                                client.room.say("#{message.sender.name} rolled a " + rand(1..20).to_s )
                                end

                        if message.content =~ /^\/roll$/
                                client.room.say("#{message.sender.name} rolled a " + rand(1..6).to_s )
                                end

                        if message.content =~ /^\/w \d{5}$/
                               	zipCode = message.content.scan(/\d{5}/).shift
				page = Nokogiri::HTML(open("http://www.weather.com/weather/today/#{zipCode}"))
				temp = page.css("div.wx-location-title")
				te = temp.pop
				location = te.text
				location = te.text.gsub(/Save Location/, "")
				location = location.gsub(/\s{2,}/, "")
				location = location.gsub(/Weather$/, "")
				temp = page.css("p.wx-temp")
				te = temp.pop
				tempature = te.text
				tempature = tempature.gsub(/Low/,"")	
				tempature = tempature.gsub(/High/,"")	

				temp = page.css("p.wx-phrase")
				te = temp.pop
				te = te.text	
				# puts "Weather Test"	
				client.room.say("The weather for #{location} is #{tempature}. The forecast is #{te}") 
				#location = temp[0].text
				#system = "*F"
				#tempature = ""
				#client.room.say("Weather for #{location} is #{tempature}#{system}") 
				end
	
			if message.content =~ /bop$/
				client.room.current_song.vote   # => true
				client.room.say(voteText);
				end
			
			if message.content =~ /^\/hugs/
				client.room.say("Awww thank you #{message.sender.name}")
				client.room.say("/me hugs #{message.sender.name}") 
				end

			if message.content =~ /^\/qm$/
				client.room.say("Queue is currently off. Fastest finger.") if queueMode == 0
				client.room.say("Queue is on. Type /q to join.") if queueMode == 1
				client.room.say("Slide is on. Type /q to join.") if queueMode == 2 
				end
#	Queue functions
			if message.content =~ /^\/ql$/
				if queueMode > 0	
				if !tableQueue.empty?
					tableQueue.each do |dj|
						client.room.say("In Queue: #{dj.name}")
						end
				else
					client.room.say("There is nobody in queue right now")
					end
				else
					client.room.say("Queue is currently off. Fastest finger.")
					end
				end

			if message.content =~ /^\/q$/
				if queueMode > 0
					if tableDjs.include? message.sender
						client.room.say("#{message.sender.name} quit messing with me. You are already on the decks!")
					elsif tableQueue.include? message.sender
						client.room.say("#{message.sender.name} quit messing with me. You are already in queue!")
					else
						client.room.say("Current amount of djs: #{client.room.djs.length}")
						if !awayMode && client.room.djs.length < 5
			
				tableDjs.push message.sender
							client.room.say("#{message.sender.name} Come on up. It's your turn")
							currentTestDj = message.sender
							awayCycle1 = EventMachine::Timer.new(30) do
							Turntabler.run {
								if client.room.djs.include? currentTestDj 
									awayCycle1.cancel
								else
									client.room.say(" I'm sorry #{currentTestDj.name}, but you took too long")
									tableDjs.delete currentTestDj
									if tableQueue.empty?
										awayCycle1.cancel
									else
										currentTestDj = tableQueue.shift
										client.room.say("#{currentTestDj.name} Come on up. It's your turn")
									end
								end
								
							}
							end	
						else
							tableQueue.push message.sender
							client.room.say("Alright #{message.sender.name} you are in the queue.  Type /qr to remove yourself from the queue.")
							
							end
						end
				else
                                	client.room.say("Queue is currently off. Fastest finger.")
					end
				end
				

			if message.content =~ /^\/qr/
				tableQueue.delete message.sender if tableQueue.include? message.sender
				if tableQueue.include? message.sender
				client.room.say("Alright #{message.sender.name} you have been removed from the queue.") 
				else
				client.room.say("Sorry #{message.sender.name}, but we didn't have you in the queue.")
				end
				end
#	Theme functions	
			if message.content =~ /^\/t$/
				client.room.say("The theme currently set is \"#{theme}\"") if themeMode == 1
				client.room.say("No theme is currently set.") if themeMode == 0	
				end
#	Admin functionsa
			if level_1_acl.include?(message.sender.id) && message.content =~ /^\/t\s+(.+)/ 
				theme = message.content.gsub(/^\/t /,"")
				themeMode = 1	
				client.room.say("The theme currently set is \"#{theme}\"")	
				end
			
			if level_1_acl.include?(message.sender.id) && message.content =~ /^\/to$/
				client.room.say("No theme is currently set.") 	
				theme = ''
				themeMode = 0
				end

    			if level_1_acl.include?(message.sender.id) && message.content =~ /^\/skip$/
            			client.room.current_song.skip
	    			client.room.say("Skipping")
    				end

    			if level_1_acl.include?(message.sender.id) && message.content =~ /^\/ab on$/
        			client.room.say("Autobop on")
				autoBop = 1
                                client.room.current_song.vote   # => true
    				end

			if level_1_acl.include?(message.sender.id) && message.content =~ /^\/ab$/
        			client.room.say("Autobop on") if autoBop == 1
        			client.room.say("Autobop off") if autoBop == 0
    				end

			if level_1_acl.include?(message.sender.id) && message.content =~ /^\/ab off$/
				client.room.say("Autobop off")
				autoBop = 0
    				end
			
			if level_1_acl.include?(message.sender.id) && message.content =~ /^\/userids$/
				client.room.listeners.each do |listener|
					message.sender.say("#{listener.name}")
                			message.sender.say("#{listener.id}")
					end
				end
			
			if level_1_acl.include?(message.sender.id) && message.content =~ /^\/qm /
				if message.content.include? "0" 
					client.room.say("Turing Queue Off")
					queueMode = 0
					tableQueue = []
					tableDjs = []
				elsif message.content.include? "1" 
					client.room.say("Queue is on. Type /q to join.")
					queueMode = 1
					autoDj = 0
					tableDjs.replace(client.room.djs.to_a)
					tableDjs.each do |dj|
						client.room.say "#{dj.name} is on the decks"
						end
				elsif message.content.include? "2"
					client.room.say("Slide is on. Type /q to join.")
					queueMode = 2
					autoDj = 0 
					tableDjs = client.room.djs
					tableDjs.each do |dj|
						client.room.say "#{dj.name} is on the decks"
						end
					end 
				end
			
			if level_3_acl.include?(message.sender.id) && message.content =~ /^\/quit/
				client.room.say("Alright Peace")
				serialized_array = Marshal.dump(blacklist)
				File.open('blacklist', 'w') {|f| f.write(serialized_array) }
				exit
				end

			if level_2_acl.include?(message.sender.id) && message.content =~ /^\/restart/
				client.room.say("I'm melting!")
				serialized_array = Marshal.dump(blacklist)
				File.open('blacklist', 'w') {|f| f.write(serialized_array) }
				exec $0
				exit
				end

			if level_1_acl.include?(message.sender.id) && message.content =~ /^\/djs$/
#    client.room.djs.each do |dj|
#      client.room.say("DJ Playing: #{dj.name}")
#    end
				end

    			if level_1_acl.include?(message.sender.id) && message.content =~ /^\/snag$/
        			client.room.current_song.add( :index => (client.user.playlist.songs).count )
				snags+=1
        			client.room.say("Snagged Song: "+(client.user.playlist.songs).count.to_s)
        			end
#	Hop functions	
			if level_1_acl.include?(message.sender.id) && message.content =~ /^\/hopup$/
				client.room.become_dj
				client.room.say("Stepping Up")
				end

			if level_1_acl.include?(message.sender.id) && message.content =~ /^\/hopdown$/
				client.user.remove_as_dj
				client.room.say("Stepping Down")
				end
#	Blacklist functions
			if level_1_acl.include?(message.sender.id) && message.content =~ /^\/bl$/
                		message.sender.say("Blacklist") 
				blacklist.each do |bl| 
					message.sender.say("#{bl}")
                			end
                                client.room.listeners.each do |listener|
                                        listener.boot("Blacklisted") if blacklist.include? listener.id
                                        end
				end

        		if level_1_acl.include?(message.sender.id) && message.content =~ /^\/bl \d+$/
                		userid = message.content.scan(/\d+/)
				if blacklist.include?(userid)
					blacklist.delete userid	
					message.sender.say("#{userid} Removed From Blacklist")
				else
               				blacklist.push userid
					message.sender.say("#{userid} Added To Blacklist")
					end 
				client.room.listeners.each do |listener|
                                        listener.boot("Blacklisted") if blacklist.include? listener.id
                                        end
                                end
			if message.content =~ /^\/tabledjs$/
				tableDjs.each do |dj|
                		puts("User #{dj.name} is part of tableDjs")
                		end
			end
        	end

client.on :dj_added do |user|
	 # client.user.remove_as_dj if client.room.djs.length > autoDj && autoDjEnabled
	if queueMode > 0
		client.room.say("tableDjs include user: #{tableDjs.include? user}")
		tableDjs.each do |dj|
			puts dj.name
			end
		if tableDjs.include? user
			client.room.say("Welcome back #{user.name}")
		elsif client.room.djs.length > 4  
			client.room.say("Sorry #{user.name}, but we have a queue going on right now.  Please type /q to join.")
			user.remove_as_dj
		else
			client.room.say("Welcome #{user.name}")
			tableDjs.push(user)
			end
		end	
	end


client.on :song_voted do |song|
	person = song.votes.pop
	#client.room.say(":song_voted triggered vote counted #{person.user.name} #{person.direction}")
	client.room.say("#{person.user.name} voted up") if person.direction == :up
	end



client.on :dj_removed do |user|
        client.room.become_dj if client.room.djs.length < autoDj && autoDjEnabled 
	if queueMode > 0
	if tableDjs.include? user
		tableAway.push([user, 0])
		client.room.say("#{user.name} you have 30 seconds to return to your seat")
                if !awayMode
		awayMode = true
		awayTimer = EventMachine::PeriodicTimer.new(2) do
		Turntabler.run { 
				# Is the dj back yet?
				tmpDjs = []
				tableAway.each do |dj|
					dj[1] += 1
					if client.room.djs.include? dj[0]
						#client.room.say("Welcome Back #{dj[0].name}")
					elsif dj[1] > 14
						client.room.say("#{dj[0].name} Took too long")
						tableDjs.delete(dj[0])
					else
						tmpDjs.push(dj)
						end
					end
				tableAway = tmpDjs
				if tableAway.empty?
					if client.room.djs.length < 5 && !tableQueue.empty?
						client.room.say("#{tableQueue[0].name} You're Next. Come on up")
						tableDjs.push(tableQueue.shift)
						end
						
					awayMode = false
					
					awayTimer.cancel #Turn away off 
					end
				
			}
			end
		end
		end
		end
	end

end
