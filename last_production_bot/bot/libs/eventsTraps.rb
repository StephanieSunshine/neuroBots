require './libs/events/moderatorAdded.rb'
require './libs/events/djAdded.rb'
require './libs/events/djRemoved.rb'
require './libs/events/roomUpdated.rb'
require './libs/events/userBooted.rb'
require './libs/events/songStarted.rb'
require './libs/events/songEnded.rb'
require './libs/events/songSnagged.rb'
require './libs/events/songVoted.rb'
require './libs/events/nameUpdated.rb'
require './libs/events/userJoined.rb'
require './libs/events/userParted.rb'
require './libs/events/userInput.rb'

module Eventstraps

	include Moderatoradded, Djadded, Djremoved, Roomupdated, Userbooted, Songstarted, Songended, Songsnagged, Songvoted, Nameupdated, Userjoined, Userparted, Userinput

	def processEvent( user, t_event )
		
		# client.room.say("Processing Event #{t_event}")
  	if user.id != self.client.user.id
    	@botData['events'].each { |event|
      	if event['event'] == t_event
        	if event['delivery_method'].to_i == 1
          	if event['include_name'].to_i == 0
            	self.client.room.say HTMLEntities.new.decode(event['pre_text'] + event['post_text'])
            else
            	self.client.room.say HTMLEntities.new.decode(event['pre_text'] + user.name + event['post_text'])
            end
          else
          	if event['include_name'].to_i == 0
          		user.say HTMLEntities.new.decode(event['pre_text'] + event['post_text'])
            else
            	user.say HTMLEntities.new.decode(event['pre_text'] + user.name + event['post_text'])
            end
          end
        end
      }
    end
  end

	def trapEvents
		
		moderatorAddedInit
		djAddedInit			
		djRemovedInit
		roomUpdatedInit
		userBootedInit
		songStartedInit
		songEndedInit
		songSnaggedInit
		songVotedInit
		nameUpdatedInit
	  userJoinedInit
		userPartedInit
		userInputInit

	end

end
