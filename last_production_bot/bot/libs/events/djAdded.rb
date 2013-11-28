module Djadded

  def djAddedInit
    puts "djAddedInit Called".yellow

    self.client.on :dj_added do |user|

			      #self.client.user.remove_as_dj if (self.client.user.dj?) and ( self.client.room.djs.count == 1 ) and (!@botData['alonedj']) and (@botData['autodj'])
      puts "Dj's counted: #{self.client.room.djs.count}".yellow
      # if were all by ourselves and djing we need to stop that
      self.client.user.remove_as_dj if (self.client.user.dj?)and(self.client.room.listeners == 1)and(self.client.room.current_dj != self.client.user)
      # if we have too many djs on stage, get down as well ( but only if were in autodj mode )
      self.client.user.remove_as_dj if (self.client.room.djs.count > 2)and(@botData['autodj'])and(self.client.user.dj?)and(self.client.room.current_dj != self.client.user)
      # if we are buy ourself onstage and we don't have alone dj get down
      self.client.user.remove_as_dj if (self.client.user.dj?)and(self.client.room.djs.count == 1)and(!@botData['alonedj'])and(self.client.room.current_dj != self.client.user)

      puts ":dj_added called".red
      @call_user = 0 if @called_user = user
      processEvent( user, "#dj_added" )
			if (@botData['flags'].match(/B/))
      	processAntiIdle(user) if (@botData['pkg_b_data']['anti_idle'].to_i == 1)
			end
      if ( @queue.count > 0 ) && ( !@tabledjs.include?(user) ) && @botData['queue']
        client.room.say("I'm sorry \@#{user.name}, but it isn't your turn yet.  People are waiting in the queue to play")
        user.remove_as_dj
        @dont_run_spooler = true
      elsif ( @queue.count == 0 ) && @botData['queue']
        @tabledjs.push(user)
      end
    end
  end
	

end
