module Songended

	def songEndedInit
		puts "songEndedInit called".yellow

    self.client.on :song_ended do |song|
			puts ":song_ended called".red
			puts "Votes Counted: #{song.votes.count}".yellow
			#Anti Idle
			if (@botData['flags'].match(/B/))
				processAntiIdle(song.played_by) if (@botData['pkg_b_data']['anti_idle'].to_i == 1)		
			end

			#more anti idle stuff
			@last_dj = song.played_by
			
			#AloneDJ Patch
			#Fucking race conditions, something is calling song started after we've hopped down on our own queue.....
			#This is a horrible patch, but should work
  		EventMachine::Timer.new(1) do
    		Turntabler.run { 
					self.client.user.remove_as_dj if (self.client.user.dj?)and(self.client.room.djs.count == 1)and(!@botData['alonedj'])and(@botData['autodj'])and(@last_dj == self.client.user) 
					self.client.user.remove_as_dj if (self.client.room.djs.count > 2)and(self.client.user.dj?)and(self.client.room.current_dj != self.client.user)
			}
			end

			#puts PP.pp(song, "").yellow
			@autobop_count = 0
      if song.played_by != self.client.user
                self.db.query("insert into bot_sstats_#{MAGICKEY} set songid='#{digest(song.title, song.artist)}', title='#{self.db.escape(song.title)}', artist='#{self.db.escape(song.artist)}', first_user_played='#{song.played_by.id}' on duplicate key update times_played=times_played")
								self.db.query("update bot_sstats_#{MAGICKEY} set times_awesomed=times_awesomed+#{song.up_votes_count}, times_lamed=times_lamed+#{song.down_votes_count} where songid='#{digest(song.title, song.artist)}'")
                self.client.room.say("#{song.title}") if @botData['stats']
                self.client.room.say("Round:[ #{song.up_votes_count} :thumbsup:  ][ #{song.down_votes_count} :thumbsdown:  ][ #{@snagged} <3  ]") if @botData['stats']
                @snagged=0

                self.db.query("select times_awesomed, times_lamed, times_snagged, times_played from bot_sstats_#{MAGICKEY} where songid='#{digest(song.title, song.artist)}' limit 1").each do |lsong|
                		self.client.room.say("Life:[ #{lsong['times_awesomed']} :thumbsup:  ][ #{lsong['times_lamed']} :thumbsdown:  ][ #{lsong['times_snagged']} <3  ][ #{lsong['times_played']} :dvd:  ]") if @botData['stats']
								end
                song.votes.each do |vote|
									#puts "Vote Check".yellow
									#puts "Vote Count For: #{vote.user.name} Up".yellow if vote.direction == :up
									#puts "Vote Count For: #{vote.user.name} Down".yellow if vote.direction == :down
								
                	self.db.query("update bot_ustats_#{MAGICKEY} set songs_awesomed=songs_awesomed+1 where userid='#{vote.user.id}'") if vote.direction == :up
                	self.db.query("update bot_ustats_#{MAGICKEY} set songs_lamed=songs_lamed+1 where userid='#{vote.user.id}'") if vote.direction == :down
        				end
        end

        @queue.push(song.played_by) if (@queue.count > 0)&&(@botData['autoReQueue'])


        if @botData['slide'] && self.client.room.djs.count > 4
        if self.client.room.djs.first == song.played_by
                self.client.room.say("Thank you \@#{song.played_by.name}, could you please slide for us? (Auto remove in 20 seconds)")
                dj_to_boot = song.played_by
                EventMachine::Timer.new(20) do
                Turntabler.run {
                        if self.client.room.djs.first == dj_to_boot
                self.client.room.say("Removing #{dj_to_boot.name}")
                dj_to_boot.remove_as_dj
              end
                }
                end
        end
        end
        end

        end

end

