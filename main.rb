require './authvaultix.rb'

AuthVaultix.new.Api(
  "Teamdeveloperxd",
  "5d36476ca4",
  "4e1d8a87787f8af61c5462d12ee16e1f06d53fe314c78e985571db65f0007178",
  "1.0"
)

puts "\nConnecting..."
AuthVaultix.new.Init

puts "\n1) Login"
puts "2) Register"
puts "3) License Login"
puts "4) Exit"
print "\nChoose: "
opt = gets.chomp

case opt
when '1'
  print "Username: "; u = gets.chomp
  print "Password: "; p = gets.chomp
  AuthVaultix.new.Login(u, p)
when '2'
  print "Username: "; u = gets.chomp
  print "Password: "; p = gets.chomp
  print "License: "; k = gets.chomp
  AuthVaultix.new.Register(u, p, k)
when '3'
  print "License: "; k = gets.chomp
  AuthVaultix.new.License(k)
else
  puts "Goodbye!"
end