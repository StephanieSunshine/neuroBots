module Processautobop

	def processAutoBop
		if (@autobop_count == 3)
			self.client.room.current_song.vote	
			@autobop_count += 1
		else
			@autobop_count += 1
		end

	end
end
