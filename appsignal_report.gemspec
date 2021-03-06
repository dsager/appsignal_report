require_relative 'lib/appsignal_report/version'

Gem::Specification.new do |s|
  s.name = 'appsignal_report'
  s.version = AppsignalReport::VERSION
  s.platform = Gem::Platform::RUBY

  s.authors = ['Daniel Sager']
  s.email = 'software@sager1.de'
  s.homepage = 'https://github.com/dsager/appsignal_report'
  s.license = 'MIT'

  s.summary = 'Useful reports around your AppSignal metrics'
  s.description = 'Toolkit to pull some Appsignal metrics and generate reports'

  s.files = Dir['{lib}/**/*.rb', 'bin/*', 'LICENSE', '*.md']
  s.require_path = 'lib'
  s.test_files = s.files.grep(%r{^(spec)/})

  s.executables << 'appsignal_report_deploy'
  s.executables << 'appsignal_report_weekly'

  s.add_development_dependency 'bundler'
  s.add_development_dependency 'rake'
end
