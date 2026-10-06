# Data for the end-to-end scenarios of this plugin, run by start_server.sh
# after the generic seed (.codex/e2e/seed.rb). Idempotent.
#
# Role "Reporter" (user reporter) has assignee, category, start and due
# date, estimated time and description hidden; "E2E full" (manager) none.
# The reporter may use webhooks, so a webhook owned by the reporter shows
# what a payload carries for a role with hidden fields.

admin = User.find_by!(login: 'admin')
User.current = admin
manager = User.find_by!(login: 'manager')
reporter = User.find_by!(login: 'reporter')
project = Project.find_by!(identifier: 'e2e-project')
role = Role.find_by!(name: 'Reporter')

hidden = %w(assigned_to_id category_id start_date due_date estimated_hours description)
Setting.plugin_redmine_issue_field_visibility = {
  'hiddenfields' => { role.id.to_s => hidden.index_with { '1' } }
}

role.add_permission!(:use_webhooks) unless role.permissions.include?(:use_webhooks)
Setting.webhooks_enabled = '1' if Setting.respond_to?(:webhooks_enabled=)

category = IssueCategory.find_by(project_id: project.id, name: 'E2E category') ||
           IssueCategory.create!(project: project, name: 'E2E category')

# the dates of #1 derive from its subtask
subtask = Issue.find_by!(project_id: project.id, subject: 'E2E subtask')
if subtask.start_date.nil?
  subtask.start_date = Date.today
  subtask.due_date = Date.today + 7
  subtask.save!
end

issue = Issue.find_by!(project_id: project.id, subject: 'E2E assigned issue')
issue.update_columns(category_id: category.id, description: 'Secret description of the assigned issue.')
if issue.journals.joins(:details).where(journal_details: { prop_key: 'estimated_hours' }).none?
  issue.init_journal(manager, 'Estimate revised.')
  issue.estimated_hours = 6
  issue.save!
end

[manager, reporter].each do |user|
  user.pref.update!(no_self_notified: false) if user.pref.respond_to?(:no_self_notified)
  user.update_column(:mail_notification, 'all')
end

puts "Plugin seed: #{role.name} hides #{hidden.join(' ')}; issue ##{issue.id} " \
     "#{issue.reload.estimated_hours} h, category #{category.name}"
