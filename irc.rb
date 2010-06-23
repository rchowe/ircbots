#!/usr/bin/env ruby

require 'socket'

$SAFE = 1
$DEBUG = false

def debug_puts msg
	puts msg if $DEBUG == true
end

class IRC
	def initialize server, port, nick, channel, bot
		@server		= server
		@port		= port
		@nick		= nick
		@channel	= channel
		@bot		= bot
	end
	
	def send msg
		# Sends a message to the server
		debug_puts "--> #{msg}"
		@irc.send "#{msg}\n", 0
	end
	
	def connect
		# Connects to the IRC server
		@irc = TCPSocket.open @server, @port
		send "USER null null null :A Bot"
		send "NICK #{@nick}"
		send "JOIN #{@channel}"
	end
	
	def main_loop
		while true
			ready = select @irc, nil, nil, nil
			next unless ready
			for s in ready[0]
				if s == @irc
					return if @irc.eof
					s = @irc.gets
					handle_server_msg s
				end
			end
		end
	end
	
	def handle_server_msg msg
		case msg.strip
			when /^PING :(.+)$/i
				debug_puts "[SERVER PING]"
				send "PONG :#{$1}"
			when /^:(.+?)!(.+?)@(.+?)\sPRIVMSG\s.+\s:[\001]PING (.+)[\001]$/i
				debug_puts "[CTCP PING from #{$1}!#{$2}@#{$3}]"
				send "NOTICE #{$1} :\001PING #{$4}\001"
			when /^:(.+?)!(.+?)@(.+?)\sPRIVMSG\s.+\s:[\001]VERSION[\001]$/i
				puts "[ CTCP VERSION from #{$1}!#{$2}@#{$3} ]"
				send "NOTICE #{$1} :\001VERSION Ruby-irc v0.042\001"
			else
				@bot.handle_server_msg self, msg
		end
	end
	
	def self.run server, port, nick, channel, bot
		irc = IRC.new server, port, nick, channel, bot
		irc.connect
		
		begin
			irc.main_loop
		rescue Interrupt
		rescue Exception => detail
			puts detail.message
			print detail.backtrace.join '\n'
			retry
		end
	end
end

