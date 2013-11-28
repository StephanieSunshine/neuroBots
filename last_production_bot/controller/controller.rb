#!/usr/bin/env ruby

require 'rubygems'
require 'base32'
require 'sinatra'
require 'mysql2'
require 'json'
require 'ap'
require 'sys/proctable'
#require 'turntabler'

include Sys

PHK = 'LJaETkMFyHCGVBFHU3uDjelMoVra6qL7rIEgHZdecDjcRXNN2hAjHWHh7n3Y8T88qKxCsjx7dk1T3ccyNKQ'
PREFIX = '/controller'
THREAD = `ps -aef | grep #{Process.pid}| awk '{print $11;}'`.scan(/\d/).first.to_i
# Classes
DBHOST = "db.neurobots.net"
DBUSER=''
DBPASS=''


class App 
	attr_accessor :pid, :type, :id, :mc, :port, :botlist
	
	def initialize(pid, type, id, mc)
		self.pid = pid
		self.type = type
		self.id = id
		self.mc = mc
		self.botlist = Hash.new
	end
end

# Functions

# Prove the key is good
def valid_key(id,magickey)
  # db = Mysql2::new(DBHOST, ENV['DBUSER'], ENV['DBPASS'], "neurobots")
  db = Mysql2::Client.new(:host => DBHOST, :username => DBUSER, :password => DBPASS, :database => "neurobots", :reconnect => true)
  db.query("select id from users where magic_key='#{magickey}' AND bot_userid='#{id}'").each do |row|
		return true
	end
		return false
end

def get_port(id)
  key = ""
  db = Mysql2::Client.new(:host => DBHOST, :username => DBUSER, :password => DBPASS, :database => "neurobots", :reconnect => true)
  db.query("select id from users where bot_userid='#{id}'").each do |row|
    key = row['id'].to_i + 30100
  end
  return key
end

# Pull the key for the backdoor
def get_key(id)
  $stderr.puts("get_key(#{id})")
	key = ""
 	db = Mysql2::Client.new(:host => DBHOST, :username => DBUSER, :password => DBPASS, :database => "neurobots", :reconnect => true)
	db.query("select magic_key from users where bot_userid='#{id}'").each do |row|
		key = row['magic_key']
	end
	$stderr.puts("Got key #{key}")
	return key
end

# Start bot
def start_bot(id,magickey)
	$stderr.puts("start_bot(#{id},#{magickey})")
	# make sure the bot isn't running and then start it if it's not
	found = false
	get_ps.each { |ps| found = true if ps.id == id }
	if(!found)
		`cd ~/bot/current; nohup ./websocketProxy.rb #{id} #{magickey} #{get_port(id)} > /dev/null &`
		return "1"
	end
		return "0"
end

# Stop bot
def stop_bot(id,magickey)
	found = false
	get_ps.each do |ps| 
		found = true if ps.id == id
		Process.kill('SIGKILL', ps.pid) if ps.id == id
	end
	return "1" if found
	return "0" 
end

# Status
def c_status(id,magickey)
	puts "c_status started #{id} #{magickey}"
  found = false
  get_ps.each do |ps|
  	found = true if ps.id == id
	end
  return "1" if found
  return "0"
end

# Get usable process list
def get_ps
  ps_list = []
	ProcTable.ps do |process| 
		#output += PP.pp(process,"") if process.comm.(/ruby/) 
		if process.comm.match(/ruby/)
			type  = ''
			type  = "ws" if process.cmdline.match(/websocketProxy.rb/)
			type  = "bc" if process.cmdline.match(/main.rb/)
			# "#{pid} #{type} #{botid} #{magic}\n" if type != ""
			$stderr.puts("get_ps running")
			if type != ''
		      breakout = process.cmdline.scan(/^.+rb (\w+)\s(\w+)\s(\w+).+$/)[0] 
			    # "#{pid} #{type} #{botid} #{magic}\n" if type != ""
			    $stderr.puts("process commandline: #{process.cmdline}")
				  $stderr.puts("botuserid: #{breakout[0]}")
				  ps_list.push(App.new(process.pid, type, breakout[0], breakout[1] )) 
			end
	end 
end
return ps_list
end

# Lookups

class MyApp < Sinatra::Base

	attr_accessor :botlist

get "#{PREFIX}/" do
	"Controller #{THREAD} Online"
end

# Backdoor Start
get "#{PREFIX}/#{PHK}/start/:id" do |id|
	"Backdoor start called with id #{id} magic key: #{get_key(id)}"
	return start_bot(id,get_key(id))
end

# Backdoor Stop
get "#{PREFIX}/#{PHK}/stop/:id" do |id|
	"Backdoor stop called with id #{id}"
	return stop_bot(id,get_key(id))
end


# Backdoor Status
get "#{PREFIX}/#{PHK}/status/:id" do |id|
	"Backdoor status called with id #{id}"
	return c_status(id,get_key(id))
end

# Backdoor Console
get "#{PREFIX}/#{PHK}/console" do |id|
#  "Backdoor status called with id #{id}"
#  return c_status(id,get_key(id))
output = ""
get_ps.each do |bot|
	if bot.type = "bc"
	output += "#{bot.id} Stop<br />"
	end
end
return output
end

# Global stats
get "#{PREFIX}/status" do
	output  = "Controller stats\n"
	build_for_json = []
	get_ps.each do |process|
		build_for_json.push([THREAD, process.pid, process.id, get_port(process.id)]) if process.type == "bc"
	end

	return JSON.dump(build_for_json)
end

# Start
get "#{PREFIX}/start/:hash" do |hash|
	id, key = JSON.parse(Base32.decode(hash))
	"Start called with id #{id} and hash of #{key}"
	return start_bot(id,key) if valid_key(id,key)
  return 0
end

# Stop
get "#{PREFIX}/stop/:hash" do |hash|
  id, key = JSON.parse(Base32.decode(hash))
  "Stop called with id #{id} and hash of #{key}"
	return stop_bot(id,key) if valid_key(id,key)
	return 0
end

# Status
get "#{PREFIX}/status/:hash" do |hash|
  id, key = JSON.parse(Base32.decode(hash))
  "Status called with id #{id} and hash of #{key}"
  return c_status(id,key)
end

end






