require File.expand_path('../../test_helper', __FILE__)

class RedmineIssueFieldVisibilityProjectsControllerTest < Redmine::ControllerTest
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
           :time_entries

  tests ProjectsController

  def setup
    Setting.clear_cache
    @request.session[:user_id] = 2
  end

  # QueriesHelper#column_content renders project rows too (GEOxyz 4139400)
  def test_index_as_list_should_render_project_rows
    with_settings('plugin_redmine_issue_field_visibility' => {
      'hiddenfields' => {
        '1' => {
          'estimated_hours' => '1'
        }
      }
    }) do
      get :index, params: { display_type: 'list', c: %w(name identifier short_description) }
      assert_response :success
      assert_select 'table.projects td.name', text: /eCookbook/
    end
  end

  def hide_estimated_hours_for(*role_ids, &block)
    with_settings('plugin_redmine_issue_field_visibility' => {
      'hiddenfields' => role_ids.to_h { |id| [id.to_s, { 'estimated_hours' => '1' }] }
    }, &block)
  end

  def estimates!
    Issue.update_all estimated_hours: nil
    Issue.find(1).update_columns estimated_hours: 12  # eCookbook
    Issue.find(6).update_columns estimated_hours: 100 # Private child of eCookbook
  end

  def test_show_should_display_the_estimated_time_total
    estimates!
    get :show, params: { id: 1 }
    assert_response :success
    assert_select 'div.spent_time li', text: /Estimated time: 112[.:]00/
  end

  # Manager (role 1) in eCookbook
  def test_show_should_not_display_the_estimated_time_total_when_hidden
    estimates!
    hide_estimated_hours_for(1) do
      get :show, params: { id: 1 }
      assert_response :success
      assert_select 'div.spent_time'
      assert_select 'div.spent_time li', text: /Estimated time/, count: 0
    end
  end

  # Developer (role 2) in the private child project only
  def test_show_should_not_count_subprojects_with_estimated_time_hidden
    estimates!
    MemberRole.find(5).update_column :role_id, 2 # user 2 in project 5
    hide_estimated_hours_for(2) do
      get :show, params: { id: 1 }
      assert_response :success
      assert_select 'div.spent_time li', text: /Estimated time: 12[.:]00/
    end
  end
end
