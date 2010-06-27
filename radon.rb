#!/usr/bin/env ruby

require 'irc.rb'

class Radon < IRCBot
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
					when /^#{self.name}[:,] (.+)/
					# To radon...
						case $1.strip.downcase
							when /^ban word (.*?)$/
								@banned_words.push $1.downcase
								irc.send_msg "OK, #{username}. The next person to say #{$1} will be banned."
								return
							when /^ban phrase (.*)$/
								@banned_words.push $1.downcase
								irc.send_msg "OK, #{username}. The next person to say #{$1} will be banned."
								return
							# If it's irrelevant, ban them for five minutes
							else
								ban irc, username, 600
								return
						end
					when /^(.*)$/
						ban irc, username, 3600 if @banned_words.include? $1.downcase
				end
		end
	end
	
	def ban irc, username, time
		irc.send "KICK #{irc.channel} #{username} :NOT FUNNY" # if time == 0
		irc.send "MODE #{irc.channel} +b #{username}"
	end
	
	def name
		'radon'
	end
	
	def fullname
		"Radon"
	end
end

IRC.run 'rcnet.ath.cx', 6667, 'radon', '#isp', Radon.new
