require File.expand_path('../../test_helper', __FILE__)

class RedmineIssueFieldVisibilityIssuesControllerTest < Redmine::ControllerTest
  fixtures :projects,
           :users,
           :roles,
           :members,
           :member_roles,
           :issues,
           :issue_statuses,
           :issue_relations,
           :versions,
           :trackers,
           :projects_trackers,
           :issue_categories,
           :enabled_modules,
           :enumerations,
           :workflows,
           :journals,
           :journal_details,
           :queries


  tests IssuesController

  def setup
    User.current = nil
    @issue = Issue.find 1
    @issue.update_column :estimated_hours, 12
    @issue.update_column :assigned_to_id, 3

    @request.session[:user_id] = 2
    Setting.plugin_redmine_issue_field_visibility = {}
  end

  def test_index_should_not_display_hidden_issue_fields
    get :index, params: { project_id: @issue.project.identifier, c: %w(subject estimated_hours assigned_to) }
    assert_select 'option[value=estimated_hours]', 2
    assert_select 'td.estimated_hours', '12:00'
    assert_select 'td.assigned_to a', 'Dave Lopper'
    assert_select 'option[value=estimated_hours]', 'Estimated time'

    Setting.plugin_redmine_issue_field_visibility = {
      'hiddenfields' => {
        '1' => {
          'estimated_hours' => '1',
          'assigned_to_id' => '1'
        }
      }
    }

    get :index, params: { project_id: @issue.project.identifier, c: %w(subject estimated_hours) }
    assert_select 'option[value=estimated_hours]', 0
    assert_select 'td.estimated_hours', text: '12', count: 0
    assert_select 'td.assigned_to a', text: 'Dave Lopper', count: 0
  end

  def test_show_should_not_display_hidden_issue_fields
    get :show, params: { id: 1 }
    assert_response :success
    assert_select 'div.label', 'Estimated time:'
    assert_select 'div.value', /^12.00 h/
    assert_select 'input[name=?]', 'issue[estimated_hours]'

    Setting.plugin_redmine_issue_field_visibility = {
      'hiddenfields' => {
        '1' => {
          'estimated_hours' => '1'
        }
      }
    }

    @issue.reload
    assert_equal %w(estimated_hours), @issue.hidden_core_fields
    assert !@issue.safe_attribute_names.include?('estimated_hours')

    get :show, params: { :id => 1 }
    assert_response :success
    assert_select 'input[name=?]', 'issue[estimated_hours]', :count => 0
    assert_select 'div.value', text: /^12.00 h/, :count => 0
    assert_select 'div.label', text: 'Estimated time:', :count => 0
  end

  def test_show_should_not_display_hidden_issue_fields_journals
    j = @issue.init_journal User.find(1)
    @issue.estimated_hours = 13.5
    @issue.save

    get :show, params: { id: 1 }
    assert_response :success
    assert_select 'strong', 'Estimated time'

    Setting.plugin_redmine_issue_field_visibility = {
      'hiddenfields' => {
        '1' => {
          'estimated_hours' => '1'
        }
      }
    }

    get :show, params: { :id => 1 }
    assert_response :success
    assert_select 'strong', text: 'Estimated time', count: 0
  end

end
