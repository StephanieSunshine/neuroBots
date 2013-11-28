module Songvoted 

	def songVotedInit
		puts "songVotedInit called".yellow
  	self.client.on :song_voted do |song|
			puts ":song_voted called".red
			#puts PP.pp(song.votes.last, "").yellow
    	#client.room.say(":song_voted triggered vote counted #{person.user.name} #{person.direction}")
    	person = song.votes.last
			processAutoBop if (person.direction == :up)and(@botData['auto_bop'] == true)
    	#processEvent( person.user, "#song_lamed" ) if person.direction == :down
    	if (@botData['flags'].match(/B/))
				processAntiIdle( person.user) if (@botData['pkg_b_data']['anti_idle'].to_i == 1)
			end
    end

  end

end
