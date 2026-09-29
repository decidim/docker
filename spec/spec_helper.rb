# frozen_string_literal: true

require "rspec"
require "serverspec"
require "pty"
require "expect"
require "webrick"
require "fileutils"
require "shellwords"

# Serverspec backend configuration
set :backend, :exec

# Shared test state populated by the before(:suite) hook.
$install_dir = nil

def project_root
  File.expand_path("..", __dir__)
end

# Build deploy.zip from the local install/ folder so the mock server can serve it.
def build_deploy_zip
  install_folder = File.join(project_root, "install")
  deploy_zip = File.join(project_root, "deploy.zip")

  puts "Building deploy.zip from #{install_folder}..."
  unless system("cd #{install_folder.shellescape} && zip -r #{deploy_zip.shellescape} . > /dev/null 2>&1")
    raise "Failed to build deploy.zip"
  end

  deploy_zip
end

# Start a lightweight WEBrick server that mocks the GitHub Releases download endpoint.
def start_mock_server(deploy_zip, port = 8765)
  server = WEBrick::HTTPServer.new(
    Port: port,
    Logger: WEBrick::Log.new("/dev/null"),
    AccessLog: []
  )

  server.mount_proc "/releases/download/latest/deploy.zip" do |_req, res|
    res.content_type = "application/zip"
    res.body = File.read(deploy_zip, mode: "rb")
  end

  Thread.new { server.start }
  server
end

# Drive install.sh through a PTY, answer every interactive prompt with the expect
# stdlib, and kill the process once the Docker app container is running and the
# Rails /up endpoint responds.
def run_installer!
  install_dir = "/tmp/decidim"
  FileUtils.rm_rf(install_dir)
  FileUtils.mkdir_p(install_dir)

  repo_url = "http://127.0.0.1:8765"

  env = {
    "REPOSITORY_PATH" => install_dir,
    "REPOSITORY_URL" => repo_url,
    "DECIDIM_IMAGE" => "ghcr.io/decidim/decidim:latest",
    "TERM" => "dumb"
  }

  script = File.join(project_root, "install", "install.sh")

  # Prompts emitted by install.sh and its sourced dependencies, in order.
  # Each hash contains the substring we match on and the text we send back.
  prompts = [
    { pattern: "Press enter to continue with the download", response: "", timeout: 30 },
    # docker pull happens here; on a cold cache it can take several minutes.
    { pattern: "Can we proceed openning ports", response: "N", timeout: 600 },
    { pattern: "Press Enter to continue...", response: "", timeout: 30 },
    { pattern: "name of your organization", response: "Test Organization", timeout: 30 },
    { pattern: "domain:", response: "localhost", timeout: 30 },
    { pattern: "Do you have an external database already set up", response: "N", timeout: 30 },
    { pattern: "SMTP_USERNAME:", response: "test", timeout: 30 },
    { pattern: "SMTP_PASSWORD:", response: "test", timeout: 30 },
    { pattern: "SMTP_ADDRESS", response: "smtp.example.com", timeout: 30 },
    { pattern: "SMTP_DOMAIN", response: "localhost", timeout: 30 },
    { pattern: "SMTP_PORT", response: "587", timeout: 30 },
    { pattern: "Do you have an external S3-compatible bucket", response: "N", timeout: 30 },
    { pattern: "HERE API KEY:", response: "test", timeout: 30 }
  ]

  # Background thread that polls Docker until the app container is running and
  # responding to the Rails /up endpoint.
  watcher = Thread.new do
    app_up = false
    180.times do # 180 * 5 seconds = 15 minutes maximum
      sleep 5

      app_name = `docker ps --filter name=^decidim-app-1$ --filter status=running --format '{{.Names}}' 2>/dev/null`.strip
      if app_name == "decidim-app-1"
        `docker exec decidim-app-1 curl -sf http://localhost:3000/up 2>/dev/null`.strip
        if $?.success?
          app_up = true
          puts "[watcher] App container is up and /up responded"
          break
        end
      end
    end
    app_up
  end

  env_prefix = env.map { |k, v| "#{k}=#{v.shellescape}" }.join(" ")
  cmd = "#{env_prefix} bash #{script.shellescape}"

  installer_pid = nil

  PTY.spawn(cmd) do |r, w, pid|
    installer_pid = pid
    prompts.each do |prompt|
      begin
        result = r.expect(prompt[:pattern], prompt[:timeout])
        if result
          w.puts prompt[:response]
          puts "[expect] Answered prompt: #{prompt[:pattern][0..50]}..."
        else
          puts "[expect] TIMEOUT waiting for prompt: #{prompt[:pattern]}"
          break
        end
      rescue Errno::EIO
        puts "[expect] PTY closed unexpectedly"
        break
      rescue => e
        puts "[expect] Error: #{e.message}"
        break
      end
    end
  end

  app_up = watcher.value

  if installer_pid
    begin
      Process.kill("TERM", installer_pid)
      sleep 2
      Process.kill("KILL", installer_pid)
    rescue Errno::ESRCH
      # Process already exited
    end
    begin
      Process.waitpid(installer_pid)
    rescue Errno::ECHILD
      # Already reaped
    end
  end

  unless app_up
    raise "App container did not become ready within the timeout"
  end

  install_dir
end

RSpec.configure do |config|
  config.before(:suite) do
    deploy_zip = build_deploy_zip
    @mock_server = start_mock_server(deploy_zip)

    puts "Running interactive installer (this may take several minutes)..."
    $install_dir = run_installer!
    puts "Installer finished. Install dir: #{$install_dir}"
  end

  config.after(:suite) do
    @mock_server&.shutdown if @mock_server.respond_to?(:shutdown)

    if $install_dir && File.exist?(File.join($install_dir, "docker-compose.yml"))
      system("cd #{File.join($install_dir).shellescape} && docker compose down -v --remove-orphans > /dev/null 2>&1")
    end
  end
end
