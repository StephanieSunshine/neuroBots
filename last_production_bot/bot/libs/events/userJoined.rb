module Userjoined

	def userJoinedInit
		puts "userJoinedInit called".yellow
  	self.client.on :user_entered do |user|
			puts ":user_entered called".red
    	if @botData['blacklist'].include?(user.id)
      	user.boot('Blacklisted')
    	elsif user.id == self.client.user.id
      	# No op
    	else
    		self.db.query("insert into bot_ustats_#{MAGICKEY} set userid='#{user.id}', last_seen='#{`date`.chomp}', name='#{self.db.escape(user.name)}' on duplicate key update last_seen='#{`date`.chomp}', name='#{self.db.escape(user.name)}' ")

    		EventMachine::Timer.new(5) { Turntabler.run { processEvent( user, '#user_entered') } }
    	end

	  end

	end

end
