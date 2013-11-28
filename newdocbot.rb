#! /usr/bin/env ruby
#
#
#
#
# Doc Funk "v2.0" 
# Beta playground A
# 
#
#
#
#
#
##
require 'turntabler'
require 'monitor'
require 'eventmachine'

require 'sqlite3'
require 'pp'
require 'json'
require 'digest/md5'
require 'nokogiri'
require 'open-uri'


#Constants
#
#ROOM         		= '4f105a84590ca243bc001ae5'	# Boozeys Back Room
#ROOM            	= '50f5b843aaa5cd16f3d8499a'	# Express Yourself
ROOM			= '4f7f9b99aaa5cd25340001e9'	# Ya Dig?
USER_ID         	= ''	# User ID
AUTH            	= ''	# Auth ID

#Variables
bopped				= false
$tableDjs			= []
$tableQueue			= []
$moderators			= []
autoDjMagicNumber 		= 2
autoDjEnabled			= false
version         		= "docBot.rb By Fuzzy"
theme				= ''
themeEnabled			= ''
db 				= SQLite3::Database.open("stats.db")
snags				= 0
slide				= false
queue				= false
$awayPeople			= []
#Globals
$responses = {
				"bop" 			=> JSON.parse(`cat bop.json`),
				"magic8ball"	 	=> JSON.parse(`cat 8-ball.json`),
				}

$ttclient = nil						# Turntbale main thread

def boot_ttstats
         $ttclient.room.listeners.each do |user|
         user.boot("Go home ttstats, you're drunk.") if user.name =~ /ttstat/
         end
end

def user_away user
		if !($awayPeople.include? user) && ($tableDjs.include? user) && $tableQueue.count > 0 
		$awayPeople.push(user)
		$ttclient.room.say("#{user.name} you have 30 seconds to return to your seat")
		EventMachine::PeriodicTimer.new(30) do
			Turntabler.run {
				if ($tableDjs.include? user) && !($ttclient.room.djs.include? user)
					# kill and call the next one in the queue
					$ttclient.room.say("#{user.name} took too long")
					$tableDjs.delete user
			 	if $tableQueue.count > 0
					$tableDjs.push($tableQueue.shift)
					$ttclient.room.say("Come on up #{$tableDjs.last.name}") 			
					end
				end
				$tableQueue.delete user if $tableQueue.include? user && !($ttclient.room.listeners.include? user)
			}
			$awayPeople.delete user
			end
		end
		
end

EM.run {

	Turntabler.interactive

	Turntabler.run do
		$ttclient = Turntabler::Client.new('', '', :room => ROOM, :user_id => USER_ID, :auth => AUTH, :reconnect => true, :reconnect_wait => 60)

		# Let everyone know were online
		$ttclient.room.say version

		# Add the moderators to the moderators list
		$ttclient.room.moderators.each { |user| $moderators.push(user) }
      
		# Add perodic timer to remove ttstats
		EventMachine::PeriodicTimer.new(10) do
			Turntabler.run {
			boot_ttstats
			$ttclient.room.become_dj if autoDjMagicNumber > $ttclient.room.djs.count 
			
			}
			
		end
		$ttclient.room.become_dj if autoDjMagicNumber > $ttclient.room.djs.count && !($ttclient.room.djs.include? $ttclient.user)
	$ttclient.on :user_entered do |user|
		boot_ttstats
		# remove as dj if we have enough people, you aren't djing, and yet you are on the tables!
		$ttclient.user.remove_as_dj if autoDjMagicNumber < $ttclient.room.djs.count && $ttclient.user != $ttclient.room.current_dj && $ttclient.room.djs.include?($ttclient.user)
		end

   $ttclient.on :user_left do |user|
   	$ttclient.room.say "#{user.name} left the room"
		# Wait 15 seconds and if the user doesn't return remove them
		user_away user if ( $tableDjs.include? user )  && ( user != $lastDj )
      end

   $ttclient.on :dj_removed do |user|
		user_away user if ( $tableDjs.include? user )  && ( user != $lastDj )
	end

   $ttclient.on :dj_added do |user|
		# if there is no one in the queue let them up and update the tabledjs list
		$tableDjs = $ttclient.room.djs.clone if ($tableQueue.count == 0 )&& queue
		($ttclient.room.say("Sorry #{user.name}, but we have a queue that you need to join. Type /q+ to join it"); user.remove_as_dj) if $tableQueue.count > 0 && queue
	end
			
   $ttclient.on :song_snagged do |snag|
   	snags = snags + 1
      digest = Digest::MD5.hexdigest(snag.song.title + snag.song.artist)
      #$ttclient.room.say("#{snag.user.name} thinks this song is playlist worthy!")
      db.execute("UPDATE Songs SET timesSnagged = timesSnagged + 1 WHERE songid='#{digest}'")
      db.execute("UPDATE Users SET songsSnagged = songsSnagged + 1 WHERE userid='#{snag.user.id}'")
      db.execute("UPDATE Users SET songsShared = songsShared + 1 WHERE userid='#{$ttclient.room.current_dj.id}'")
      end

   $ttclient.on :song_started do |song|
		$lastDj = $ttclient.room.djs.first
		end

   $ttclient.on :song_ended do |song|
   	puts "Song Ended"
		bopped = false
		# Make the bot get down if we have enough people up there
		$ttclient.user.remove_as_dj if autoDjMagicNumber < $ttclient.room.djs.count && $ttclient.user != $ttclient.room.current_dj 

      
		# If slide is enabled and were past magic number then slide people 
		if $ttclient.room.djs.count > ( autoDjMagicNumber + 1 ) && slide
      	
			# Don't say something if we haven't gotten to the front of the line yet
      	if $ttclient.room.djs.first == song.played_by && $ttclient.room.djs.count > 3
		$ttclient.room.say("Thank you \@#{song.played_by.name}, could you please slide for us? (Auto remove in 20 seconds)") 
         	dj_to_boot = song.played_by
         	EventMachine::Timer.new(20) do
         		Turntabler.run {
            		if $ttclient.room.djs.first == dj_to_boot
               		$ttclient.room.say("Removing #{dj_to_boot.name}")
                  	dj_to_boot.remove_as_dj                 
                  	$tableDjs.delete dj_to_boot
			( $tableDjs.push($tableQueue.shift); $ttclient.room.say("Come on up #{$tableDjs.last.name}") ) if $tableQueue.count > 0
			$tableQueue.push dj_to_boot if queue
			end
                  }
					end # end timer
			end # end if front
			end # if side

         db.execute("UPDATE Users SET songsPlayed = songsPlayed + 1 WHERE userid='#{song.played_by.id}'")

			song.votes.each do |vote|
				db.execute("UPDATE Users SET songsAwesomed = songsAwesomed + 1 WHERE userid='#{vote.user.id}'") if vote.direction == :up
            db.execute("UPDATE Users SET songsLamed = songsLamed + 1 WHERE userid='#{vote.user.id}'") if vote.direction == :down	
				end

			digest = Digest::MD5.hexdigest(song.title + song.artist)

			$ttclient.room.say("\"#{song.title}\" Awesomes: #{song.up_votes_count} Lames: #{song.down_votes_count} Snags: #{snags}")

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
            db.execute "UPDATE Songs SET timesPlayed = #{timesPlayed}, timesAwesomed = #{timesAwesomed}, timesLamed = #{timesLamed}, timesSnagged = #{timesSnagged} WHERE songid='#{songid}'"
         else
            songid = digest
            title = song.title
            artist = song.artist
            timesPlayed = 1
            timesAwesomed = song.up_votes_count
            timesLamed = song.down_votes_count
            timesSnagged = snags
            db.execute "INSERT INTO Songs(songid, title, artist, timesPlayed, timesAwesomed, timesLamed, timesSnagged) VALUES ('#{songid}', '#{title.gsub(/'/,"")}', '#{artist.gsub(/'/,"")}', #{timesPlayed}, #{timesAwesomed}, #{timesLamed}, #{timesSnagged})"
            end
	$ttclient.room.say("Lifetime Awesomes: #{timesAwesomed} Lames: #{timesLamed} Snags: #{timesSnagged} Played: #{timesPlayed}")
   snags=0
	end # end song ended

	$ttclient.on :user_spoke do |message|
		case message.content 
			when /^\/slide$/
				# This is a wonderful trick, true = !(false) :p
				slide = !slide
				$ttclient.room.say("Slide is on") if slide
				$tableDjs = $ttclient.room.djs.clone if slide
				$ttclient.room.say("Slide is off") if !slide
			#when /^\/queue$/
			#		queue = !queue
			#		$ttclient.room.say("Queue is on") if queue
			#	$ttclient.room.say("Queue is off") if !queue
			when /^\/tdjs$/
				$tableDjs.each { |dj| $ttclient.room.say("On decks: #{dj.name}") }
			when /^\/q\+$/
				if queue
					if $ttclient.room.djs.include? message.sender
						$ttclient.room.say("#{message.sender.name} quit messin with me, you are already dj'ing!")
					elsif $tableQueue.include? message.sender
						$ttclient.room.say("#{message.sender.name} quit messin with me, you are already in the queue!") 
					else
					$tableQueue.push(message.sender)
					$ttclient.room.say("Alright #{message.sender.name} we added you to the queue position #{$tableQueue.count}.")
					end
				else
					$ttclient.room.say("There is no queue running right now.  Fastest Finger.")
				end
			when /^\/qr$/
				if queue
					if $tableQueue.include? message.sender
					$tableQueue.delete(message.sender)
					$ttclient.room.say("Alright #{message.sender.name} we removed you from the queue.")
					else
					$ttclient.room.say("Sorry #{message.sender.name}, but you aren't in the queue right now.")
					end
				else
                                        $ttclient.room.say("There is no queue running right now.  Fastest Finger.")
				end
			when /^\/ql$/
				if queue
					if $tableQueue.count == 0
					$ttclient.room.say("No one is in queue!") 
					else
                                        $tableQueue.each do |dj|
						$ttclient.room.say("In Queue: #{dj.name}")
					end
					end
                                else
                                        $ttclient.room.say("There is no queue running right now.  Fastest Finger!")
                                end
			when /^\/8-ball/
				$ttclient.room.say("The Magic 8-ball says: "+$responses["magic8ball"].sample)
			when /bop/
				$ttclient.room.say($responses['bop'].sample)
				$ttclient.room.current_song.vote if !bopped
				bopped = !bopped if !bopped 
			when /^\/rules$/
				$ttclient.room.say("Rock/Funk/Soul/Jazz 50's-70's; No AFK, No auto-DJ! Please remember to support your fellow DJ's by hitting the thumbs up if you are on the decks!!!")
			when /^\/Aries$/
				$ttclient.room.say "Aries: " + Nokogiri::HTML(open("http://my.horoscope.com/astrology/free-daily-horoscope-aries.html")).css("div.fontdef1").shift.text
                        when /^\/Taurus$/
                                $ttclient.room.say "Taurus: " + Nokogiri::HTML(open("http://my.horoscope.com/astrology/free-daily-horoscope-taurus.html")).css("div.fontdef1").shift.text
			when /^\/Gemini$/
				$ttclient.room.say "Gemini: " + Nokogiri::HTML(open("http://my.horoscope.com/astrology/free-daily-horoscope-gemini.html")).css("div.fontdef1").shift.text
                        when /^\/Cancer$/
                                $ttclient.room.say "Cancer: " + Nokogiri::HTML(open("http://my.horoscope.com/astrology/free-daily-horoscope-cancer.html")).css("div.fontdef1").shift.text
                        when /^\/Leo$/
                                $ttclient.room.say "Leo: " + Nokogiri::HTML(open("http://my.horoscope.com/astrology/free-daily-horoscope-leo.html")).css("div.fontdef1").shift.text
                        when /^\/Virgo$/
                                $ttclient.room.say "Virgo: " + Nokogiri::HTML(open("http://my.horoscope.com/astrology/free-daily-horoscope-virgo.html")).css("div.fontdef1").shift.text
                        when /^\/Libra$/
                                $ttclient.room.say "Libra: " + Nokogiri::HTML(open("http://my.horoscope.com/astrology/free-daily-horoscope-libra.html")).css("div.fontdef1").shift.text
                        when /^\/Scorpio$/
                                $ttclient.room.say "Scorpio: " + Nokogiri::HTML(open("http://my.horoscope.com/astrology/free-daily-horoscope-scorpio.html")).css("div.fontdef1").shift.text
                        when /^\/Sagittarius$/
                                $ttclient.room.say "Sagittarius: " + Nokogiri::HTML(open("http://my.horoscope.com/astrology/free-daily-horoscope-sagittarius.html")).css("div.fontdef1").shift.text
                        when /^\/Capricorn$/
                                $ttclient.room.say "Capricorn: " + Nokogiri::HTML(open("http://my.horoscope.com/astrology/free-daily-horoscope-capricorn.html")).css("div.fontdef1").shift.text
                        when /^\/Aquarius$/
                                $ttclient.room.say "Aquarius: " + Nokogiri::HTML(open("http://my.horoscope.com/astrology/free-daily-horoscope-aquarius.html")).css("div.fontdef1").shift.text
                        when /^\/Pisces$/
                                $ttclient.room.say "Pisces: " + Nokogiri::HTML(open("http://my.horoscope.com/astrology/free-daily-horoscope-pisces.html")).css("div.fontdef1").shift.text

			when /^\/t$/
				$ttclient.room.say("Theme is: #{theme}")
			when /^\/w (.+)$/
				zip = $1
				cnn = Nokogiri::HTML(open("http://weather.cnn.com/weather/forecast.jsp?zipCode=#{zip}"))
				location = cnn.css('div#cnnWeatherLocationHeader').shift.text.match(/(\w+,\s\w+)/)
				current_temp = cnn.css('div.cnnWeatherTempCurrent').shift.text.match(/(\d+)/)
				temps = cnn.css('div.cnnWeatherTemp').shift.text
				temp_hi = temps.match(/Hi\s(\d+)/)
				temp_low = temps.match(/Lo\s(\d+)/)
				$ttclient.room.say("The weather report for #{location} is Current Temp: #{current_temp} Todays: #{temp_hi} #{temp_low}")
			when /^\/t (.*)$/ 
				( theme = $1; $ttclient.room.say("Theme is set: #{theme}")) if $ttclient.room.moderators.include? message.sender 
			end # end case
	end # user spoke
	
	end	#end Turntabler.interactive


}
