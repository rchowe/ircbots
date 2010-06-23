#!/usr/bin/env ruby

require 'socket'

$SAFE = 1

class IRC
	def initialize server, port, nick, channel
		@name = 'carbon'
		@server = server
		@port = port
		@nick = nick
		@channel = channel
		@memory = {}
	end
	
	def send msg
		# Sends a message to the server and prints it to the screen
		puts "--> #{msg}"
		@irc.send( "#{msg}\n", 0 )
	end
	
	def connect
		# Connect to the IRC server
		@irc = TCPSocket.open @server, @port
		send "USER #{@name} rcnet.ath.cx rcnet.ath.cx :Durr Bot"
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
			when /^:(.+?)!(.+?)@(.+?)\sPRIVMSG\s(.+)\s:#{@name}[,:](.+)$/i
				username = $1
				# These are the carbon verbs
				case $5.strip
					when /^remember (.+)? (is|are) (.+)$/
						puts "B"
						send_msg "OK, #{username}, remembering #{$1} as #{$3}."
						@memory[$1.downcase] = $3
					when /^[hH]ello$/
						send_msg "Hi, #{username}!"
				end
			when /^:(.+?)!(.+?)@(.+?)\sPRIVMSG\s(.+)\s:(.+)$/i
				return unless @memory.has_key? $5.downcase
				reply = @memory[$5.downcase]
				return if reply.nil? or $5.nil?
				reply = reply.gsub( /\$someone/, random_user )
				send_msg reply if @memory.has_key? $5.downcase
			else
				puts s
		end
	end
	
	def random_user
		usernames = []
		send "NAMES"
		ready = select [@irc, $stdin], nil, nil, nil
			2.times do
				return @name unless ready
				for s in ready[0]
					if s == @irc
						return @name if @irc.eof
						s = @irc.gets
						if /^:(.+?)\s353\s(.+?)\s=\s(.+?)\s:((.+?)\w)+/.match(s)
							usernames = $4.split ' '
						end
					end
				end
			end
		return @name if @usernames.nil? or @usernames.empty?
		return @usernames.sort_by{ rand }.slice(0...1)
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
	
	def send_msg msg
		t = Thread.new do
			sleep( 0.1 + (rand(60) * 0.01))
			send "PRIVMSG #{@channel} :#{msg}"
		end
		
		t.join
	end
end

# The main process
# If we get an exception, print it out and keep going
irc = IRC.new 'rcnet.ath.cx', 6667, 'carbon', '#isp'
irc.connect

begin
	irc.main_loop
rescue Interrupt
	irc.send_msg "NOOOOOOO!!!!"
rescue Exception => detail
	puts detail.message
	print detail.backtrace.join( '\n' )
	retry
end
