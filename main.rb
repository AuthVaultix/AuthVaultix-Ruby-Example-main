require './authvaultix.rb'


app = AuthVaultixClient.new(
    "", # Application Name
    "", # Application OwnerID
    "", # Application Secret
    "1.0" # Application Version
)


puts "Connecting..."
app.init

loop do
  puts "\n[1] Login"
  puts "[2] Register"
  puts "[3] License Login"
  puts "[4] Upgrade"
  puts "[5] Forgot Password"
  puts "[6] Exit"
  print "\nChoose option: "
  opt = gets.chomp

  case opt
  when '1'
    print "Username: "; u = gets.chomp
    print "Password: "; p = gets.chomp
    app.login(u, p)
  when '2'
    print "Username: "; u = gets.chomp
    print "Password: "; p = gets.chomp
    print "License: "; k = gets.chomp
    app.register(u, p, k, "")
  when '3'
    print "License: "; k = gets.chomp
    app.license_login(k)
  when '4'
    print "Username: "; u = gets.chomp
    print "License: "; k = gets.chomp
    app.upgrade(u, k)
  when '5'
    print "Username: "; u = gets.chomp
    print "Email: "; e = gets.chomp
    app.forgot_password(u, e)
  when '6'
    puts "Goodbye!"
    break
  else
    puts "Invalid option!"
  end
end
