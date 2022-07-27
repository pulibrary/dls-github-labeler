require "thor"
require_relative "labeler"
require_relative "vulnerability_alerts"

class LabelerCLI < Thor
  def self.exit_on_failure?
    true
  end

  desc "list_labels [org/repository]", "list all the labels in given repo"
  def list_labels(repo)
    Labeler.new.list_labels(repo).each do |pair|
      puts "#{pair[0]}, #{pair[1]}"
    end
  end

  desc "categories", "list all the category names"
  def categories
    puts Labeler.new.categories
  end

  desc "apply_labels [org/repository]", "apply all the labels to given repo"
  def apply_labels(repo)
    Labeler.new.apply_labels(repo)
  end

  desc "clear_labels [org/repository/]", "delete all labels from the given repo"
  def clear_labels(repo)
    Labeler.new.clear_labels(repo)
  end

  desc "delete_label [org/repository,org/repository] label", "delete the label from the repo"
  def delete_label(repos, label)
    puts Labeler.new.delete_label(repos.split(","), label)
  end

  desc "report_security", "list all vulnerability alerts by repository"
  def report_security
    puts VulnerabilityAlerts.new.report_security
  end
end

LabelerCLI.start(ARGV)
