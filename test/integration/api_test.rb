require File.expand_path('../../test_helper', __FILE__)

class RedmineIssueFieldVisibilityApiTest < Redmine::ApiTest::Base
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

  HIDDEN_FIELDS = %w(assigned_to_id category_id fixed_version_id start_date
                     due_date estimated_hours description priority_id)

  # a Symbol key, like Setting.plugin_redmine_issue_field_visibility reads it
  def with_hidden_fields(fields = HIDDEN_FIELDS, &block)
    with_settings(plugin_redmine_issue_field_visibility: {
      'hiddenfields' => { '1' => fields.index_with { '1' } }
    }, &block)
  end

  def setup
    Setting.rest_api_enabled = '1'
    Setting.clear_cache
    Issue.find(1).update_columns estimated_hours: 12, assigned_to_id: 3, category_id: 1,
                                 fixed_version_id: 2, start_date: '2026-01-05',
                                 due_date: '2026-01-30', description: 'Secret description'
  end

  def test_show_json_should_contain_fields_that_are_not_hidden
    get '/issues/1.json', headers: credentials('jsmith')
    assert_response :success
    issue = ActiveSupport::JSON.decode(response.body)['issue']
    assert_equal 12.0, issue['estimated_hours']
    assert_equal 12.0, issue['total_estimated_hours']
    assert_equal 3, issue['assigned_to']['id']
    assert_equal 1, issue['category']['id']
    assert_equal 2, issue['fixed_version']['id']
    assert_equal '2026-01-05', issue['start_date']
    assert_equal '2026-01-30', issue['due_date']
    assert_equal 'Secret description', issue['description']
    assert issue['priority']
  end

  def test_show_json_should_not_contain_hidden_fields
    with_hidden_fields do
      get '/issues/1.json', headers: credentials('jsmith')
      assert_response :success
      issue = ActiveSupport::JSON.decode(response.body)['issue']
      assert_nil issue['estimated_hours']
      assert_nil issue['total_estimated_hours']
      assert_nil issue['assigned_to']
      assert_nil issue['category']
      assert_nil issue['fixed_version']
      assert_nil issue['start_date']
      assert_nil issue['due_date']
      assert_nil issue['description']
      assert_nil issue['priority']
      assert_equal 'Cannot print recipes', issue['subject']
    end
  end

  def test_show_json_should_contain_hidden_fields_for_admin
    with_hidden_fields do
      get '/issues/1.json', headers: credentials('admin')
      assert_response :success
      issue = ActiveSupport::JSON.decode(response.body)['issue']
      assert_equal 12.0, issue['estimated_hours']
      assert_equal 3, issue['assigned_to']['id']
    end
  end

  def test_show_xml_should_not_contain_hidden_fields
    with_hidden_fields(%w(estimated_hours assigned_to_id)) do
      get '/issues/1.xml', headers: credentials('jsmith')
      assert_response :success
      assert_select 'issue>estimated_hours', text: ''
      assert_select 'issue>total_estimated_hours', text: ''
      assert_select 'issue>assigned_to', 0
      assert_select 'issue>category[id="1"]'
    end
  end

  def test_index_json_should_not_contain_hidden_fields
    with_hidden_fields(%w(estimated_hours assigned_to_id)) do
      get '/projects/1/issues.json?issue_id=1&status_id=*', headers: credentials('jsmith')
      assert_response :success
      issues = ActiveSupport::JSON.decode(response.body)['issues']
      assert_equal [1], issues.map { |i| i['id'] }
      assert_nil issues.first['estimated_hours']
      assert_nil issues.first['total_estimated_hours']
      assert_nil issues.first['assigned_to']
      assert_equal 2, issues.first['fixed_version']['id']
    end
  end

  def test_update_json_should_keep_hidden_values
    with_hidden_fields(%w(estimated_hours start_date due_date assigned_to_id)) do
      put '/issues/1.json',
          params: { issue: { subject: 'Updated through the API', estimated_hours: 99 } },
          headers: credentials('jsmith')
      assert_response :no_content
    end
    issue = Issue.find 1
    assert_equal 'Updated through the API', issue.subject
    assert_equal 12.0, issue.estimated_hours
    assert_equal Date.new(2026, 1, 5), issue.start_date
    assert_equal 3, issue.assigned_to_id
  end

  def test_create_json_response_should_not_contain_hidden_fields
    Setting.default_issue_start_date_to_creation_date = '1'
    with_hidden_fields(%w(assigned_to_id start_date)) do
      post '/issues.json',
           params: { issue: { project_id: 1, tracker_id: 1, subject: 'Created through the API' } },
           headers: credentials('jsmith')
      assert_response :created
      json = ActiveSupport::JSON.decode(response.body)['issue']
      issue = Issue.find json['id']
      assert_not_nil issue.start_date
      assert_nil json['start_date']
    end
  end

  def test_version_json_should_not_contain_hidden_estimated_hours
    get '/versions/2.json', headers: credentials('jsmith')
    assert_operator ActiveSupport::JSON.decode(response.body)['version']['estimated_hours'], :>, 0

    with_hidden_fields(%w(estimated_hours)) do
      get '/versions/2.json', headers: credentials('jsmith')
      assert_response :success
      assert_equal 0, ActiveSupport::JSON.decode(response.body)['version']['estimated_hours'].to_i
    end
  end
end
