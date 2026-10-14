require File.expand_path('../../test_helper', __FILE__)

class RedmineIssueFieldVisibilityCalendarsControllerTest < Redmine::ControllerTest
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
           :enumerations

  tests CalendarsController

  def setup
    Setting.clear_cache
    Issue.find(1).update_columns start_date: Date.today, due_date: Date.today, assigned_to_id: 3
    @request.session[:user_id] = 2
  end

  def tooltip
    css_select('div.issue span.tip').detect { |tip| tip.text.include?('#1:') } # not #10, #11 ...
  end

  def test_tooltip_should_show_the_fields
    get :show, params: { project_id: 1 }
    assert_response :success
    assert_match /Assignee: .*Dave Lopper/, tooltip.text
    assert_match /Priority:/, tooltip.text
    assert_match /Start date:/, tooltip.text
    assert_match /Due date:/, tooltip.text
  end

  def test_tooltip_should_leave_out_hidden_fields
    with_settings('plugin_redmine_issue_field_visibility' => {
      'hiddenfields' => {
        '1' => { 'assigned_to_id' => '1', 'priority_id' => '1', 'start_date' => '1', 'due_date' => '1' }
      }
    }) do
      get :show, params: { project_id: 1 }
      assert_response :success
      text = tooltip.text
      assert_match /Status:/, text
      assert_no_match /Assignee|Dave Lopper/, text
      assert_no_match /Priority/, text
      assert_no_match /Start date|Due date/, text
    end
  end

  # 31 entries of one issue, each a fresh instance as calendar_events_daily
  # loads them: one visibility decision for the whole calendar
  def test_tooltips_should_decide_the_hidden_fields_once_per_project
    with_settings('plugin_redmine_issue_field_visibility' => {
      'hiddenfields' => { '1' => { 'assigned_to_id' => '1' } }
    }) do
      get :show, params: { project_id: 1 }
      assert_response :success
      User.current = User.find(2)
      view = @controller.view_context
      calls = 0
      counting = Module.new do
        define_method(:hidden_core_fields) { |*args| calls += 1; super(*args) }
      end
      RedmineIssueFieldVisibility.singleton_class.prepend(counting)
      tips = Array.new(31) { view.render_issue_tooltip(Issue.find(1)) }
      assert_equal 1, calls
      assert tips.all? { |tip| tip.include?('Status') && !tip.include?('Assignee') }
    ensure
      counting&.send(:define_method, :hidden_core_fields) { |*args| super(*args) }
    end
  end
end

