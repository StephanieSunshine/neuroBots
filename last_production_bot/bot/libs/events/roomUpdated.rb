module Roomupdated

	def roomUpdatedInit
		puts "roomUpdatedInit called".yellow
		self.client.on :room_updated do |room|
			puts ":room_updated called".red
			@botData['events'].each { |event| self.client.room.say(event['pre_text'] + event['post_text']) if event['event'] == "#room_updated" }
		end

	end


end
