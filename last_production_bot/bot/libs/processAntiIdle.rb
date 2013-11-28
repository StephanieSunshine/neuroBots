module Processantiidle

def processAntiIdle(user)
	#Fucking race conditions.........
	return 1 if @anti_idle_running
	@anti_idle_running = true
	my_djlist = []
  #Validate list of dj's is current
  now = Time.new()
  puts "Anti-Idle Processing".red
  #Add any new ones that did just join
  self.client.room.djs.each do |ndj|
		#puts "Anti-Idle: Pass 1 testing #{ndj.name}".yellow
    newdj = true
    @antiIdle.each do |odj|
			# puts "Anti-Idle: odj: #{odj['user'].name} cdj: #{ndj.name}".yellow
			# If this is the user that triggered this then update their time
    	odj['timer'] = now.to_i if user == odj['user']
			# If this user exists in the old list then it's not a new user
		  newdj = false if odj['user'] == ndj
    	# push the old folks out to the new list
		  my_djlist.push(odj) if odj['user'] == ndj
		  end
			# new comers to the list
    if newdj
			# puts "Anti-Idle: #{ndj.name} is a new comer".yellow
      a_newdj = {}
      a_newdj['user'] = ndj
      a_newdj['warned'] = false
      a_newdj['booted'] = false
      a_newdj['timer'] = now.to_i
      my_djlist.push(a_newdj)
    end
  end
	#Wipe antiIdle
	@antiIdle = []
		# purge anyone that isn't there anymore but still in our memory
  my_djlist.each do |dj|
		# puts "Anti-Idle: my_djlist: #{dj['name']}".yellow
		dj['timer'] = now.to_i if (self.client.room.current_dj == dj['user'])
  	@antiIdle.push(dj) if self.client.room.djs.include?(dj['user'])
		# puts "Dj pushed" if self.client.room.djs.include?(dj['user'])
    end
	my_djlist = []
  #Ok validate they haven't hit one of the clips
  	@antiIdle.each do |dj|
			# Check timer for boot
			if (( now.to_i - dj['timer'].to_i ) > @botData['pkg_b_data']['ai_msg_t'].to_i)
				#Boot time

				puts "Booting #{dj['user'].name}".yellow
				output = @botData['pkg_b_data']['ai_msg'].gsub(/\$name/,dj['user'].name)

      	self.client.room.say(HTMLEntities.new.decode output)
				
				dj['user'].remove_as_dj

				dj['booted'] = true

			elsif ((( now.to_i - dj['timer'].to_i ) > @botData['pkg_b_data']['ai_w_msg_t'].to_i)and(!dj['warned']))

				#Warn time
				puts "Warning #{dj['user'].name}".yellow

        output = @botData['pkg_b_data']['ai_w_msg'].gsub(/\$name/,dj['user'].name)
        output = output.gsub(/\$time/,(@botData['pkg_b_data']['ai_msg_t'].to_i-@botData['pkg_b_data']['ai_w_msg_t'].to_i).to_s)

        self.client.room.say(HTMLEntities.new.decode output)				

				dj['warned'] = true

			end

#    	# if timer has ran out and it's not the current dj or the last dj ( only if slide is enabled )
#			if ((( now.to_i - dj['timer'].to_i ) > @botData['pkg_b_data']['ai_msg_t'].to_i)and((self.client.room.current_dj != dj['user'])or((@last_dj != dj['user'])and(@botData['slide']))))
#      	#boot
#				output = @botData['pkg_b_data']['ai_msg'].gsub(/\$name/,dj['user'].name)
#      	self.client.room.say(output)
#      	dj['user'].removedj
#      	#dj['booted'] = true
#				#warning timer ran out and it's not the current dj or the last dj ( only if slide is enabled )
#    	elsif ((( now.to_i - dj['timer'].to_i ) > @botData['pkg_b_data']['ai_w_msg_t'].to_i)and(!dj['warned'])and((self.client.room.current_dj != dj['user'])or((@last_dj != dj['user'])and(@botData['slide']))))
#      	#Warn
#      	#Flag
#				puts "Current DJ: #{self.client.room.current_dj.name} DJ in question: #{dj['user'].name}".yellow
#				output = @botData['pkg_b_data']['ai_w_msg'].gsub(/\$name/,dj['user'].name)
#				output = output.gsub(/\$time/,(@botData['pkg_b_data']['ai_msg_t'].to_i-@botData['pkg_b_data']['ai_w_msg_t'].to_i).to_s)
#      	self.client.room.say(output)
#      	dj['warned'] = true
#    	end
    	my_djlist.push(dj) if !dj['booted']
    end
		
		@antiIdle = my_djlist
		@anti_idle_running = false
end

end
