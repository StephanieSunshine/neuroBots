module Userbooted

	def userBootedInit
		puts "userBootedInit called".yellow
 		self.client.on :user_booted do |boot|
			puts ":user_booted called".red
    	processEvent( boot.user, "#user_booted" )
    end

  end

end
