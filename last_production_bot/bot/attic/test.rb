#!/var/lib/openshift/445b548ca10d4d3a92a0b73cce110875/app-root/data/.rvm/rubies/ruby-1.9.3-p125/bin/ruby

#       Basic requires needed to make this possible

require 'rubygems'
require 'turntabler'
require 'monitor'
require 'eventmachine'
require 'em-websocket'
require 'json'
require 'open-uri'
require 'pp'

$stdout.sync = true

abort "No magic key in envrioment variable" if !ENV.include? 'MAGICKEY'
abort "No userid in envrioment variable" if !ENV.include? 'BOTUSERID'

$botData = {
                "userid" => ENV['BOTUSERID'],
                "authid" => "",
                "magicKey" => ENV['MAGICKEY'],
                "ownerid" => "",
                "roomid" => "",
                "ads" => [],
                "triggers" => [],
                "blacklist" => [],
                "level3acl" => [],
                "level2acl" => [],
                "level1acl" => [],
                "command_trigger" => "",
}


def rehash
$jOutput = JSON.parse((URI.parse("http://www.neurobots.net/websockets/pull.php?bot_userid=#{$botData['userid']}&magic_key=#{$botData['magicKey']}")).read)
$botData['authid'] = $jOutput['bot_authid']
$botData['roomid'] = $jOutput['bot_roomid']
$botData['ownerid'] = $jOutput['owner_userid']
$botData['ads'] = $jOutput['adverts']
$botData['triggers'] = $jOutput['triggers']
$botData['blacklist'] = $jOutput['blacklist']
$botData['command_trigger'] = $jOutput['command_trigger']
$botData['ads'].pop
$botData['triggers'].pop
$botData['blacklist'].pop
end

rehash

pp $botData

$botData['ads'].each do |ad|
	puts "#{ad['message']} delay #{ad['delay']}"	
	end

