require File.expand_path('../../test_helper', __FILE__)

class RedmineIssueFieldVisibilityVersionsControllerTest < Redmine::ControllerTest
  fixtures :projects,
           :users,
           :roles,
           :members,
           :member_roles,
           :issues,
           :issue_statuses,
           :versions,
           :trackers,
           :projects_trackers,
           :issue_categories,
           :enabled_modules,
           :enumerations,
           :workflows

  tests VersionsController

  # a Symbol key, like Setting.plugin_redmine_issue_field_visibility reads it
  # (Setting caches per key as given)
  HIDE_ESTIMATED_HOURS = {
    plugin_redmine_issue_field_visibility: {
      'hiddenfields' => { '1' => { 'estimated_hours' => '1' } }
    }
  }

  def setup
    Setting.clear_cache
    @version = Version.create!(project_id: 1, name: 'IFV')
    Issue.find(1).update_columns fixed_version_id: @version.id, estimated_hours: 12, done_ratio: 0

    User.current = User.find 2
    @request.session[:user_id] = 2
  end

  def test_show_should_display_estimated_time_when_not_hidden
    get :show, params: { id: @version.id }
    assert_response :success
    assert_select '.time-tracking td.total-hours', text: /12[:.]00/
  end

  def test_show_should_not_display_estimated_time_when_hidden
    with_settings(HIDE_ESTIMATED_HOURS) do
      get :show, params: { id: @version.id }
      assert_response :success
      assert_select '.time-tracking td.total-hours', text: /12[:.]00/, count: 0
    end
  end

  def test_version_totals_should_be_zero_when_estimated_time_is_hidden
    version = Version.find @version.id
    assert_equal 12.0, version.visible_fixed_issues.estimated_hours
    assert_equal 12.0, version.estimated_hours
    if version.respond_to?(:estimated_remaining_hours)
      assert_equal 12.0, version.visible_fixed_issues.estimated_remaining_hours
      assert_equal 12.0, version.estimated_remaining_hours
    end

    with_settings(HIDE_ESTIMATED_HOURS) do
      version = Version.find @version.id
      assert_equal 0, version.visible_fixed_issues.estimated_hours
      assert_equal 0, version.estimated_hours
      if version.respond_to?(:estimated_remaining_hours)
        assert_equal 0, version.visible_fixed_issues.estimated_remaining_hours
        assert_equal 0, version.estimated_remaining_hours
      end
    end
  end

  def test_version_totals_should_follow_the_current_user
    with_settings(HIDE_ESTIMATED_HOURS) do
      version = Version.find @version.id
      assert_equal 0, version.visible_fixed_issues.estimated_hours
      User.current = User.find 1
      assert_equal 12.0, version.visible_fixed_issues.estimated_hours
    end
  end
end
