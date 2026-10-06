require File.expand_path('../../test_helper', __FILE__)

class IssueValuesTest < ActiveSupport::TestCase
  fixtures :projects,
           :users,
           :email_addresses,
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
    Setting.clear_cache
    Issue.find(1).update_columns estimated_hours: 12, assigned_to_id: 3, start_date: '2026-01-05'
    User.current = @user = User.find 2
  end

  test "readers keep their values outside of a serialization" do
    with_hidden_fields(%w(estimated_hours assigned_to_id start_date)) do
      issue = Issue.find 1
      assert_equal %w(estimated_hours assigned_to_id start_date), issue.hidden_core_fields
      assert_equal 12.0, issue.estimated_hours
      assert_equal 12.0, issue.total_estimated_hours
      assert_equal 3, issue.assigned_to_id
      assert_equal User.find(3), issue.assigned_to
      assert_equal Date.new(2026, 1, 5), issue.start_date
    end
  end

  test "readers of hidden fields answer nil while hiding values" do
    with_hidden_fields(%w(estimated_hours assigned_to_id start_date)) do
      issue = Issue.find 1
      RedmineIssueFieldVisibility.hide_values do
        assert_nil issue.estimated_hours
        assert_nil issue.total_estimated_hours
        assert_nil issue.assigned_to_id
        assert_nil issue.assigned_to
        assert_nil issue.start_date
        assert_equal 'Cannot print recipes', issue.subject
      end
      assert_equal 12.0, issue.estimated_hours
      assert_not RedmineIssueFieldVisibility.hide_values?
    end
  end

  test "readers answer their values for a user who sees the fields" do
    with_hidden_fields(%w(estimated_hours)) do
      issue = Issue.find 1
      User.current = User.find 1
      RedmineIssueFieldVisibility.hide_values do
        assert_equal 12.0, issue.estimated_hours
      end
    end
  end

  test "reload accepts the arguments of ActiveRecord reload" do
    issue = Issue.find 1
    assert_equal issue, issue.reload(lock: true)
    assert_nothing_raised { Issue.transaction { issue.lock! } }
  end

  if Issue.method_defined?(:webhook_payload)
    test "webhook payload does not contain fields hidden for the webhook user" do
      with_hidden_fields(%w(estimated_hours assigned_to_id start_date)) do
        issue = Issue.find 1
        User.current = User.find 1
        issue.init_journal(User.current)
        issue.estimated_hours = 20
        issue.save!

        payload = WebhookPayload.new('issue.updated', issue, @user).to_h
        data = payload.dig(:data, :issue)
        assert_equal 'Cannot print recipes', data[:subject]
        assert_nil data[:estimated_hours]
        assert_nil data[:total_estimated_hours]
        assert_nil data[:start_date]
        assert_nil data[:assigned_to]
        assert_equal [], payload.dig(:data, :journal, :details).map { |d| d[:prop_key] } & %w(estimated_hours)

        payload = WebhookPayload.new('issue.updated', issue, User.find(1)).to_h
        assert_equal 20.0, payload.dig(:data, :issue, :estimated_hours)
        assert_equal 3, payload.dig(:data, :issue, :assigned_to, :id)
        assert_equal 20.0, issue.estimated_hours
      end
    end
  end
end
