require File.expand_path('../../test_helper', __FILE__)

class RedmineIssueFieldVisibilityGanttsControllerTest < Redmine::ControllerTest
  fixtures :projects,
           :users,
           :roles,
           :members,
           :member_roles,
           :issues,
           :issue_statuses,
           :trackers,
           :projects_trackers,
           :enabled_modules,
           :enumerations,
           :versions

  tests GanttsController

  def setup
    Setting.clear_cache
    Issue.find(1).update_columns start_date: Date.today, due_date: Date.today, assigned_to_id: 3
    @request.session[:user_id] = 2
  end

  def tooltip
    css_select('div.tooltip span.tip').detect { |tip| tip.text.include?('#1') }
  end

  def test_tooltip_should_show_the_fields
    get :show, params: { project_id: 1 }
    assert_response :success
    assert_match /Assignee: .*Dave Lopper/, tooltip.text
    assert_match /Priority:/, tooltip.text
  end

  def test_tooltip_should_leave_out_hidden_fields
    with_settings('plugin_redmine_issue_field_visibility' => {
      'hiddenfields' => { '1' => { 'assigned_to_id' => '1', 'priority_id' => '1' } }
    }) do
      get :show, params: { project_id: 1 }
      assert_response :success
      text = tooltip.text
      assert_match /Status:/, text
      assert_match /Start date:/, text
      assert_no_match /Assignee|Dave Lopper/, text
      assert_no_match /Priority/, text
    end
  end
end
