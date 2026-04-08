require './authvaultix.rb'

AuthVaultix.new.Api(
    "", # Application Name
    "", # Application OwnerID
    "", # Application Secret
    "1.0" # Applicaiton Version
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