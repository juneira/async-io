# Copyright, 2017, by Samuel G. D. Williams. <http://www.codeotaku.com>
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

require_relative 'socket'

module Async
	module IO
		class Address < Struct.new(:specification, :options)
			include ::Socket::Constants
			include Comparable
			
			class << self
				def tcp(*args, **options)
					self.new([:tcp, *args], **options)
				end
				
				def udp(*args, **options)
					self.new([:udp, *args], **options)
				end
				
				def unix(*args, **options)
					self.new([:unix, *args], **options)
				end
				
				def each(specifications, &block)
					specifications.each do |specification|
						if specification.is_a? self
							yield self
						else
							# Perhaps detect options here?
							yield self.new(specification)
						end
					end
				end
			end
			
			def initialize(specification, **options)
				super(specification, options)
			end
			
			def == other
				self.to_sockaddr == other.to_sockaddr
			end
			
			def <=> other
				self.to_sockaddr <=> other.to_sockaddr
			end
			
			def to_sockaddr
				addrinfo.to_sockaddr
			end
			
			# This is how addresses are internally converted, e.g. within `Socket#sendto`.
			alias to_str to_sockaddr
			
			def socktype
				addrinfo.socktype
			end
			
			# Preferred accessor for socket type.
			alias type socktype
			
			def afamily
				addrinfo.afamily
			end
			
			# Preferred accessor for address family.
			alias family afamily
			
			# def connect? accept? DatagramHandler StreamHandler
			
			def bind(&block)
				case specification
				when Addrinfo
					Socket.bind(specification, **options, &block)
				when Array
					Socket.bind(Addrinfo.send(*specification), **options, &block)
				when ::BasicSocket
					yield Socket.new(specification)
				when BasicSocket
					yield specification
				else
					raise ArgumentError, "Not sure how to bind to #{specification}!"
				end
			end
			
			def accept(&block)
				backlog = self.options.fetch(:backlog, SOMAXCONN)
				
				bind do |socket|
					socket.listen(backlog)
					socket.accept_each(&block)
				end
			end
			
			def connect(&block)
				case specification
				when Addrinfo, Array
					Socket.connect(self, &block)
				when ::BasicSocket
					yield Async::IO.try_convert(specification)
				when BasicSocket
					yield specification
				else
					raise ArgumentError, "Not sure how to bind to #{specification}!"
				end
			end
			
			private
			
			def addrinfo
				@addrinfo ||= case specification
					when Addrinfo
						specification
					when Array
						Addrinfo.send(*specification)
					when ::BasicSocket
						specification.local_address
					when BasicSocket
						specification.local_address
				else
					raise ArgumentError, "Not sure how to convert #{specification} into address!"
				end
			end
		end
	end
end
