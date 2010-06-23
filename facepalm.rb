#!/usr/bin/env ruby

require 'irc.rb'

class Facepalm < IRCBot
	def initialize
		@banned_words = []
	end
	
	def handle_server_msg irc, msg
		case msg
			when /^:(.+?)!(.+?)@(.+?)\sPRIVMSG\s(.+)\s:(.+)$/
			# Someone says something
				username = $1
				m = $5.strip
				case m
					when /^facepalm[:,] (.+)/
					# To facepalm...
						case $1.strip.downcase
							when /^ban word ([^\w]*?)$/
								@banned_words.push $1.downcase
								irc.send_msg "OK, #{username}. The next person to say #{$1} will be banned."
							when /^ban phrase (.*)$/
								@banned_words.push $1.downcase
								irc.send_msg "OK, #{username}. The next person to say #{$1} will be banned."
							# If it's irrelevant, ban them for five minutes
							else
								ban irc, username, 600
						end
					when /^(.*)$/
						ban irc, username, 3600 if @banned_words.include? $1.downcase
				end
		end
	end
	
	def ban irc, username, time
		irc.send "KICK #{irc.channel} #{username} You made me facepalm" # if time == 0
#		irc.send "MODE #{irc.channel} +b #{username}"
	end
	
	def name
		'facepalm'
	end
	
	def fullname
		"Facepalm"
	end
end

IRC.run 'rcnet.ath.cx', 6667, 'facepalm', '#isp', Facepalm.new
