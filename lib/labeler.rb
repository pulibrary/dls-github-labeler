require "json"
require "open3"
require "pry"
require "octokit"
require "yaml"

class Labeler
  attr_reader :client, :labels_hash
  # @param client Octokit::Client
  # @param labels_hash Hash see labels.json for expected structure
  def initialize(client: nil, labels_hash: nil)
    @client = client || connect_client
    @labels_hash = labels_hash || load_labels
  end

  # lists all the categories in the labels hash
  def categories
    labels_hash.keys.map(&:to_s)
  end

  # @param repo String The repository, aka "pulibrary/figgy"
  # @return Array<Array<String, String>> a list of labels by name and color
  def list_labels(repo)
    client.labels(repo).map { |l| [l[:name], l[:color]] }
  end

  # @param repo String the repository to apply labels to
  def label_repo(repo)
    labels_hash.values.each do |h|
      h[:labels].each do |label|
        client.add_label(repo, label, h[:color])
      rescue Octokit::UnprocessableEntity => e
        client.update_label(repo, label, { color: h[:color] }) if already_exists_error?(e.message)
      end
    end
  end

  # @param config_file String the file name to read configuration from
  def label_repos(config_file)
    file_string = File.read(config_file)
    config_hash = YAML.safe_load(file_string)
    repos_array = config_hash["repos"]
    repos_array.each do |repo|
      label_repo(repo)
    end
  end

  # Delete all the labels and remove them from issues.
  # WARNING: only for initializing a new project.
  # @param repo String The repository, aka "pulibrary/figgy"
  def clear_labels(repo)
    labels = client.labels(repo)
    labels.each do |label|
      client.delete_label!(repo, label[:name])
    end
  end

  # Delete the labels from the repo
  # @param repos Array<String> List of repositories to delete from, aka ["pulibrary/figgy", "pulibrary/dpul"]
  # @param label String The name of the label, aka "on hold"
  # @return bool Whether it was deleted
  def delete_label(config_file, label)
    file_string = File.read(config_file)
    config_hash = YAML.safe_load(file_string)
    repos_array = config_hash["repos"]
    repos_array.map do |repo|
      client.delete_label!(repo, label)
    end
  end

  private

  def connect_client
    Octokit::Client.new(access_token: token, auto_paginate: true)
  end

  def token
    out, _st = Open3.capture2("lpass show hubot_github_token --notes")
    out
  end

  def load_labels
    JSON.parse(File.read("labels.json"), symbolize_names: true)
  end

  def already_exists_error?(message)
    message.split("\n")
           .map { |l| l.strip.split(":") }
           .select { |pair| pair.first == "code" }
           .flatten[1]
           .strip == "already_exists"
  end
end
