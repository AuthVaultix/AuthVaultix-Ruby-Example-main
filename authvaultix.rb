require 'net/http'
require 'json'
require 'uri'
require 'base64'
require 'rbconfig'

module AuthVaultix

  class NetworkAgent
    def self.post(url, payload)
      uri = URI(url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = (uri.scheme == "https")
      
      request = Net::HTTP::Post.new(uri)
      request["Content-Type"] = "application/x-www-form-urlencoded"
      request["User-Agent"] = "AuthVaultixClient/1.0"
      request.body = URI.encode_www_form(payload)

      begin
        response = http.request(request)
        if response.code == "429"
          puts "You're connecting too fast, slow down."
          return nil
        end
        return JSON.parse(response.body)
      rescue => e
        puts "Request failed: #{e.message}"
        return nil
      end
    end
  end

  class PayloadBuilder
    def initialize(action_type)
      @payload = { "type" => action_type }
    end

    def with_context(app_name, owner_id, session_id)
      @payload["name"] = app_name
      @payload["ownerid"] = owner_id
      @payload["sessionid"] = session_id if session_id && !session_id.empty?
      self
    end

    def with_value(key, value)
      @payload[key] = value if value
      self
    end

    def compile
      @payload
    end
  end

  class SystemInfoCollector
    def self.windows?
      RbConfig::CONFIG['host_os'] =~ /mswin|mingw|cygwin/
    end

    def self.macos?
      RbConfig::CONFIG['host_os'] =~ /darwin/
    end

    def self.linux?
      RbConfig::CONFIG['host_os'] =~ /linux/
    end

    def self.get_os_version
      if windows?
        begin
          caption = `powershell -Command "(Get-CimInstance Win32_OperatingSystem).Caption" 2>nul`.strip
          caption = caption.sub("Microsoft ", "") if caption.start_with?("Microsoft ")
          version = `powershell -Command "(Get-CimInstance Win32_OperatingSystem).Version" 2>nul`.strip
          return "#{caption} (#{version})" unless caption.empty? || version.empty?
        rescue
        end
        "Windows"
      elsif macos?
        begin
          version = `sw_vers -productVersion 2>/dev/null`.strip
          return "macOS (#{version})" unless version.empty?
        rescue
        end
        "macOS"
      elsif linux?
        begin
          version = `uname -sr 2>/dev/null`.strip
          return version unless version.empty?
        rescue
        end
        "Linux"
      else
        "Unknown OS"
      end
    end

    def self.get_platform
      "native"
    end

    def self.get_device_type
      "Desktop"
    end

    def self.get_architecture
      if windows?
        ENV['PROCESSOR_ARCHITECTURE']&.upcase || "X64"
      else
        begin
          arch = `uname -m 2>/dev/null`.strip.upcase
          return arch unless arch.empty?
        rescue
        end
        "X64"
      end
    end

    def self.get_cpu_cores
      if windows?
        begin
          physical_cores = `powershell -Command "(Get-CimInstance Win32_Processor).NumberOfCores" 2>nul`.strip
          logical_processors = ENV['NUMBER_OF_PROCESSORS'] || "2"
          cores = physical_cores.empty? ? logical_processors : physical_cores
          return "#{cores} Cores / #{logical_processors} Threads"
        rescue
        end
        "2 Cores / 2 Threads"
      else
        logical = "2"
        begin
          if macos?
            logical = `sysctl -n hw.ncpu 2>/dev/null`.strip
          else
            logical = `nproc 2>/dev/null`.strip
          end
        rescue
        end
        "#{logical} Cores / #{logical} Threads"
      end
    end

    def self.get_ram_gb
      if windows?
        begin
          ram = `powershell -Command "[Math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB)" 2>nul`.strip
          return ram unless ram.empty?
        rescue
        end
        "0"
      elsif macos?
        begin
          bytes = `sysctl -n hw.memsize 2>/dev/null`.strip.to_i
          return (bytes / (1024 * 1024 * 1024)).to_str if bytes > 0
        rescue
        end
        "0"
      else
        begin
          kb = `grep MemTotal /proc/meminfo 2>/dev/null | awk '{print $2}'`.strip.to_i
          return (kb / (1024 * 1024)).to_s if kb > 0
        rescue
        end
        "0"
      end
    end
  end

  class AuthVaultixCore
    attr_accessor :app_name, :owner_id, :secret, :version, :session_id, :initialized, :current_user

    BASE_URL = "https://authvaultix.com/api/1.0/"

    def initialize(app_name, owner_id, secret, version)
      if [app_name, owner_id, secret, version].any? { |x| x.nil? || x.empty? }
        puts "Application not setup correctly."
        exit(1)
      end
      @app_name = app_name
      @owner_id = owner_id
      @secret = secret
      @version = version
      @session_id = nil
      @initialized = false
      @current_user = nil
    end

    def ensure_ready
      unless @initialized
        puts "SDK not initialized. Call init before using any API."
        exit(1)
      end
    end

    def hwid
      sid = `powershell -Command "[System.Security.Principal.WindowsIdentity]::GetCurrent().User.Value" 2>nul`
      sid = sid.strip
      sid.empty? ? "UNKNOWN_HWID" : sid
    rescue
      "UNKNOWN_HWID"
    end

    def init
      return true if @initialized

      payload = PayloadBuilder.new("init")
                .with_value("ver", @version)
                .with_value("name", @app_name)
                .with_value("ownerid", @owner_id)
                .compile

      resp = NetworkAgent.post(BASE_URL, payload)
      if resp.nil?
        puts "Init Error"
        exit(1)
      end

      if resp["success"]
        @session_id = resp["sessionid"]
        @initialized = true
        puts "Initialized Successfully! Session ID: #{@session_id}"
        true
      else
        puts "Init Failed: #{resp['message']}"
        exit(1)
      end
    end

    def authenticate_user(username, password)
      ensure_ready
      payload = PayloadBuilder.new("login")
                .with_context(@app_name, @owner_id, @session_id)
                .with_value("username", username)
                .with_value("pass", password)
                .with_value("hwid", hwid)
                .with_value("os", SystemInfoCollector.get_os_version)
                .with_value("platform", SystemInfoCollector.get_platform)
                .with_value("device", SystemInfoCollector.get_device_type)
                .with_value("architecture", SystemInfoCollector.get_architecture)
                .with_value("cpu_cores", SystemInfoCollector.get_cpu_cores)
                .with_value("ram", SystemInfoCollector.get_ram_gb)
                .compile

      resp = NetworkAgent.post(BASE_URL, payload)
      return false if resp.nil?

      if resp["success"]
        @current_user = resp["info"]
        @session_id = resp["sessionid"] if resp["sessionid"] && !resp["sessionid"].empty?
        puts "Logged in!"
        print_user_info
        true
      else
        puts "Login Failed: #{resp['message']}"
        false
      end
    end

    def validate_session
      ensure_ready
      return false if @session_id.nil?

      payload = PayloadBuilder.new("check")
                .with_context(@app_name, @owner_id, @session_id)
                .compile

      resp = NetworkAgent.post(BASE_URL, payload)
      return false if resp.nil?

      if resp["success"]
        puts "Session Valid!"
        true
      else
        puts "Session Invalid: #{resp['message']}"
        false
      end
    end

    def register_account(username, password, license, email)
      ensure_ready
      payload = PayloadBuilder.new("register")
                .with_context(@app_name, @owner_id, @session_id)
                .with_value("username", username)
                .with_value("pass", password)
                .with_value("key", license)
                .with_value("email", email)
                .with_value("hwid", hwid)
                .compile

      resp = NetworkAgent.post(BASE_URL, payload)
      return false if resp.nil?

      if resp["success"]
        @current_user = resp["info"]
        @session_id = resp["sessionid"] if resp["sessionid"] && !resp["sessionid"].empty?
        puts "Registered Successfully!"
        print_user_info
        true
      else
        puts "Register Failed: #{resp['message']}"
        false
      end
    end

    def license_access(license)
      ensure_ready
      payload = PayloadBuilder.new("license")
                .with_context(@app_name, @owner_id, @session_id)
                .with_value("key", license)
                .with_value("hwid", hwid)
                .compile

      resp = NetworkAgent.post(BASE_URL, payload)
      return false if resp.nil?

      if resp["success"]
        @current_user = resp["info"]
        @session_id = resp["sessionid"] if resp["sessionid"] && !resp["sessionid"].empty?
        puts "License Login Successful!"
        print_user_info
        true
      else
        puts "License Login Failed: #{resp['message']}"
        false
      end
    end

    def send_log(message)
      ensure_ready
      pcuser = ENV['USERNAME'] || 'Unknown'
      payload = PayloadBuilder.new("log")
                .with_context(@app_name, @owner_id, @session_id)
                .with_value("message", message)
                .with_value("pcuser", pcuser)
                .compile

      resp = NetworkAgent.post(BASE_URL, payload)
      return false if resp.nil?

      if resp["success"]
        true
      else
        puts "Log Failed: #{resp['message']}"
        false
      end
    end

    def retrieve_file(fileid)
      ensure_ready
      payload = PayloadBuilder.new("file")
                .with_context(@app_name, @owner_id, @session_id)
                .with_value("fileid", fileid)
                .compile

      resp = NetworkAgent.post(BASE_URL, payload)
      return nil if resp.nil?

      if resp["success"]
        begin
          decoded = Base64.decode64(resp["contents"])
          puts "Download successful"
          return decoded
        rescue
          puts "Base64 Decode Error"
          return nil
        end
      else
        puts "Download Failed: #{resp['message']}"
        nil
      end
    end

    def get_online_clients
      ensure_ready
      payload = PayloadBuilder.new("fetchonline")
                .with_context(@app_name, @owner_id, @session_id)
                .compile

      resp = NetworkAgent.post(BASE_URL, payload)
      return nil if resp.nil?

      if resp["success"]
        resp["users"]
      else
        puts "Fetch Online Failed: #{resp['message']}"
        nil
      end
    end

    def enforce_ban(reason)
      ensure_ready
      payload = PayloadBuilder.new("ban")
                .with_context(@app_name, @owner_id, @session_id)
                .with_value("reason", reason)
                .compile

      resp = NetworkAgent.post(BASE_URL, payload)
      return false if resp.nil?

      if resp["success"]
        puts "Banned successfully"
        true
      else
        puts "Ban Failed: #{resp['message']}"
        false
      end
    end

    def terminate_session
      ensure_ready
      payload = PayloadBuilder.new("logout")
                .with_context(@app_name, @owner_id, @session_id)
                .compile

      resp = NetworkAgent.post(BASE_URL, payload)
      if resp && resp["success"]
        @session_id = nil
        @initialized = false
        puts "Logged out successfully"
      else
        puts "Logout Error"
      end
    end

    def update_username(new_username)
      ensure_ready
      payload = PayloadBuilder.new("changeusername")
                .with_context(@app_name, @owner_id, @session_id)
                .with_value("newUsername", new_username)
                .compile

      resp = NetworkAgent.post(BASE_URL, payload)
      if resp && resp["success"]
        @session_id = nil
        @initialized = false
        puts "Username changed successfully. Please login again."
      else
        puts "Change Username Error"
      end
    end

    def verify_blacklist
      ensure_ready
      payload = PayloadBuilder.new("checkblacklist")
                .with_context(@app_name, @owner_id, @session_id)
                .with_value("hwid", hwid)
                .compile

      resp = NetworkAgent.post(BASE_URL, payload)
      return false if resp.nil?

      if resp["success"]
        true
      else
        puts "Client is blacklisted: #{resp['message']}"
        false
      end
    end

    def trigger_password_reset(username, email)
      ensure_ready
      payload = PayloadBuilder.new("forgot")
                .with_context(@app_name, @owner_id, @session_id)
                .with_value("username", username)
                .with_value("email", email)
                .compile

      resp = NetworkAgent.post(BASE_URL, payload)
      return false if resp.nil?

      if resp["success"]
        puts "Reset email sent successfully"
        true
      else
        puts "Forgot Password Failed: #{resp['message']}"
        false
      end
    end

    def apply_upgrade(username, license)
      ensure_ready
      payload = PayloadBuilder.new("upgrade")
                .with_context(@app_name, @owner_id, @session_id)
                .with_value("username", username)
                .with_value("key", license)
                .compile

      resp = NetworkAgent.post(BASE_URL, payload)
      return false if resp.nil?

      if resp["success"]
        puts "Upgrade successful"
        true
      else
        puts "Upgrade Failed: #{resp['message']}"
        false
      end
    end

    def fetch_global_variable(var_id)
      ensure_ready
      payload = PayloadBuilder.new("var")
                .with_context(@app_name, @owner_id, @session_id)
                .with_value("varid", var_id)
                .compile

      resp = NetworkAgent.post(BASE_URL, payload)
      return nil if resp.nil?

      if resp["success"]
        resp["message"]
      else
        puts "Fetch Global Var Failed: #{resp['message']}"
        nil
      end
    end

    def fetch_user_variable(var_name)
      ensure_ready
      payload = PayloadBuilder.new("getvar")
                .with_context(@app_name, @owner_id, @session_id)
                .with_value("var", var_name)
                .compile

      resp = NetworkAgent.post(BASE_URL, payload)
      return nil if resp.nil?

      if resp["success"]
        resp["response"]
      else
        puts "Fetch User Var Failed: #{resp['message']}"
        nil
      end
    end

    def update_user_variable(var_name, value)
      ensure_ready
      payload = PayloadBuilder.new("setvar")
                .with_context(@app_name, @owner_id, @session_id)
                .with_value("var", var_name)
                .with_value("data", value)
                .compile

      resp = NetworkAgent.post(BASE_URL, payload)
      return false if resp.nil?

      unless resp["success"]
        puts "Set User Var Failed: #{resp['message']}"
      end
      resp["success"]
    end

    def transmit_chat_message(message, channel)
      ensure_ready
      payload = PayloadBuilder.new("chatsend")
                .with_context(@app_name, @owner_id, @session_id)
                .with_value("message", message)
                .with_value("channel", channel)
                .compile

      resp = NetworkAgent.post(BASE_URL, payload)
      return false if resp.nil?

      if resp["success"]
        puts "Message sent."
        return true
      end

      if resp["code"] == 403 && resp["remaining_seconds"] > 0
        puts "Muted till #{resp['muted_until']} (wait #{resp['remaining_human']})"
      else
        puts "Chat Send Failed: #{resp['message']}"
      end
      false
    end

    def retrieve_chat_history(channel)
      ensure_ready
      payload = PayloadBuilder.new("chatfetch")
                .with_context(@app_name, @owner_id, @session_id)
                .with_value("channel", channel)
                .compile

      resp = NetworkAgent.post(BASE_URL, payload)
      return nil if resp.nil?

      if resp["success"]
        resp["messages"]
      else
        puts "Chat Fetch Failed: #{resp['message']}"
        nil
      end
    end

    private

    def format_time(unix)
      Time.at(unix.to_i).strftime("%Y-%m-%d %H:%M:%S")
    rescue
      unix.to_s
    end

    def format_timeleft(seconds)
      seconds = seconds.to_i
      d = seconds / 86400
      h = (seconds % 86400) / 3600
      m = (seconds % 3600) / 60
      "#{d}d #{h}h #{m}m"
    end

    def print_user_info
      return unless @current_user
      puts "\n=== User Data ==="
      puts "Username: #{@current_user['username']}"
      puts "IP: #{@current_user['ip']}" if @current_user['ip']
      puts "HWID: #{@current_user['hwid']}" if @current_user['hwid']
      puts "Created: #{format_time(@current_user['createdate'])}" if @current_user['createdate']
      puts "Last Login: #{format_time(@current_user['lastlogin'])}" if @current_user['lastlogin']

      if @current_user['subscriptions'].is_a?(Array) && !@current_user['subscriptions'].empty?
        puts "\nSubscriptions:"
        @current_user['subscriptions'].each_with_index do |sub, i|
          puts "[#{i + 1}] #{sub['subscription']} | Expiry: #{format_time(sub['expiry'])} | Timeleft: #{format_timeleft(sub['timeleft'])}"
        end
      end
      puts
    end
  end
end

class AuthVaultixClient
  def initialize(app_name, owner_id, secret, version)
    @core = AuthVaultix::AuthVaultixCore.new(app_name, owner_id, secret, version)
  end

  def init; @core.init; end
  def login(username, password); @core.authenticate_user(username, password); end
  def check; @core.validate_session; end
  def register(username, password, license, email = ""); @core.register_account(username, password, license, email); end
  def license_login(license); @core.license_access(license); end
  def log(message); @core.send_log(message); end
  def download(fileid); @core.retrieve_file(fileid); end
  def fetch_online; @core.get_online_clients; end
  def ban(reason); @core.enforce_ban(reason); end
  def logout; @core.terminate_session; end
  def change_username(new_username); @core.update_username(new_username); end
  def check_blacklist; @core.verify_blacklist; end
  def upgrade(username, license); @core.apply_upgrade(username, license); end
  def forgot_password(username, email); @core.trigger_password_reset(username, email); end
  def get_global_var(varid); @core.fetch_global_variable(varid); end
  def get_var(var_name); @core.fetch_user_variable(var_name); end
  def set_var(var_name, value); @core.update_user_variable(var_name, value); end
  def chat_send(message, channel); @core.transmit_chat_message(message, channel); end
  def chat_fetch(channel); @core.retrieve_chat_history(channel); end
end
