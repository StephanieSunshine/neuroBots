module Djremoved

  def djRemovedInit
  puts "djRemovedInit called".yellow

  self.client.on :dj_removed do |user|
	puts ":dj_removed called".red

      #self.client.user.remove_as_dj if (self.client.user.dj?) and ( self.client.room.djs.count == 1 ) and (!@botData['alonedj']) and (@botData['autodj'])
      puts "Dj's counted: #{self.client.room.djs.count}".yellow
      # if were all by ourselves and djing we need to stop that
      self.client.user.remove_as_dj if (self.client.user.dj?)and(self.client.room.listeners == 1)and(self.client.room.current_dj != self.client.user)
      # if we have too many djs on stage, get down as well ( but only if were in autodj mode )
      self.client.user.remove_as_dj if (self.client.room.djs.count > 2)and(@botData['autodj'])and(self.client.user.dj?)and(self.client.room.current_dj != self.client.user)
      # if we are buy ourself onstage and we don't have alone dj get down
      self.client.user.remove_as_dj if (self.client.user.dj?)and(self.client.room.djs.count == 1)and(!@botData['alonedj'])and(self.client.room.current_dj != self.client.user)and(@botData['autodj'])

  	processEvent( user,  "#dj_removed" )
		
		if(@botData['flags'].match(/B/))
	    processAntiIdle(user) if (@botData['pkg_b_data']['anti_idle'].to_i == 1)
		end
    @tabledjs.delete(user) if @tabledjs.include?(user)
    if (!@running)&&(!@queue.empty?)
      @running = true
      @called_dj = @queue.shift
      @tabledjs.push(@called_dj)
      self.client.room.say("Ok \@#{@called_dj.name}, you have 30 seconds to get to the stage")
      timer_handle = EventMachine.add_periodic_timer(30) do
        Turntabler.run {
          if self.client.room.djs.include?(@called_dj)
            @running = false
            timer_handle.cancel
          else
            self.client.room.say("\@#{@called_dj.name} you took too long!")
            @tabledjs.delete(@called_dj)
            if !@queue.empty?
              @called_dj = @queue.shift
              @tabledjs.push(@called_dj)
              self.client.room.say("Ok \@#{@called_dj.name}, you have 30 seconds to get to the stage")
            else
              self.client.room.say("Nobody left in the queue!")
              @running = false
              timer_handle.cancel
            end
          end

        }
        end
      end
    end

  end

end
