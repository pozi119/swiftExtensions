Pod::Spec.new do |s|
  s.name             = 'Utils'
  s.version          = '0.1.0'
  s.summary          = 'A short description of Utils.'
  s.description      = <<-DESC
      TODO: Add long description of the pod here.
                       DESC

  s.homepage         = 'https://github.com/pozi119/Utils'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'pozi119' => 'pozi119@163.com' }
  s.source           = { :git => 'https://github.com/pozi119/Utils.git', :tag => s.version.to_s }

  s.ios.deployment_target = '10.0'
  s.tvos.deployment_target = '10.0'
  s.osx.deployment_target = '10.12'
  s.watchos.deployment_target = '3.0'

  s.source_files = 'Utils/Classes/**/*'

  # s.resource_bundles = {
  #   'Utils' => ['Utils/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'Cocoa'
  # s.dependency 'AFNetworking', '~> 2.3'
end
