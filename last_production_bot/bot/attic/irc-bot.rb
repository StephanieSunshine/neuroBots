#!/usr/local/bin/ruby

require 'ponder'
require 'eventmachine'
trigger = "nc1:"

EM.run {
$ircSocket = Ponder::Thaum.new do |config|
  config.nick   = 'Neuro-Contoller-'
  config.server = 'irc.freenode.net'
  config.port   = 6667
end

$ircSocket.on :connect do
  $ircSocket.join '#neurobots', 'Ponyo'
end

$ircSocket.on :channel, /#{trigger} status/ do |event_data|
  $ircSocket.message event_data[:channel], "Online" 
end

$ircSocket.on :channel, /#{trigger} restart/ do |event_data|
  $ircSocket.message event_data[:channel], "Restarting in 5"
	EventMachine::Timer.new(5) do
  		exit 0          
  	end
end

$ircSocket.connect

EventMachine::Timer.new(60) do
timer = EventMachine::PeriodicTimer.new(10) do
	$ircSocket.message "#neurobots", "Ping"
end
end
 }
