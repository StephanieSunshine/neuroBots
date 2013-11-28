module Userinput

	def userInputInit
		puts "userInputInit called".yellow

		self.client.on :user_spoke do |message|
			puts ":user_spoke called".red
    	if message.sender.id != self.client.user.id
      	processTriggers( message )
      	processPkgB( message, 0 ) if @botData['flags'].match(/B/)
				if (/B/ =~ @botData['flags'])
      		processAntiIdle( message.sender ) if (@botData['pkg_b_data']['anti_idle'].to_i == 1)
				end
    	end
    end
 
		self.client.on :message_received do |message|
			puts ":message_received called".red
    	processTriggers( message )
    	processPkgB( message, 1 ) if @botData['flags'].match(/B/)
    end

  end

end
