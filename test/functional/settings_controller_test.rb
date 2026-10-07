require File.expand_path('../../test_helper', __FILE__)

class RedmineIssueFieldVisibilitySettingsControllerTest < Redmine::ControllerTest
  fixtures :users, :roles, :email_addresses

  tests SettingsController

  def setup
    Setting.clear_cache
    @request.session[:user_id] = 1 # admin
  end

  def test_plugin_settings_should_show_the_matrix
    get :plugin, params: { id: 'redmine_issue_field_visibility' }
    assert_response :success
    assert_select 'table.issue-visibilities'
    assert_select 'input[name=?]', 'settings[hiddenfields][1][estimated_hours]'
  end

  def test_plugin_settings_without_roles_should_be_translated
    Role.delete_all
    User.find(1).update! language: 'de'
    get :plugin, params: { id: 'redmine_issue_field_visibility' }
    assert_response :success
    assert_select 'table.issue-visibilities', 0
    assert_select 'p', text: 'Legen Sie Rollen an, bevor Sie dieses Plugin verwenden.'
  end

  def test_locales_should_have_the_same_keys
    root = File.expand_path('../../../config/locales', __FILE__)
    keys = Dir[File.join(root, '*.yml')].to_h do |file|
      [File.basename(file), YAML.load_file(file).values.first.keys.sort]
    end
    assert_equal 4, keys.size
    keys.each_value { |k| assert_equal keys['en.yml'], k }
  end
end
