require 'net/http'
require 'json'
require 'uri'
require 'date'

class AuthVaultix
  # ======================================================
  # 🔹 Core App Variables
  # ======================================================
  AppInitialized = String.new("no")
  SessionID     = String.new("none")
  Name          = String.new("")
  OwnerID       = String.new("")
  Secret        = String.new("")
  Version       = String.new("")

  BASE_URL = "https://api.authvaultix.com/api/1.2/" # ✅ Single Base URL here

  AppInfo = { "name" => "", "version" => "" }
  UserData = {}

  # ======================================================
  # 🔹 Set API Credentials
  # ======================================================
  def Api(name, ownerid, secret, version)
    if [name, ownerid, secret, version].any?(&:empty?)
      puts "❌ Missing application credentials."
      exit
    end
    Name.replace(name)
    OwnerID.replace(ownerid)
    Secret.replace(secret)
    Version.replace(version)
  end

  # ======================================================
  # 🔹 Init Function
  # ======================================================
  def Init
    payload = {
      "type" => "init",
      "name" => Name,
      "ownerid" => OwnerID,
      "secret" => Secret,
      "ver" => Version
    }

    resp = send_request("#{BASE_URL}", payload)
    if resp["success"]
      AppInitialized.replace("yes")
      SessionID.replace(resp["sessionid"])
      AppInfo["name"] = resp.dig("appinfo", "name")
      AppInfo["version"] = resp.dig("appinfo", "version")
    else
      error_exit(resp["message"])
    end
  end

  # ======================================================
  # 🔹 Login Function
  # ======================================================
  def Login(username, password)
    check_init
    payload = {
      "type" => "login",
      "sessionid" => SessionID,
      "username" => username,
      "pass" => password,
      "hwid" => hwid,
      "name" => Name,
      "ownerid" => OwnerID
    }
    resp = send_request("#{BASE_URL}", payload)
    handle_auth_response(resp, "✅ Logged in!")
  end

  # ======================================================
  # 🔹 Register Function
  # ======================================================
  def Register(username, password, license)
    check_init
    payload = {
      "type" => "register",
      "sessionid" => SessionID,
      "username" => username,
      "pass" => password,
      "key" => license,
      "hwid" => hwid,
      "name" => Name,
      "ownerid" => OwnerID
    }
    resp = send_request("#{BASE_URL}", payload)
    handle_auth_response(resp, "✅ Registered Successfully!")
  end

  # ======================================================
  # 🔹 License Login Function
  # ======================================================
  def License(license)
    check_init
    payload = {
      "type" => "license",
      "sessionid" => SessionID,
      "key" => license,
      "hwid" => hwid,
      "name" => Name,
      "ownerid" => OwnerID
    }
    resp = send_request("#{BASE_URL}", payload)
    handle_auth_response(resp, "✅ License Login Successful!")
  end

  # ======================================================
  # 🔹 Internal Helper: Send POST request
  # ======================================================
  def send_request(url, data)
    uri = URI(url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = (uri.scheme == "https")

    request = Net::HTTP::Post.new(uri)
    request["Content-Type"] = "application/x-www-form-urlencoded"
    request.body = URI.encode_www_form(data)

    response = http.request(request)
    begin
      JSON.parse(response.body)
    rescue
      puts "❌ Invalid JSON from server\n#{response.body}"
      exit
    end
  end

  # ======================================================
  # 🔹 Handle Auth Responses
  # ======================================================
  def handle_auth_response(resp, success_msg)
    if resp["success"]
      UserData.replace(resp["info"])
      puts success_msg
      print_user_info
    else
      error_exit(resp["message"])
    end
  end

  # ======================================================
  # 🔹 Display User Info
  # ======================================================
  def print_user_info
    puts "\n👤 User Info:"
    puts " Username: #{UserData['username']}"
    puts " IP: #{UserData['ip']}" if UserData['ip']
    puts " HWID: #{UserData['hwid']}" if UserData['hwid']
    puts " Created: #{format_time(UserData['createdate'])}" if UserData['createdate']

    if UserData['subscriptions'].is_a?(Array)
      puts "\n Subscriptions:"
      UserData['subscriptions'].each do |sub|
        puts "  → #{sub['subscription']} | Expiry: #{format_time(sub['expiry'])} | Left: #{sub['timeleft']}s"
      end
    end
    puts
  end

  # ======================================================
  # 🔹 Utility Helpers
  # ======================================================
  def hwid
    sid = `wmic useraccount where name='%username%' get sid /value 2>nul`
    sid = sid.gsub("SID=", "").strip
    sid.empty? ? "UNKNOWN_HWID" : sid
  rescue
    "UNKNOWN_HWID"
  end

  def check_init
    unless AppInitialized == "yes"
      error_exit("App not initialized. Run Init first.")
    end
  end

  def format_time(unix)
    Time.at(unix.to_i).strftime("%d-%m-%Y %H:%M:%S")
  end

  def error_exit(msg)
    puts "❌ Error: #{msg}"
    exit
  end
end
