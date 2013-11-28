module Songstarted

	def songStartedInit
		puts "songStartedInit called".yellow
		self.client.on :song_started do |song|
			puts ":song_started called".red

    	self.db.query("insert into bot_sstats_#{MAGICKEY} set songid='#{digest(song.title, song.artist)}', title='#{self.db.escape(song.title)}', artist='#{self.db.escape(song.artist)}', first_user_played='#{song.played_by.id}' on duplicate key update times_played=times_played+1")
    	self.db.query("update bot_ustats_#{MAGICKEY} set songs_played=songs_played+1 where userid='#{song.played_by.id}'")

    EventMachine::Timer.new(song.length+5) do
                        Turntabler.run { song.skip if (self.client.room.current_song == song) && (self.client.room.current_dj == self.client.user) }
      end
    @errorcounts = Hash.new
    end


  end

end
