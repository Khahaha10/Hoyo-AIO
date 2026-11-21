require 'xcodeproj'

NAME = 'HoYoWidgets'.freeze
SOURCES = %w[HoYoWidgets.swift WidgetSnapshot.swift WidgetTokens.swift].freeze

project = Xcodeproj::Project.open(File.expand_path('../Runner.xcodeproj', __dir__))
if project.targets.any? { |target| target.name == NAME }
  puts "#{NAME} already present"
  exit 0
end

runner = project.targets.find { |target| target.name == 'Runner' } or abort('Runner target missing')
widget = project.new_target(:app_extension, NAME, :ios, '17.0')

group = project.main_group.find_subpath(NAME, true)
group.set_source_tree('<group>')
group.set_path(NAME)
widget.add_file_references(SOURCES.map { |file| group.new_reference(file) })
group.new_reference('Info.plist')
group.new_reference("#{NAME}.entitlements")

flutter_group = project.main_group['Flutter']
generated = flutter_group.files.find { |file| file.path == 'Generated.xcconfig' } ||
            flutter_group.new_reference('Generated.xcconfig')

widget.build_configurations.each do |config|
  config.base_configuration_reference = generated
  settings = config.build_settings
  settings['PRODUCT_NAME'] = '$(TARGET_NAME)'
  settings['PRODUCT_BUNDLE_IDENTIFIER'] = 'com.hoyoaio.app.HoYoWidgets'
  settings['INFOPLIST_FILE'] = "#{NAME}/Info.plist"
  settings['GENERATE_INFOPLIST_FILE'] = 'NO'
  settings['CODE_SIGN_ENTITLEMENTS'] = "#{NAME}/#{NAME}.entitlements"
  settings['MARKETING_VERSION'] = '$(FLUTTER_BUILD_NAME)'
  settings['CURRENT_PROJECT_VERSION'] = '$(FLUTTER_BUILD_NUMBER)'
  settings['SWIFT_VERSION'] = '5.0'
  settings['TARGETED_DEVICE_FAMILY'] = '1,2'
  settings['SKIP_INSTALL'] = 'YES'
  settings['LD_RUNPATH_SEARCH_PATHS'] = '$(inherited) @executable_path/Frameworks @executable_path/../../Frameworks'
end

runner_group = project.main_group['Runner']
unless runner_group.files.any? { |file| file.path == 'Runner.entitlements' }
  runner_group.new_reference('Runner.entitlements')
end
runner.build_configurations.each do |config|
  config.build_settings['CODE_SIGN_ENTITLEMENTS'] = 'Runner/Runner.entitlements'
end

runner.add_dependency(widget)
embed = runner.new_copy_files_build_phase('Embed Foundation Extensions')
embed.dst_subfolder_spec = '13'
embed.add_file_reference(widget.product_reference, true).settings = {
  'ATTRIBUTES' => ['RemoveHeadersOnCopy']
}
phases = runner.build_phases
phases.delete(embed)
thin_binary = phases.index { |phase| phase.respond_to?(:name) && phase.name == 'Thin Binary' }
phases.insert(thin_binary || phases.length, embed)

project.save
puts "#{NAME} added"
