# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Generated build artifacts" do
  describe file(File.join($install_dir, ".env")) do
    it { should exist }
    its(:content) { should match(/DECIDIM_DOMAIN=localhost/) }
    its(:content) { should match(/COMPOSE_PROFILES=db/) }
    its(:content) { should match(/DATABASE_HOST=db/) }
    its(:content) { should match(/SMTP_ADDRESS=smtp\.example\.com/) }
    its(:content) { should match(/SMTP_PORT=587/) }
  end

  describe file(File.join($install_dir, "docker-compose.yml")) do
    it { should exist }
    its(:content) { should match(/services:/) }
    its(:content) { should match(/image: \$\{DECIDIM_IMAGE/) }
  end

  describe file(File.join($install_dir, "Gemfile.wrapper")) do
    it { should exist }
    its(:content) { should match(/eval_gemfile "Gemfile"/) }
    its(:content) { should match(/eval_gemfile "Gemfile\.local"/) }
  end

  describe file(File.join($install_dir, "Gemfile.local")) do
    it { should exist }
    its(:content) { should match(/gem "sidekiq-cron"/) }
  end
end

RSpec.describe "Docker containers" do
  describe command("docker ps --filter name=^decidim-app-1$ --filter status=running --format '{{.Names}}'") do
    its(:stdout) { should match(/decidim-app-1/) }
    its(:exit_status) { should eq 0 }
  end

  describe command("docker ps --filter name=^decidim-db-1$ --filter status=running --format '{{.Names}}'") do
    its(:stdout) { should match(/decidim-db-1/) }
    its(:exit_status) { should eq 0 }
  end

  describe command("docker ps --filter name=^decidim-cache-1$ --filter status=running --format '{{.Names}}'") do
    its(:stdout) { should match(/decidim-cache-1/) }
    its(:exit_status) { should eq 0 }
  end
end

RSpec.describe "Rails /up endpoint" do
  describe command("docker exec decidim-app-1 curl -sf http://localhost:3000/up") do
    its(:exit_status) { should eq 0 }
  end
end

RSpec.describe "Known container_name mismatch bug" do
  # create_system_admin.sh hardcodes container names 'decidim' and 'decidim-db',
  # but docker-compose.yml never sets container_name, so Docker Compose generates
  # decidim-app-1 and decidim-db-1. The suite remains green while the bug is exposed.

  describe command("docker ps --filter name=^decidim$ --filter status=running --format '{{.Names}}'") do
    its(:stdout) { should eq "" }
    its(:exit_status) { should eq 0 }
  end

  describe command("docker ps --filter name=^decidim-db$ --filter status=running --format '{{.Names}}'") do
    its(:stdout) { should eq "" }
    its(:exit_status) { should eq 0 }
  end

  describe command("docker ps --filter name=^decidim-app-1$ --filter status=running --format '{{.Names}}'") do
    its(:stdout) { should match(/decidim-app-1/) }
    its(:exit_status) { should eq 0 }
  end
end
