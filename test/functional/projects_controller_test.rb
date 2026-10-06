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
           :enumerations

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
end
