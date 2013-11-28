module Moderatoradded

	def moderatorAddedInit
		puts "moderatorAddedInit called".yellow
		self.client.on :moderator_added do |user|
			puts ":moderator_added called".red
			processEvent( user, "#moderator_added" )
		end

	end

end
