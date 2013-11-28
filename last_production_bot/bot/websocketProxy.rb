#!/usr/bin/env ruby

require 'rubygems'
require 'eventmachine'
require 'em-websocket'
require 'base64'

log = ""
$logOn = true
ip = "0.0.0.0"
$wsHandle = ""
#ip = ENV['OPENSHIFT_INTERNAL_IP'] if ENV.include? 'OPENSHIFT_INTERNAL_IP'

#abort "No bot port in envrioment variable" if !ENV.include? 'BOTPORT'
#abort "No magic key in envrioment variable" if !ENV.include? 'MAGICKEY'
#abort "No userid in envrioment variable" if !ENV.include? 'BOTUSERID'

botPort = ARGV[2]
magicKey = ARGV[1]
botUserid = ARGV[0]
$spoolerPid = -1
$spoolerHandler = nil
$websocket_open = false

puts "#{ip} #{botPort} #{botUserid} #{magicKey}"

Signal.trap("TERM") do
  Process.kill("TERM",$spoolerPid.to_i) if $spoolerPid.to_i > 0
  exit
end

module RubyCounter
  def post_init
    # count up to 5
  end
  def receive_data data
    if $spoolerPid == -1 
		$spoolerPid = data
		puts "Bot Pid: "+$spoolerPid.to_s
	else
		logLine = Base64.encode64(data).gsub("\n",'')
    		$wsHandle.send("Log|#{logLine}") if $logOn && $websocket_open
	end 
end
  def unbind

    puts "ruby died with exit status: #{get_status.exitstatus}"
    EventMachine.add_timer(10){ $spoolerHandler = EventMachine.popen("./main.rb #{botUserid} #{magicKey} #{botPort} ", RubyCounter) }
    uptime = `date +%s`.to_i
    $spoolerPid = -1
    $wsHandle.send("Uptime|"+(`date +%s`.to_i - uptime).to_s) if $websocket_open
  end
end

EM.run {
   Dir.chdir(File.expand_path('~/bot/current'))
   puts `pwd`
   $spoolerHandler = EventMachine.popen("./main.rb #{botUserid} #{magicKey} #{botPort}", RubyCounter) 
   uptime = `date +%s`.to_i
  
   EM::WebSocket.run(:host => ip, :port => botPort.to_i, :debug => false) do |ws|
   
  EventMachine.add_periodic_timer(90) { $wsHandle.send("Uptime|"+(`date +%s`.to_i - uptime).to_s) }
   ws.onopen { |handshake|
     $websocket_open = true
     $wsHandle = ws
     ws.send "Hello #{botPort} here"
     ws.send("Uptime|"+(`date +%s`.to_i - uptime).to_s) 
    }
 
   ws.onmessage { |msg|
    case msg
	when /^log=on$/
		ws.send "Log On"
		$logOn = true
	when /^log=off$/
		ws.send "Log Off"
		$logOn = false
	when /^restart$/
		Process.kill("USR2",pid)
	when /^die$/
		Process.kill("TERM",pid)
		exit
	end

    }
    ws.onclose {
      puts "WebSocket closed"
      $websocket_open = false
    }
    ws.onerror { |e|
      puts "Error: #{e.message}"
    }
  end
}
