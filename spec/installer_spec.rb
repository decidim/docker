# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Decidim interactive installer" do
  it "answers all prompts and produces a working install directory" do
    expect($install_dir).not_to be_nil
    expect(File).to exist(File.join($install_dir, ".env"))
    expect(File).to exist(File.join($install_dir, "docker-compose.yml"))
    expect(File).to exist(File.join($install_dir, "Gemfile.wrapper"))
    expect(File).to exist(File.join($install_dir, "Gemfile.local"))
  end
end
