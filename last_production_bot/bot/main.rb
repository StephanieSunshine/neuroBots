#!/usr/bin/env ruby

# Basic requires needed to make this possible

require 'rubygems'
require 'turntabler'
require 'monitor'
require 'eventmachine'
require 'json'
require 'open-uri'
require 'pp'
require 'mysql2'
require 'digest/md5'
require 'nokogiri'
#require 'debugger'
require 'colorize'
require 'htmlentities'

require './libs/syncUserList.rb'
require './libs/backgroundLoop.rb'
require './libs/eventsTraps.rb'
require './libs/processAntiIdle.rb'
require './libs/digest.rb'
require './libs/processTriggers.rb'
require './libs/processPkgB.rb'
require './libs/processAutoBop.rb'

CODENAME = "neuroBot"
VERSION  = "1.0"

DBHOST   = 'db.neurobots.net'
DBTABLE  = 'neurobots'
DBUSER	 = ''
DBPASS	 = ''

# Sanitize the envrioment first, the enviroment should have the magic key and the command line the bot_userid.  
# The bot userid is consider public knowledge so there is no desire to protect that.  
# However the magic_key is how we two factor everything, so we want to protect that.

# Check for bot userid

abort "No Bot Userid found.  Usage: ./main <bot userid> <magic key>" if !(ARGV.count > 0)
abort "No magic key found.  Usage: ./main <bot userid> <magic key>" if !(ARGV.count > 1)

# Set constant for bot userid

USERID = ARGV.shift if ARGV.count > 0 
MAGICKEY = ARGV.shift if ARGV.count > 0 

puts "#{USERID} #{MAGICKEY} #{Process.pid}"
puts "#{CODENAME} #{VERSION}"

class Neurobot

	include Syncuserlist, Digest, Backgroundloop, Eventstraps, Processantiidle, Processtriggers, Processpkgb, Processautobop

	attr_accessor	:client, :db

	def initialize
		punt
	end
	
	def punt

		# Create db handle
		
		# @db = Mysql::new(DBHOST, DBUSER, DBPASS, DBTABLE)
		
		@db = Mysql2::Client.new(:host => DBHOST, :username => DBUSER, :password => DBPASS, :encoding => 'utf8', :reconnect => true, :database => DBTABLE )
		# Create our instance variables

		@botData  = Hash.new
		@queue 	  = Array.new
		@tabledjs = Array.new
		@snagged  = 0		
	
		# Load the first pass of bot variables		

		jOutput = JSON.parse((URI.parse("http://www.neurobots.net/websockets/pull.php?bot_userid=#{USERID}&magic_key=#{MAGICKEY}")).read)
		
		#debugger
	
		@botData['authid'] = jOutput['bot_authid']
		@botData['roomid'] = jOutput['bot_roomid']
		@botData['ownerid'] = jOutput['owner_userid']
    @botData['running_timers'] =  []

	end
	
	def rehash(user)
		
		jOutput = JSON.parse((URI.parse("http://www.neurobots.net/websockets/pull.php?bot_userid=#{USERID}&magic_key=#{MAGICKEY}")).read)
		
		@errorcounts = {}
		@antiIdle = []
		@sayings = []
		@autobop_count = 0
		@votes = []
		@anti_idle_running = false

		@botData['authid'] = jOutput['bot_authid']
		@botData['roomid'] = jOutput['bot_roomid']
		@botData['ownerid'] = jOutput['owner_userid']
		@botData['ads'] = jOutput['adverts']
		@botData['triggers'] = jOutput['triggers']
		@botData['command_trigger'] = jOutput['command_trigger']
		@botData['events'] = jOutput['events']
		@botData['events'].pop
		@botData['triggers'].pop
		@botData['ads'].pop
		@botData['level1acl'] = []
		@botData['level2acl'] = []
		@botData['level3acl'] = []
		@botData['queue'] = false
		@botData['slide'] = false
		@botData['autodj'] = false
		@botData['stats'] = false
		@botData['autoReQueue'] = false
		@botData['alonedj'] = false
		@botData['auto_bop'] = false
		@botData['flags'] = jOutput['flags'].to_s
		@botData['queue'] = true if jOutput['start_queue'].to_i == 1
		@botData['slide'] = true if jOutput['start_slide'].to_i == 1
		@botData['autodj'] = true if jOutput['start_autodj'].to_i == 1
		@botData['stats'] = true if jOutput['start_stats'].to_i == 1
		@botData['autoReQueue'] = true if jOutput['switch_autorequeue'].to_i == 1
		@botData['alonedj'] = true if jOutput['switch_alonedj'].to_i == 1
    @botData['auto_bop'] = true if jOutput['auto_bop'].to_i == 1
		# @botData['autobop'] = true
		jOutput['blacklist'].pop
		@botData['blacklist'] = jOutput['blacklist'].map {|h| h['userid']}
		
		@aclCount = jOutput['acl'].count
		jOutput['acl'].pop
		jOutput['acl'].each { |acl|
        @botData['level1acl'].push(acl['userid']) if acl['access_level'] == "1"
        @botData['level2acl'].push(acl['userid']) if acl['access_level'] == "2"
        @botData['level3acl'].push(acl['userid']) if acl['access_level'] == "3"
		}
		
		('B'..'B').each do |pkg|
        @botData['pkg_'+pkg.downcase+'_data'] = jOutput['pkg_'+pkg.downcase+'_data'][0] if /#{pkg}/ =~ @botData['flags']
		end

		@tabledjs = @client.room.djs.to_a if @botData['queue']


		if jOutput['mods_to_lvl1'].to_i == 1
    	self.client.room.moderators.each do |mod|
      	@botData['level1acl'].push(mod.id)
      end
		end

		self.db.query("select * from bot_sayings_#{MAGICKEY}").each do |row|
    		@sayings.push(row['saying']);
    end
			
			flags = 'A'
			flags += 'B' if /B/ =~ @botData['flags']

		if user == nil
			self.client.room.say("#{CODENAME} #{VERSION}")
			self.client.room.say("[Triggers: #{@botData['triggers'].count}][Ads: #{@botData['ads'].count}][Events: #{@botData['events'].count}][Acls: #{jOutput['acl'].count}][Sayings: #{@sayings.count}][Packages: #{flags}]") 
			self.client.room.say("[#{@botData['triggers'].count} triggers][#{@botData['ads'].count} ads][#{@botData['events'].count} events]")
			self.client.room.say("[#{jOutput['acl'].count} acls][#{@sayings.count} sayings]")
			self.client.room.say("[ #{flags} ]") 
		else
			user.say("#{CODENAME} #{VERSION}")
			user.say("[Triggers: #{@botData['triggers'].count}][Ads: #{@botData['ads'].count}][Events: #{@botData['events'].count}][Acls: #{jOutput['acl'].count}][Sayings: #{@sayings.count}][Packages: #{flags}]")
		end

		# Ad Spooler
    
		@botData['running_timers'].each { |timer| timer.cancel }
    @botData['running_timers'] =  []
    @botData['ads'].each do |ad|
    	timer = EventMachine::PeriodicTimer.new(ad['delay']) do
      	Turntabler.run { client.room.say ad['message'] }
      end
      @botData['running_timers'].push(timer)
    end
    rescue JSON::ParserError, SocketError
	end

	def roomid
		@botData['roomid']
	end

	def authid
		@botData['authid']
	end
end


# Main
		
		# Start Eventmachine main loop
		
		bot = Neurobot.new		
		Turntabler.interactive
		Turntabler.run do

		# Start the client handle
		
			bot.client = Turntabler::Client.new('', '', :room => bot.roomid, :user_id => USERID, :auth => bot.authid, :reconnect => true, :reconnect_wait => 15)
			

		# Pull in all the information and spit out the startup
		
			bot.rehash(nil)

		# Sync the user database with the current room settings

			bot.syncUserList

		#	Start Auto dj watcher, alone dj watcher, and blacklist watcher

			bot.backgroundLoopInit			

			bot.trapEvents

		end # End Turntabler.run do

