require 'zlib'
require 'rack/request'
require 'rack/response'
require 'rack/utils'
require 'time'

class GitoliteHttpController < ApplicationController

  # prevents login action to be filtered by check_if_login_required application scope filter
  skip_before_filter :check_if_login_required, :verify_authenticity_token

  before_filter :authenticate

  def index()

    @request = Rack::Request.new(request.env)

    command, path, @requested_file, @rpc = match_routing

    return render_method_not_allowed if command == 'not_allowed'
    return render_not_found if !command

    puts "###### AUTHENTICATED ######"
    puts "repo_dir  : #{@repo_dir}"
    puts "is_push   : #{@is_push}"
    puts "user_name : #{@user.login}"
    puts "command   : #{command}"
    puts "##########################"

    Dir.chdir(@repo_dir) do
      self.method(command).call()
    end

  end

  private

  def authenticate

    query_valid = false
    authentication_valid = true

    @is_push = (params[:path] == "git-receive-pack")
    @repo_dir = "#{GitoliteConfig.repository_absolute_base_path}/#{params[:repo_path]}"

    puts "###### AUTHENTICATION ######"
    puts "repo_dir : #{@repo_dir}"
    puts "is_push  : #{@is_push}"
    puts "############################"

    if (@repository = Repository.find_by_url(@repo_dir)) && @repository.is_a?(Repository::Git)
      if @project = @repository.project
        #~ if @repository.extra[:git_http] == 2 || (@repository.extra[:git_http] == 1 && is_ssl?)
          query_valid = true
          allow_anonymous_read = @project.is_public
          if @is_push || (!allow_anonymous_read)
            authentication_valid = false
            authenticate_or_request_with_http_basic do |login, password|
              user = User.find_by_login(login);
              if user.is_a?(User)
                if user.allowed_to?( :commit_access, @project ) || ((!@is_push) && user.allowed_to?( :view_changesets, @project ))
                  authentication_valid = user.check_password?(password)
                  @user = user
                end
              end
              authentication_valid
            end
          end
        #~ end
      end
    end

    #if authentication failed, error already rendered
    #so, just render case where user queried a project
    #that's nonexistant or for which smart http isn't active
    if !query_valid
      render_not_found
    end

    return query_valid && authentication_valid
  end

  SERVICES = [
    ["POST", 'service_rpc',      "/#{GitoliteConfig.gitolite_smart_http_prefix}/(.*?)/git-upload-pack$",  'upload-pack'],
    ["POST", 'service_rpc',      "/#{GitoliteConfig.gitolite_smart_http_prefix}/(.*?)/git-receive-pack$", 'receive-pack'],

    ["GET",  'get_info_refs',    "/#{GitoliteConfig.gitolite_smart_http_prefix}/(.*?)/info/refs$"],
    ["GET",  'get_text_file',    "/#{GitoliteConfig.gitolite_smart_http_prefix}/(.*?)/HEAD$"],
    ["GET",  'get_text_file',    "/#{GitoliteConfig.gitolite_smart_http_prefix}/(.*?)/objects/info/alternates$"],
    ["GET",  'get_text_file',    "/#{GitoliteConfig.gitolite_smart_http_prefix}/(.*?)/objects/info/http-alternates$"],
    ["GET",  'get_info_packs',   "/#{GitoliteConfig.gitolite_smart_http_prefix}/(.*?)/objects/info/packs$"],
    ["GET",  'get_text_file',    "/#{GitoliteConfig.gitolite_smart_http_prefix}/(.*?)/objects/info/[^/]*$"],
    ["GET",  'get_loose_object', "/#{GitoliteConfig.gitolite_smart_http_prefix}/(.*?)/objects/[0-9a-f]{2}/[0-9a-f]{38}$"],
    ["GET",  'get_pack_file',    "/#{GitoliteConfig.gitolite_smart_http_prefix}/(.*?)/objects/pack/pack-[0-9a-f]{40}\\.pack$"],
    ["GET",  'get_idx_file',     "/#{GitoliteConfig.gitolite_smart_http_prefix}/(.*?)/objects/pack/pack-[0-9a-f]{40}\\.idx$"],
  ]

  def initialize()
    @config = {
      :project_root => '/data/git-repositories/jbox/repositories',
      :upload_pack => true,
      :receive_pack => true,
    }
  end

  # ---------------------------------
  # actual command handling functions
  # ---------------------------------

  def service_rpc
    return render_no_access if !has_access(@rpc, true)
    input = read_body

    self.response.headers["Content-Type"] = "application/x-git-%s-result" % @rpc
    self.response.status = 200

    command = git_command("#{@rpc} --stateless-rpc .")

    puts "###### SERVICE RPC ######"
    puts "command    : #{command}"
    #~ puts "input data : #{input}"
    puts "#########################"

    IO.popen(command, File::RDWR) do |pipe|
      pipe.write(input)
      while !pipe.eof?
        block = pipe.read() # 8M at a time
        self.response_body = Enumerator.new do |y|
          y << block.to_s
        end
      end
    end

  end

  def get_info_refs
    service_name = get_service_type

    if has_access(service_name)
      command = git_command("#{service_name} --stateless-rpc --advertise-refs .")
      refs = %x[#{command}]
      content_type = "application/x-git-#{service_name}-advertisement"

      self.response.status = 200
      self.response.headers["Content-Type"] = content_type
      hdr_nocache

      puts "###### GET INFO REFS ######"
      puts "command      : #{command}"
      puts "refs         : #{refs}"
      puts "content_type : #{content_type}"
      puts "service_name : #{service_name}"
      puts "###########################"

      self.response_body = Enumerator.new do |y|
        y << pkt_write("# service=git-#{service_name}\n")
        y << pkt_flush
        y << refs
      end

    else
      dumb_info_refs
    end
  end

  def dumb_info_refs
    update_server_info
    internal_send_file(@requested_file, "text/plain; charset=utf-8", hdr_nocache)
  end

  def get_info_packs
    # objects/info/packs
    internal_send_file(@requested_file, "text/plain; charset=utf-8", hdr_nocache)
  end

  def get_loose_object
    internal_send_file(@requested_file, "application/x-git-loose-object", hdr_cache_forever)
  end

  def get_pack_file
    internal_send_file(@requested_file, "application/x-git-packed-objects", hdr_cache_forever)
  end

  def get_idx_file
    internal_send_file(@requested_file, "application/x-git-packed-objects-toc", hdr_cache_forever)
  end

  def get_text_file
    internal_send_file(@requested_file, "text/plain", hdr_nocache)
  end

  # ------------------------
  # logic helping functions
  # ------------------------

  def match_routing
    cmd = nil
    path = nil
    SERVICES.each do |method, handler, match, rpc|
      if m = Regexp.new(match).match(@request.path_info)
        return ['not_allowed'] if method != @request.request_method
        cmd = handler
        path = m[1]
        file = @request.path_info.sub("#{GitoliteConfig.gitolite_smart_http_prefix}/#{path}/", '')

        puts "###### ROUTING ######"
        puts "path      : #{path}"
        puts "path info : #{@request.path_info}"
        puts "file      : #{file}"
        puts "rpc       : #{rpc}"
        puts "#####################"

        return [cmd, path, file, rpc]
      end
    end
    return nil
  end


  def internal_send_file(requested_file, content_type, cache_parameter)
    requested_file = File.join(@repo_dir, requested_file)

    return render_not_found if !File.exists?(requested_file)
    return render_not_found if !File.size?(requested_file)

    last_modified = File.mtime(requested_file).httpdate
    file_size = File.size?(requested_file)

    puts "###### SEND FILE ######"
    puts "requested_file : #{requested_file}"
    puts "content_type   : #{content_type}"
    puts "last_modified  : #{last_modified}"
    puts "file_size      : #{file_size}"
    puts "#######################"

    self.response.status = 200
    self.response.headers["Last-Modified"] = last_modified
    self.response.headers["Content-Length"] = file_size.to_s
    cache_parameter

    send_file requested_file, :type => content_type

  end


  def read_body
    return @request.body.read
  end


  def get_service_type
    service_type = @request.params['service']
    return false if !service_type
    return false if service_type[0, 4] != 'git-'
    service_type.gsub('git-', '')
  end


  def has_access(rpc, check_content_type = false)
    if check_content_type
      return false if @request.content_type != "application/x-git-%s-request" % rpc
    end
    return false if !['upload-pack', 'receive-pack'].include? rpc
    if rpc == 'receive-pack'
      return @config[:receive_pack] if @config.include? :receive_pack
    end
    if rpc == 'upload-pack'
      return @config[:upload_pack] if @config.include? :upload_pack
    end
    return get_config_setting(rpc)
  end


  def get_config_setting(service_name)
    service_name = service_name.gsub('-', '')
    setting = get_git_config("http.#{service_name}")
    if service_name == 'uploadpack'
      return setting != 'false'
    else
      return setting == 'true'
    end
  end


  def get_git_config(config_name)
    command = git_command("config #{config_name}")
    %x[#{command}].chomp
  end


  def update_server_info
    command = git_command('update-server-info')
    %x[#{command}]
  end


  def git_command(command)
    return "#{GitoliteHosting.git_user_runner()} 'cd #{@repo_dir} && GL_BYPASS_UPDATE_HOOK=true git #{command}'"
  end

  # --------------------------------------
  # HTTP error response handling functions
  # --------------------------------------

  def render_method_not_allowed
    puts "###### HTTP ERRORS ######"
    if request.env['SERVER_PROTOCOL'] == "HTTP/1.1"
      puts "method : not allowed"
      head :method_not_allowed
    else
      puts "method : bad request"
      head :bad_request
    end
    puts "#########################"
    return head
  end

  def render_not_found
    head :not_found
  end

  def render_no_access
    head :forbidden
  end

  # ------------------------------
  # packet-line handling functions
  # ------------------------------

  def pkt_flush
    '0000'
  end

  def pkt_write(str)
    (str.size + 4).to_s(base=16).rjust(4, '0') + str
  end


  # ------------------------
  # header writing functions
  # ------------------------

  def hdr_nocache
    self.response.headers["Expires"] = "Fri, 01 Jan 1980 00:00:00 GMT"
    self.response.headers["Pragma"] = "no-cache"
    self.response.headers["Cache-Control"] = "no-cache, max-age=0, must-revalidate"
  end

  def hdr_cache_forever
    now = Time.now().to_i
    self.response.headers["Date"] = now.to_s
    self.response.headers["Expires"] = (now + 31536000).to_s;
    self.response.headers["Cache-Control"] = "public, max-age=31536000";
  end

end
