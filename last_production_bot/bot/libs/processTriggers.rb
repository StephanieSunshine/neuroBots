module Processtriggers

	def validate_security(id, level)
  returnset = 0
  	case level
    	when 0 # Anyone
      	returnset = 1
    	when 1 # Level 1
      	returnset = 1 if(@botData['level1acl'].include?(id)||@botData['level2acl'].include?(id)||@botData['level3acl'].include?(id)||@botData['ownerid'] == id)
    	when 2 # Level 2
      	returnset = 1 if(@botData['level2acl'].include?(id)||@botData['level3acl'].include?(id)||@botData['ownerid'] == id)
    	when 3 # Level 3
      	returnset = 1 if(@botData['level3acl'].include?(id)||@botData['ownerid'] == id)
    	when 4 # Owner
      	returnset = 1 if(@botData['ownerid'] == id)
    end
  	if returnset == 1
    	return true
  	else
    	return false
  	end
	end

	def trigger_speak( trigger, name )
		if trigger['use_saying_switch'].to_i == 1
  		self.client.room.say HTMLEntities.new.decode(@sayings.sample)
		else
  		if trigger['use_name_switch'].to_i == 1
    		self.client.room.say HTMLEntities.new.decode(trigger['pre_name_response']+name+trigger['post_name_response']) if (trigger['pre_name_response'] != "")||(trigger['post_name_response'] != "")
  		else
    		self.client.room.say HTMLEntities.new.decode(trigger['pre_name_response']+trigger['post_name_response']) if (trigger['pre_name_response'] != "")||(trigger['post_name_response'] != "")
  		end
		end
	end



        def trigger_pm( trigger, user )
                if trigger['use_saying_switch'].to_i == 1
                        user.say HTMLEntities.new.decode($sayings.sample)
                else
    if trigger['use_name_switch'].to_i == 1
        user.say HTMLEntities.new.decode(trigger['pre_name_response']+user.name+trigger['post_name_response']) if (trigger['pre_name_response'] != "")||(trigger['post_name_response'] != "")
    else
        user.say HTMLEntities.new.decode(trigger['pre_name_response']+trigger['post_name_response']) if (trigger['pre_name_response'] != "")||(trigger['post_name_response'] != "")
    end
        end
end



	def processTriggers( message )
  	
		@botData['triggers'].each do |trigger|
    	if (( (trigger['use_trigger_switch'].to_i == 1) && (trigger['use_strict_matching'].to_i == 1) && message.content.match("^"+Regexp.escape(@botData['command_trigger'])+Regexp.escape(trigger['trigger_phrase'])+"$"))||((trigger['use_trigger_switch'].to_i == 0) && (trigger['use_strict_matching'].to_i == 1) && message.content.match("^"+Regexp.escape(trigger['trigger_phrase'])+"$"))||((trigger['use_trigger_switch'].to_i == 1) && (trigger['use_strict_matching'].to_i == 0) && message.content.match("^"+Regexp.escape(@botData['command_trigger'])) && message.content.match(Regexp.escape(trigger['trigger_phrase'])))||( (trigger['use_trigger_switch'].to_i == 0) && (trigger['use_strict_matching'].to_i == 0) && message.content.match(Regexp.escape(trigger['trigger_phrase'])) ))
                        # Mark
                        # client.room.say("Action Triggered #{trigger['action']}")
                        # client.room.say("Validate Security says: "+validate_security(message.sender.id, trigger['access_level'].to_i).to_s)
      	if validate_security(message.sender.id, trigger['access_level'].to_i)
        	case trigger['action']
          	when "*queue_move"
            	(from, to) =  message.content.gsub(/^.+#{trigger['trigger_phrase']}/, '').scan(/\d+/)
              if ( from.abs < @queue.count ) && ( to.abs < @queue.count )
              	self.client.room.say HTMLEntities.new.decode("Moving \##{from} to \##{to}")
                @queue.insert(to, @queue.delete_at(from))
              else
              	self.client.room.say("Queue Move failed: Out of Range")
              end

            when "*queue_list"
            	if @botData['queue']
              	if @queue.count != 0
                	@queue.each_with_index do |user, i|
                  	self.client.room.say HTMLEntities.new.decode("Queue Slot \##{i} #{user.name}")
                  end
                else
                	self.client.room.say("The queue is empty.")
                end
              else
              	self.client.room.say("The queue is not enabled right now.  Fastest finger right now.")
              end

            when "*queue_add"
            	if @botData['queue']
              	if !@tabledjs.include?(message.sender)
                	if @tabledjs.count == 5
                  	if !@queue.include?(message.sender)
                    	@queue.push(message.sender)
                      self.client.room.say HTMLEntities.new.decode("Ok #{message.sender.name}, you are #{@queue.count} in the queue")
                    else
                    	self.client.room.say HTMLEntities.new.decode("I'm sorry #{message.sender.name}, but you are already in the queue")
                    end
                  else
                  	self.client.user.say("There is a free spot, go fot it")
                  end
                else
                	self.client.room.say("I can't add you to the queue.  You are already djing")
                end
              else
              	self.client.room.say("The queue is not enabled right now.  Fastest finger right now.")
              end
           
						when "*queue_remove"
            	if @botData['queue']
              	if @queue.include?(message.sender)
                	@queue.delete(message.sender)
                  self.client.room.say HTMLEntities.new.decode("Ok #{message.sender.name}, I'm removing you from the queue")
                else
                	self.client.room.say HTMLEntities.new.decode("I'm sorry #{message.sender.name}, but you aren't in the queue right now")
                end
              else
              	self.client.room.say("The queue is not enabled right now.  Fastest finger right now.")
              end

            when "*slide"
            	@botData['slide'] = !@botData['slide']
              self.client.room.say("Slide is on: #{@botData['slide']}")

            when "*stats"
            	@botData['stats'] = !@botData['stats']
              self.client.room.say("Display round stats: #{@botData['stats']}")

            when "*autodj"
            	@botData['autodj'] = !@botData['autodj']
              self.client.room.say("Auto DJ: #{@botData['autodj']}")

            when "*queue"
            	@botData['queue'] = !@botData['queue']
              if @botData['queue']
              	@tabledjs = []
                @called_dj = ""
                @running = false
                self.client.room.djs.each do |dj|
                	@tabledjs.push(dj)
                end
              end
              	@tabledjs = [] if !@botData['queue']
                self.client.room.say("Queue is on: #{@botData['queue']}")

            when "*theme"
            	tmp_trigger = trigger.clone
              tmp_trigger['pre_name_response'] = "Theme is: " + tmp_trigger['pre_name_response']
              trigger_speak( tmp_trigger, message.sender.name )
            
						when "*themeset"
            	theme_input = message.content.gsub(/^.+#{trigger['trigger_phrase']}/, '')
              pre_post = []
              pre_post[0] = ""
              pre_post[1] = ""
              use_name = "0"
              if theme_input.include?('$name')
              	#has name
                pre_post = theme_input.split('$name')
                use_name = "1"
                #client.room.say(" Pre:'#{pre_post[0]}' Post: '#{pre_post[1]}'")
              else
                pre_post[0] = theme_input
                pre_post[1] = ''
                #no name
              end
              pre_post[1] = "" if pre_post[1] == nil
              @botData['triggers'].each do |trig|
              	if trig['action'] == "*theme"
                	trig['use_name_switch'] = use_name
                  trig['pre_name_response'] = pre_post[0]
                  trig['post_name_response'] = pre_post[1]
                end
              end
              trigger_speak( trigger, message.sender.name )
              #client.room.say("Found #{message.content.gsub(/^.+#{trigger['trigger_phrase']}/, '')}")
              
						when "*voteup"
            	# trigger_speak( client, pre, post, name, switch )
              trigger_speak( trigger, message.sender.name )
              self.client.room.current_song.vote
						
            when "*votedown"
            	self.client.room.current_song.vote(:down)
              trigger_speak(	trigger, message.sender.name )
						
            when "*action"
            	trigger_speak( trigger, message.sender.name	)

            when "*actionpm"
 		          trigger_pm(trigger, message.sender)

            when "*status"
            	message.sender.say("triggers: #{@botData['triggers'].count} ads: #{@botData['ads'].count} events: #{@botData['events'].count} acls: #{@aclCount} sayings: #{@sayings.count}  ")
              message.sender.say("Slide: #{@botData['slide']}  Queue: #{@botData['queue']}  AutoDj: #{@botData['autodj']}  Stats: #{@botData['stats']}")

            when "*restart"
            	trigger_speak( trigger, message.sender.name  )
              exit
            
						when "*rehash"
            	trigger_speak( trigger, message.sender.name )
              rehash( message.sender )

            when "*snag"
            	self.client.room.current_song.add( :index => (self.client.user.playlist.songs).count )
              self.client.room.current_song.snag
              trigger_speak( trigger, message.sender.name )
            
						when "*nextup"
            	self.client.user.playlist.update
              self.client.room.say('Next song: '+((self.client.user.playlist.songs)[0]).title+' by '+((self.client.user.playlist.songs)[0]).artist)
              self.client.room.say('Next song: '+((self.client.user.playlist.songs)[1]).title+' by '+((self.client.user.playlist.songs)[1]).artist)
            
						when "*skip"
            	if self.client.room.current_dj == self.client.user
              	self.client.room.current_song.skip
                self.client.user.playlist.update
                #(client.user.playlist.songs)[-1].move(0)
                #((client.user.playlist.songs)[0]).move((client.user.playlist.songs).count)
              else
              	(self.client.user.playlist.songs)[0].move(-1)
                #((client.user.playlist.songs)[0]).skip
              end
              self.client.user.playlist.update
              trigger_speak( trigger ,message.sender.name )

						when "*forget"
            	if self.client.room.current_dj == self.client.user
              	self.client.room.current_song.skip
                self.client.user.playlist.songs.last.remove
              else
              	self.client.user.playlist.songs.first.remove
              end
              self.client.user.playlist.update
              trigger_speak( trigger, message.sender.name )

						when "*hopup"
            	self.client.room.become_dj
              trigger_speak( trigger, message.sender.name )

						when "*hopdown"
            	self.client.user.remove_as_dj
              trigger_speak( trigger, message.sender.name )

						when "*userids"
            	self.client.room.listeners.each do |listener|
              	message.sender.say("#{listener.name}")
                message.sender.say("#{listener.id}")
              end

            when "*say"
            	self.client.room.say(message.content.gsub(/^.+#{trigger['trigger_phrase']} /, ''))

            when "*kick"
            	userid = message.content.match(/(\h+)$/)
              	if @botData['ownerid'].match(/#{userid}/)
                	self.client.room.say("I'm sorry, but I can't do that to my owner")
                else
                	self.client.user(userid).boot(trigger['pre_name_response'])
                end

						when "*ban"
            	userid = message.content.match(/(\h+)$/)
              if @botData['ownerid'].match(/#{userid}/)
              	self.client.room.say("I'm sorry, but I can't do that to my owner")
              else
              	URI.parse("http://www.neurobots.net/websockets/blacklistpush.php?magic_key=#{MAGICKEY}&target=#{userid}&reason=#{message.sender.name}+banned+#{userid}").read
                @botData['blacklist'].push("#{userid}")
								self.client.room.dj(userid).boot('Blacklisted')
								 #user.boot('Blacklisted') if @botData['blacklist'].include?(user.id)
                #client.user(userid).boot(trigger['response'])
              end

            when "*removedj"
            	self.client.room.current_dj.remove_as_dj
              trigger_speak( trigger, message.sender.name )
                                
						when "*fan"
            	begin
              self.client.room.current_dj.become_fan
              trigger_speak( trigger ,message.sender.name )
              rescue
              #client.room.say("failtest");
              @errorcounts['fan'] = 1 if @errorcounts['fan'] == nil
              if (trigger['post_command_fail'] == "")
              	self.client.room.say HTMLEntities.new.decode(trigger['pre_command_fail'])
              else
              	self.client.room.say HTMLEntities.new.decode("#{trigger['pre_command_fail']}#{@errorcounts['fan']}#{trigger['post_command_fail']}")
                @errorcounts['fan'] += 1
              end
            end
          end
        end
      end
    end
	end
end
