module Processpkgb

	def processPkgB( message, loc )

  	# Dice  6
  	self.client.room.say("#{message.sender.name} rolled a " + rand(1..6).to_s ) if ( @botData['pkg_b_data']['dice_6_e'] == "1" ) and ( message.content.match(/^#{Regexp.escape(@botData['pkg_b_data']['dice_6_t'])}/)) and ( loc == 0 )
  	message.sender.say("#{message.sender.name} rolled a " + rand(1..6).to_s ) if ( @botData['pkg_b_data']['dice_6_e'] == "1" ) and ( message.content.match(/^#{Regexp.escape(@botData['pkg_b_data']['dice_6_t'])}/)) and ( loc == 1 )

  	# Dice 20
    self.client.room.say("#{message.sender.name} rolled a " + rand(1..20).to_s ) if ( @botData['pkg_b_data']['dice_20_e'] == "1" ) and ( message.content.match(/^#{Regexp.escape(@botData['pkg_b_data']['dice_20_t'])}/)) and ( loc == 0 )
    message.sender.say("#{message.sender.name} rolled a " + rand(1..20).to_s ) if ( @botData['pkg_b_data']['dice_20_e'] == "1" ) and ( message.content.match(/^#{Regexp.escape(@botData['pkg_b_data']['dice_20_t'])}/)) and ( loc == 1 )

  	# 8ball
  	self.client.room.say HTMLEntities.new.decode( @botData['pkg_b_data']['8ball_'+rand(1..20).to_s] ) if ( @botData['pkg_b_data']['8ball_e'] == "1" ) and ( message.content.match(/^#{Regexp.escape(@botData['pkg_b_data']['8ball_t'])} /)) and ( loc == 0 )
  	message.sender.say HTMLEntities.new.decode( @botData['pkg_b_data']['8ball_'+rand(1..20).to_s] ) if ( @botData['pkg_b_data']['8ball_e'] == "1" ) and ( message.content.match(/^#{Regexp.escape(@botData['pkg_b_data']['8ball_t'])} /)) and ( loc == 1 )

  	# Weather
 		if ( @botData['pkg_b_data']['weather_e'] == "1" ) and ( message.content.match(/^#{Regexp.escape(@botData['pkg_b_data']['weather_t'])} /) )

    	#zipCode = message.content.scan(/\d+/).shift
			#squish call string
			zipcode = message.content.sub(/^#{Regexp.escape(@botData['pkg_b_data']['weather_t'])} /,'')
			
			#get it ready to all
			zipcode = zipcode.gsub(/\s/,'%20')
			
			result = JSON.parse(open('http://api.wunderground.com/api/50ca23430fbf3b7d/conditions'+JSON.parse(open("http://autocomplete.wunderground.com/aq?query=#{zipcode}").read)['RESULTS'].first['l']+'.json').read)['current_observation']

			self.client.room.say HTMLEntities.new.decode("Forecast for #{result['display_location']['full']}") if loc == 0
			self.client.room.say HTMLEntities.new.decode("#{result['weather']} Temp: #{result['temperature_string']} Humidity: #{result['relative_humidity']} Wind: #{result['wind_string']}") if loc == 0
			
			self.message.sender.say HTMLEntities.new.decode("Forecast for #{result['display_location']['full']}") if loc == 1
			self.message.sender.say HTMLEntities.new.decode("#{result['weather']} Temp: #{result['temperature_string']} Humidity: #{result['relative_humidity']} Wind: #{result['wind_string']}") if loc == 1



    	#cnn = Nokogiri::HTML(open("http://weather.cnn.com/weather/forecast.jsp?zipCode=#{zipCode}"))
      #  location = cnn.css('div#cnnWeatherLocationHeader').shift.to_s.match(/\<b>(.*)<\/b>/)[1]
      #  current_temp = cnn.css('div.cnnWeatherTempCurrent').shift.text.match(/(\d+)/)
      #  temps = cnn.css('div.cnnWeatherTemp').shift.text
      #  temp_hi = temps.match(/Hi\s(\d+)/)
      #  temp_low = temps.match(/Lo\s(\d+)/)

    	#self.client.room.say("The weather report for #{location} is Current Temp: #{current_temp} Todays: #{temp_hi} #{temp_low}") if loc == 0
    	#message.sender.say("The weather report for #{location} is Current Temp: #{current_temp} Todays: #{temp_hi} #{temp_low}") if loc == 1
  	end

  	# Wikipedia
    if ( @botData['pkg_b_data']['wikipedia_e'] == "1" ) and ( message.content.match(/^#{Regexp.escape(@botData['pkg_b_data']['wikipedia_t'])} /))

    	search = message.content.gsub(/^#{Regexp.escape(@botData['pkg_b_data']['wikipedia_t'])} /, "")
      rsearch = search.gsub(/ /,"_")
      myuri = "http://en.wikipedia.org/wiki/#{rsearch}"
    	#myuri2 = "http://www.google.com/?q=wikipedia+#{rsearch}&bntl"
			wikipedia = Nokogiri::HTML(open(myuri))

    	result = wikipedia.css('p')[0].text

    	self.client.room.say HTMLEntities.new.decode(result)
    	self.client.room.say("#{myuri}")
    end

  	# Last.fm
   	if ( @botData['pkg_b_data']['last_fm_e'] == "1" ) and ( message.content.match(/^#{Regexp.escape(@botData['pkg_b_data']['last_fm_t'])} /))

     	search = message.content.gsub(/^#{@botData['pkg_b_data']['last_fm_t']} /, "")
      rsearch = search.gsub(/ /,"+")
      myuri = "http://www.last.fm/music/#{rsearch}"
      wikipedia = Nokogiri::HTML(open(myuri))

      result = wikipedia.css('div#wikiAbstract')[0].css('div')[0].text
                
		  self.client.room.say HTMLEntities.new.decode(result)
      self.client.room.say("#{myuri}")
  	end

  	# User Lookup
  	if ( @botData['pkg_b_data']['user_lookup_e'] == "1" ) and ( message.content.match(/^#{Regexp.escape(@botData['pkg_b_data']['user_lookup_t'])} /))
    	search = message.content.gsub(/^#{Regexp.escape(@botData['pkg_b_data']['user_lookup_t'])} /, "")
    	self.db.query("select * from bot_ustats_#{MAGICKEY} where LOWER(name) = LOWER('#{self.db.escape(search)}')  LIMIT 1").each do |row|
      case  loc
    		when 0
      		self.client.room.say("#{row['name']}:")
      		self.client.room.say("#{row['last_seen']}")
      		self.client.room.say("[#{row['songs_awesomed']}:thumbsup:][#{row['songs_lamed']}:thumbsdown:][#{row['songs_snagged']}<3][#{row['songs_played']}:dvd:]")
      		#client.room.say("#{row[0]}")
   			when 1
      		message.sender.say("#{row['name']}:")
      		message.sender.say("#{row['last_seen']}")
      		message.sender.say("[#{row['songs_awesomed']}:thumbsup:][#{row['songs_lamed']}:thumbsdown:][#{row['songs_snagged']}<3][#{row['songs_played']}:dvd:]")
      		message.sender.say("#{row['userid']}")
				end
      end
    end

  # Horoscope
  if ( @botData['pkg_b_data']['horoscope_e'] == "1" )
     self.client.room.say "Aries: " + Nokogiri::HTML(open("http://my.horoscope.com/astrology/free-daily-horoscope-aries.html")).css("div.fontdef1").shift.text if message.content.match(/^.aries/)
     self.client.room.say "Taurus: " + Nokogiri::HTML(open("http://my.horoscope.com/astrology/free-daily-horoscope-taurus.html")).css("div.fontdef1").shift.text if message.content.match(/^.taurus/)
     self.client.room.say "Gemini: " + Nokogiri::HTML(open("http://my.horoscope.com/astrology/free-daily-horoscope-gemini.html")).css("div.fontdef1").shift.text if message.content.match(/^.gemini/)
     self.client.room.say "Cancer: " + Nokogiri::HTML(open("http://my.horoscope.com/astrology/free-daily-horoscope-cancer.html")).css("div.fontdef1").shift.text if message.content.match(/^.cancer/)
     self.client.room.say "Leo: " + Nokogiri::HTML(open("http://my.horoscope.com/astrology/free-daily-horoscope-leo.html")).css("div.fontdef1").shift.text if message.content.match(/^.leo/)
     self.client.room.say "Virgo: " + Nokogiri::HTML(open("http://my.horoscope.com/astrology/free-daily-horoscope-virgo.html")).css("div.fontdef1").shift.text if message.content.match(/^.virgo/)
     self.client.room.say "Libra: " + Nokogiri::HTML(open("http://my.horoscope.com/astrology/free-daily-horoscope-libra.html")).css("div.fontdef1").shift.text if message.content.match(/^.libra/)
     self.client.room.say "Scorpio: " + Nokogiri::HTML(open("http://my.horoscope.com/astrology/free-daily-horoscope-scorpio.html")).css("div.fontdef1").shift.text if message.content.match(/^.scorpio/)
     self.client.room.say "Sagittarius: " + Nokogiri::HTML(open("http://my.horoscope.com/astrology/free-daily-horoscope-sagittarius.html")).css("div.fontdef1").shift.text if message.content.match(/^.sagittarius/)
     self.client.room.say "Capricorn: " + Nokogiri::HTML(open("http://my.horoscope.com/astrology/free-daily-horoscope-capricorn.html")).css("div.fontdef1").shift.text if message.content.match(/^.capricorn/)
     self.client.room.say "Aquarius: " + Nokogiri::HTML(open("http://my.horoscope.com/astrology/free-daily-horoscope-aquarius.html")).css("div.fontdef1").shift.text if message.content.match(/^.aquarius/)
     self.client.room.say "Pisces: " + Nokogiri::HTML(open("http://my.horoscope.com/astrology/free-daily-horoscope-pisces.html")).css("div.fontdef1").shift.text if message.content.match(/^.pisces/)

  end

  if (message.content.match(/^\.\.bd_test/))
	puts "Backdoor Called".red
  now = Time.new().to_i
	self.client.room.say("Backdoor says listeners's count: #{self.client.room.listeners.count}")
	#puts PP.pp(@antiIdle, "").yellow
    #@antiIdle.each do |dj|
		#	puts "Backdoor: User: #{dj['user'].name} Timer: #{dj['timer']}".yellow
		#end
   #   user = self.client.user(dj['user'])
   #   self.client.room.say("#{dj['user']} = #{user.name} Idle: #{now - dj['timer'].to_i}")
    end
   # self.client.room.say(self.client.user('4ea8d05fa3f751271d024366').name)
  #end
  # pp $botData['pkg_b_data']

end

end
