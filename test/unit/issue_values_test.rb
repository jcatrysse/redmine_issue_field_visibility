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

  setup do
    Setting.clear_cache
    Issue.find(1).update_columns estimated_hours: 12, assigned_to_id: 3, start_date: '2026-01-05'
    User.current = @user = User.find 2
  end

  test "reload accepts the arguments of ActiveRecord reload" do
    issue = Issue.find 1
    assert_equal issue, issue.reload(lock: true)
    assert_nothing_raised { Issue.transaction { issue.lock! } }
  end
end
