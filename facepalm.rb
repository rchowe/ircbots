#!/usr/bin/env ruby

require 'socket'

$SAFE = 1

class IRC
	def initialize server, port, nick, channel
		@server = server
		@port = port
		@nick = nick
		@channel = channel
		@banned_words = []
	end
	
	def send msg
		# Sends a message to the server and prints it to the screen
		puts "--> #{msg}"
		@irc.send( "#{msg}\n", 0 )
	end
	
	def connect
		# Connect to the IRC server
		@irc = TCPSocket.open @server, @port
		send "USER facepalm rcnet.ath.cx rcnet.ath.cx :Durr Bot"
		send "NICK #{@nick}"
		send "JOIN #{@channel}"
	end
	
	def evaluate s
		# Make sure we have a valid expression, and evaluate it if we do, otherwise
		# return an error message
		if s =~ /^[-+*\/\d\s\eE.()]*$/ then
			begin
				s.untaint
				return eval( s ).to_s
			rescue Exception => detail
				puts detail.message
			end
		end
		
		return "Error"
	end
	
	def handle_server_input(s)
		# This isn't at all efficient, but it shows what we can do with Ruby
		# (Dave Thomas calls this construct "a multiway if on steroids")
		case s.strip
			when /^PING :(.+)$/i
				puts "[ Server ping ]"
				send "PONG :#{$1}"
			when /^:(.+?)!(.+?)@(.+?)\sPRIVMSG\s.+\s:[\001]PING (.+)[\001]$/i
				puts "[ CTCP PING from #{$1}!#{$2}@#{$3} ]"
				send "NOTICE #{$1} :\001PING #{$4}\001"
			when /^:(.+?)!(.+?)@(.+?)\sPRIVMSG\s.+\s:[\001]VERSION[\001]$/i
				puts "[ CTCP VERSION from #{$1}!#{$2}@#{$3} ]"
				send "NOTICE #{$1} :\001VERSION Ruby-irc v0.042\001"
			when /^:(.+?)!(.+?)@(.+?)\sPRIVMSG\s(.+)\s:EVAL (.+)$/i
				puts "[ EVAL #{$5} from #{$1}!#{$2}@#{$3} ]"
				send "PRIVMSG #{(($4==@nick)?$1:$4)} :#{evaluate($5)}"
			when /^:(.+?)!(.+?)@(.+?)\sPRIVMSG\s(.+)\s:facepalm, ban word (.+)$/i
				send "PRIVMSG #isp :OK, #{$1}. Anyone who says '#{$5}' will be kicked and banned."
			else
				puts s
		end
	end
	
	def main_loop
		# Just keep on going until we disconnect
		while true
			ready = select [@irc, $stdin], nil, nil, nil
			next unless ready
			for s in ready[0]
				if s == $stdin
					return if $stdin.eof
					s = $stdin.gets
					send s
				elsif s == @irc
					return if @irc.eof
					s = @irc.gets
					handle_server_input s
				end
			end
		end
	end
end

# The main process
# If we get an exception, print it out and keep going
irc = IRC.new 'rcnet.ath.cx', 6667, 'facepalm', '#isp'
irc.connect

begin
	irc.main_loop
rescue Interrupt
rescue Exception => detail
	puts detail.message
	print detail.backtrace.join( '\n' )
	retry
end
