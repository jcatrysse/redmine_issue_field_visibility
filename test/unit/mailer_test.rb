require File.expand_path('../../test_helper', __FILE__)

class RedmineIssueFieldVisibilityMailerTest < ActiveSupport::TestCase
  include Redmine::I18n
  fixtures :projects,
           :users,
           :email_addresses,
           :user_preferences,
           :roles,
           :members,
           :member_roles,
           :issues,
           :issue_statuses,
           :issue_categories,
           :versions,
           :trackers,
           :projects_trackers,
           :enabled_modules,
           :enumerations,
           :workflows,
           :journals,
           :journal_details

  # a Symbol key, like Setting.plugin_redmine_issue_field_visibility reads it
  def with_hidden_fields(fields, &block)
    with_settings(plugin_redmine_issue_field_visibility: {
      'hiddenfields' => { '1' => fields.index_with { '1' } }
    }, &block)
  end

  setup do
    # config/configuration.yml may set another delivery method (start_server.sh)
    @delivery_method = ActionMailer::Base.delivery_method
    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.deliveries.clear
    Setting.clear_cache
    Setting.plain_text_mail = '0'
    Setting.default_language = 'en'
    User.current = nil
    Issue.find(1).update_columns assigned_to_id: 3, description: 'Secret description'
  end

  teardown do
    ActionMailer::Base.delivery_method = @delivery_method
  end

  def mail_body(mail)
    mail.parts.map { |p| p.body.decoded }.join("\n")
  end

  test "issue mail shows the fields the recipient sees" do
    Mailer.issue_add(User.find(2), Issue.find(1)).deliver_now
    mail = ActionMailer::Base.deliveries.last
    assert_equal 'dlopper', mail.header['X-Redmine-Issue-Assignee'].to_s
    assert_includes mail_body(mail), 'Secret description'
    assert_includes mail_body(mail), 'Dave Lopper'
  end

  test "issue mails leave out the fields hidden for the recipient" do
    with_hidden_fields(%w(assigned_to_id description)) do
      issue = Issue.find 1
      journal = issue.init_journal(User.find(1), 'A note')
      issue.subject = 'Changed subject'
      issue.save!
      ActionMailer::Base.deliveries.clear
      Mailer.issue_add(User.find(2), issue).deliver_now
      Mailer.issue_edit(User.find(2), journal).deliver_now

      assert_equal 2, ActionMailer::Base.deliveries.size
      ActionMailer::Base.deliveries.last(2).each do |mail|
        assert_nil mail.header["X-Redmine-Issue-Assignee"]&.value.presence, mail.subject
        assert_not_includes mail_body(mail), 'Secret description'
        assert_not_includes mail_body(mail), 'Dave Lopper'
        assert_includes mail.subject, 'Bug #1'
      end

      # the admin still gets everything
      Mailer.issue_add(User.find(1), issue).deliver_now
      assert_includes mail_body(ActionMailer::Base.deliveries.last), 'Secret description'
    end
  end
end
